import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { CityCoordinates, CitySuggestion } from './dto/location.dto';
// @ts-ignore - Mapbox SDK has incomplete TypeScript declarations
import mbxGeocoding from '@mapbox/mapbox-sdk/services/geocoding';

@Injectable()
export class GeocodingService {
  private readonly logger = new Logger(GeocodingService.name);
  private readonly geocodingClient: any;
  private readonly isEnabled: boolean;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    const token = this.config.get<string>('MAPBOX_ACCESS_TOKEN');

    if (!token) {
      this.logger.warn(
        'MAPBOX_ACCESS_TOKEN not configured - geocoding will be disabled. ' +
        'Get token from https://account.mapbox.com/access-tokens/'
      );
      this.isEnabled = false;
      this.geocodingClient = null;
    } else {
      this.geocodingClient = mbxGeocoding({ accessToken: token });
      this.isEnabled = true;
      this.logger.log('Mapbox geocoding client initialized');
    }
  }

  /**
   * Forward geocode: city name -> coordinates
   * Uses DB cache to minimize Mapbox API calls
   */
  async geocodeCity(cityName: string): Promise<CityCoordinates | null> {
    if (!this.isEnabled) {
      this.logger.warn(`Geocoding disabled - cannot geocode "${cityName}"`);
      return null;
    }

    // Normalize city name for cache lookup
    const normalizedCity = cityName.trim();

    // Check cache first
    const cached = await this.prisma.cityLocation.findFirst({
      where: { cityName: normalizedCity },
    });

    if (cached) {
      this.logger.debug(`Cache hit for city: ${normalizedCity}`);
      return {
        lat: cached.latitude,
        lng: cached.longitude,
        city: cached.cityName,
        country: cached.country ?? undefined,
      };
    }

    // Cache miss - call Mapbox API
    this.logger.debug(`Cache miss - geocoding city: ${normalizedCity}`);

    try {
      const response = await this.geocodingClient
        .forwardGeocode({
          query: normalizedCity,
          limit: 1,
          types: ['place'], // cities only
        })
        .send();

      const features = response.body.features;
      if (!features || features.length === 0) {
        this.logger.warn(`No results found for city: ${normalizedCity}`);
        return null;
      }

      const feature = features[0];
      const [lng, lat] = feature.center; // Mapbox uses [lng, lat] order
      const country = feature.context?.find((ctx: any) =>
        ctx.id.startsWith('country.')
      )?.text;

      // Validate coordinates
      if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
        this.logger.error(
          `Invalid coordinates from Mapbox for "${normalizedCity}": lat=${lat}, lng=${lng}`
        );
        return null;
      }

      // Store in cache
      await this.prisma.cityLocation.create({
        data: {
          cityName: normalizedCity,
          latitude: lat,
          longitude: lng,
          country: country ?? null,
        },
      });

      this.logger.log(`Geocoded and cached: ${normalizedCity} -> (${lat}, ${lng})`);

      return {
        lat,
        lng,
        city: normalizedCity,
        country,
      };
    } catch (error) {
      this.logger.error(
        `Mapbox geocoding failed for "${normalizedCity}": ${error.message}`,
        error.stack,
      );
      return null;
    }
  }

  /**
   * Reverse geocode: GPS coordinates -> city name
   * For location badge display (FEED-07)
   */
  async reverseGeocode(lat: number, lng: number): Promise<string> {
    if (!this.isEnabled) {
      this.logger.warn('Geocoding disabled - cannot reverse geocode');
      return 'Unknown Location';
    }

    // Validate coordinates
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      this.logger.error(`Invalid coordinates: lat=${lat}, lng=${lng}`);
      return 'Unknown Location';
    }

    try {
      const response = await this.geocodingClient
        .reverseGeocode({
          query: [lng, lat], // Mapbox uses [lng, lat] order!
          limit: 1,
          types: ['place'], // cities only
        })
        .send();

      const features = response.body.features;
      if (!features || features.length === 0) {
        this.logger.warn(`No city found for coordinates: (${lat}, ${lng})`);
        return 'Unknown Location';
      }

      const cityName = features[0].text || features[0].place_name;
      this.logger.debug(`Reverse geocoded (${lat}, ${lng}) -> ${cityName}`);
      return cityName;
    } catch (error) {
      this.logger.error(
        `Reverse geocoding failed for (${lat}, ${lng}): ${error.message}`,
        error.stack,
      );
      return 'Unknown Location';
    }
  }

  /**
   * City search autocomplete
   * For manual location change (FEED-08)
   */
  async searchCities(query: string, limit: number = 5): Promise<CitySuggestion[]> {
    if (!this.isEnabled) {
      this.logger.warn('Geocoding disabled - cannot search cities');
      return [];
    }

    if (!query || query.trim().length === 0) {
      return [];
    }

    try {
      const response = await this.geocodingClient
        .forwardGeocode({
          query: query.trim(),
          limit,
          types: ['place'], // cities only
          autocomplete: true,
        })
        .send();

      const features = response.body.features;
      if (!features || features.length === 0) {
        return [];
      }

      const suggestions: CitySuggestion[] = features.map((feature: any) => {
        const [lng, lat] = feature.center; // Mapbox uses [lng, lat] order
        return {
          name: feature.place_name,
          lat,
          lng,
        };
      });

      this.logger.debug(`City search for "${query}" returned ${suggestions.length} results`);
      return suggestions;
    } catch (error) {
      this.logger.error(
        `City search failed for "${query}": ${error.message}`,
        error.stack,
      );
      return [];
    }
  }
}
