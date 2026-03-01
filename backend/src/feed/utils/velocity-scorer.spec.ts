/**
 * Tests for VelocityScorer utility
 *
 * Velocity formula: (engagement/hour) * (1 + e^(-age/24))
 * - Fresh content gets boost from decay factor
 * - Older content needs higher raw engagement to overcome decay
 * - Viral threshold: 10 engagements/hour
 */

import { VelocityScorer } from './velocity-scorer';

describe('VelocityScorer', () => {
  describe('calculate', () => {
    beforeEach(() => {
      // Mock current time to 2026-03-01 12:00:00 UTC
      jest.useFakeTimers();
      jest.setSystemTime(new Date('2026-03-01T12:00:00Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('should calculate high velocity for fresh content with moderate engagement', () => {
      // Recipe scraped 30 minutes ago with 100 loves and 50 views
      const scrapedAt = new Date('2026-03-01T11:30:00Z');
      const result = VelocityScorer.calculate(100, 50, scrapedAt);

      // Expected: total engagement = 100 + (50 * 0.3) = 115
      // Age = 0.5 hours
      // Raw velocity = 115 / 0.5 = 230 per hour
      // Decay factor = e^(-0.5/24) ≈ 0.979
      // Final velocity = 230 * (1 + 0.979) ≈ 455
      expect(result.velocityScore).toBeGreaterThan(10);
      expect(result.isViral).toBe(true);
      expect(result.timeWindow).toBe('this hour');
    });

    it('should calculate very low velocity for old content with same engagement', () => {
      // Recipe scraped 7 days ago with 100 loves
      const scrapedAt = new Date('2026-02-22T12:00:00Z');
      const result = VelocityScorer.calculate(100, 0, scrapedAt);

      // Age = 168 hours (7 days)
      // Raw velocity = 100 / 168 ≈ 0.595 per hour
      // Decay factor = e^(-168/24) = e^(-7) ≈ 0.00091
      // Final velocity = 0.595 * (1 + 0.00091) ≈ 0.596
      expect(result.velocityScore).toBeLessThan(1);
      expect(result.isViral).toBe(false);
      expect(result.timeWindow).toBe('this week');
    });

    it('should mark recipe as viral when velocity >= 10', () => {
      // Recipe scraped 1 hour ago with 200 loves
      const scrapedAt = new Date('2026-03-01T11:00:00Z');
      const result = VelocityScorer.calculate(200, 0, scrapedAt);

      // Age = 1 hour
      // Raw velocity = 200 / 1 = 200 per hour
      // Decay factor = e^(-1/24) ≈ 0.959
      // Final velocity = 200 * (1 + 0.959) ≈ 391
      expect(result.velocityScore).toBeGreaterThanOrEqual(10);
      expect(result.isViral).toBe(true);
    });

    it('should NOT mark recipe as viral when velocity < 10', () => {
      // Recipe scraped 3 days ago with 50 loves
      const scrapedAt = new Date('2026-02-26T12:00:00Z');
      const result = VelocityScorer.calculate(50, 0, scrapedAt);

      // Age = 72 hours (3 days)
      // Raw velocity = 50 / 72 ≈ 0.694 per hour
      // Decay factor = e^(-72/24) = e^(-3) ≈ 0.0498
      // Final velocity = 0.694 * (1 + 0.0498) ≈ 0.729
      expect(result.velocityScore).toBeLessThan(10);
      expect(result.isViral).toBe(false);
    });

    it('should apply time decay exponentially', () => {
      const loves = 100;

      // Fresh (1 hour ago)
      const fresh = VelocityScorer.calculate(loves, 0, new Date('2026-03-01T11:00:00Z'));

      // Day old (24 hours ago)
      const dayOld = VelocityScorer.calculate(loves, 0, new Date('2026-02-28T12:00:00Z'));

      // Week old (168 hours ago)
      const weekOld = VelocityScorer.calculate(loves, 0, new Date('2026-02-22T12:00:00Z'));

      // Fresh should have highest velocity due to decay factor
      expect(fresh.velocityScore).toBeGreaterThan(dayOld.velocityScore);
      expect(dayOld.velocityScore).toBeGreaterThan(weekOld.velocityScore);

      // Decay factor at 24 hours should be e^(-1) ≈ 0.368
      // So boost factor (1 + decay) should be ~1.368 vs fresh's ~1.959
      expect(fresh.velocityScore / dayOld.velocityScore).toBeGreaterThan(1.3);
    });

    it('should use minimum effective age of 0.5 hours to prevent division by zero', () => {
      // Very fresh recipe (1 minute ago)
      const veryFresh = new Date('2026-03-01T11:59:00Z');
      const result = VelocityScorer.calculate(10, 0, veryFresh);

      // Should use 0.5 hours as minimum, not actual age (0.0167 hours)
      // Raw velocity = 10 / 0.5 = 20 per hour (not 10 / 0.0167 = 600)
      // This prevents extreme velocities for brand new content
      expect(result.velocityScore).toBeLessThan(100);
      expect(result.velocityScore).toBeGreaterThan(10);
    });

    it('should weight views at 0.3x compared to loves', () => {
      const scrapedAt = new Date('2026-03-01T11:00:00Z');

      // 100 loves, no views
      const lovesOnly = VelocityScorer.calculate(100, 0, scrapedAt);

      // 70 loves, 100 views (70 + 100*0.3 = 100 total engagement)
      const mixed = VelocityScorer.calculate(70, 100, scrapedAt);

      // Should have identical velocity scores
      expect(Math.abs(lovesOnly.velocityScore - mixed.velocityScore)).toBeLessThan(0.01);
    });

    it('should humanize 1234 loves at age 2 hours as "1.2k loves today"', () => {
      const scrapedAt = new Date('2026-03-01T10:00:00Z'); // 2 hours ago
      const result = VelocityScorer.calculate(1234, 0, scrapedAt);

      expect(result.engagementHumanized).toMatch(/1\.2k loves today/);
      expect(result.timeWindow).toBe('today');
    });

    it('should humanize 45 loves at age 0.5 hours as "45 loves this hour"', () => {
      const scrapedAt = new Date('2026-03-01T11:30:00Z'); // 30 minutes ago
      const result = VelocityScorer.calculate(45, 0, scrapedAt);

      expect(result.engagementHumanized).toMatch(/45 loves this hour/);
      expect(result.timeWindow).toBe('this hour');
    });

    it('should humanize 5000 loves at age 48 hours as "5k loves this week"', () => {
      const scrapedAt = new Date('2026-02-27T12:00:00Z'); // 48 hours ago
      const result = VelocityScorer.calculate(5000, 0, scrapedAt);

      expect(result.engagementHumanized).toMatch(/5(\.0)?k loves this week/);
      expect(result.timeWindow).toBe('this week');
    });
  });

  describe('getTimeWindow', () => {
    it('should return "this hour" for age < 1 hour', () => {
      expect(VelocityScorer.getTimeWindow(0.5)).toBe('this hour');
      expect(VelocityScorer.getTimeWindow(0.99)).toBe('this hour');
    });

    it('should return "today" for age >= 1 and < 24 hours', () => {
      expect(VelocityScorer.getTimeWindow(1)).toBe('today');
      expect(VelocityScorer.getTimeWindow(12)).toBe('today');
      expect(VelocityScorer.getTimeWindow(23.99)).toBe('today');
    });

    it('should return "this week" for age >= 24 hours', () => {
      expect(VelocityScorer.getTimeWindow(24)).toBe('this week');
      expect(VelocityScorer.getTimeWindow(48)).toBe('this week');
      expect(VelocityScorer.getTimeWindow(168)).toBe('this week');
    });
  });
});
