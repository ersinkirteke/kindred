/**
 * Velocity Scorer Utility
 *
 * Calculates engagement velocity for viral detection:
 * - Velocity = (engagement/hour) * (1 + time_decay_factor)
 * - Time decay: e^(-ageHours/24) - exponential decay over 24 hours
 * - Views weighted at 0.3x compared to loves
 * - Minimum effective age: 0.5 hours (prevents division by zero)
 * - Viral threshold: 10 engagements/hour
 *
 * Pure utility class - no NestJS decorators, stateless, testable
 */

import * as Humanize from 'humanize-plus';

export interface VelocityResult {
  velocityScore: number;
  isViral: boolean;
  engagementHumanized: string;
  timeWindow: 'this hour' | 'today' | 'this week';
}

export class VelocityScorer {
  // Default viral threshold: 10 engagements/hour in local area
  // Per research: adjustable based on production metrics
  static readonly VIRAL_THRESHOLD = 10;

  /**
   * Calculate velocity score for a recipe based on engagement and age
   *
   * @param engagementLoves - Number of loves/likes
   * @param engagementViews - Number of views (weighted at 0.3x)
   * @param scrapedAt - When the recipe was scraped/posted
   * @returns VelocityResult with score, viral flag, and humanized text
   */
  static calculate(
    engagementLoves: number,
    engagementViews: number,
    scrapedAt: Date,
  ): VelocityResult {
    const now = new Date();
    const ageHours = (now.getTime() - scrapedAt.getTime()) / (1000 * 60 * 60);
    const effectiveAge = Math.max(ageHours, 0.5); // Min 30 min to prevent extreme velocities

    // Total engagement: loves + views * 0.3 (views weighted lower)
    const totalEngagement = engagementLoves + engagementViews * 0.3;

    // Velocity = engagement per hour
    const rawVelocity = totalEngagement / effectiveAge;

    // Time decay: exponential over 24 hours (older = needs higher raw velocity)
    const decayFactor = Math.exp(-ageHours / 24);
    const velocityScore = rawVelocity * (1 + decayFactor);

    const isViral = velocityScore >= VelocityScorer.VIRAL_THRESHOLD;

    // Humanize count with time window
    const engagementHumanized = VelocityScorer.humanize(
      engagementLoves,
      ageHours,
    );
    const timeWindow = VelocityScorer.getTimeWindow(ageHours);

    return { velocityScore, isViral, engagementHumanized, timeWindow };
  }

  /**
   * Humanize engagement count with appropriate time window
   *
   * @param loves - Number of loves
   * @param ageHours - Age of content in hours
   * @returns Humanized string like "1.2k loves today"
   */
  static humanize(loves: number, ageHours: number): string {
    const window = VelocityScorer.getTimeWindow(ageHours);
    const humanized = Humanize.compactInteger(loves, 1);
    return `${humanized} loves ${window}`;
  }

  /**
   * Determine time window based on content age
   *
   * @param ageHours - Age of content in hours
   * @returns Time window category
   */
  static getTimeWindow(
    ageHours: number,
  ): 'this hour' | 'today' | 'this week' {
    if (ageHours < 1) return 'this hour';
    if (ageHours < 24) return 'today';
    return 'this week';
  }
}
