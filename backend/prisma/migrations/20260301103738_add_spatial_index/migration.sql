-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create spatial GIST index for radius queries (CRITICAL for performance)
-- Note: ST_MakePoint uses (longitude, latitude) order per PostGIS convention
CREATE INDEX IF NOT EXISTS idx_recipe_geolocation
ON "Recipe" USING GIST (
  (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
);
