/**
 * GIF Segments Configuration
 * Defines the rotating GIF segments for hero and background
 * Segments are generated from VHS recordings using scripts/vhs/generate-demos.sh --segments
 */

export interface GifSegment {
  path: string;
  description: string;
}

/**
 * Hero banner segments
 * Higher opacity, more prominent display
 * Shows key features like installation, tools, verification
 */
export const heroSegments: GifSegment[] = [
  { path: 'segments/hero/segment-01.gif', description: 'Installation start' },
  { path: 'segments/hero/segment-02.gif', description: 'System audit' },
  { path: 'segments/hero/segment-03.gif', description: 'Tool installation' },
  { path: 'segments/hero/segment-04.gif', description: 'Configuration' },
  { path: 'segments/hero/segment-05.gif', description: 'Verification' },
];

/**
 * Background segments
 * Lower opacity, subtler ambient animation
 * Shows terminal activity, logs, general usage
 */
export const backgroundSegments: GifSegment[] = [
  { path: 'segments/bg/segment-01.gif', description: 'Terminal activity' },
  { path: 'segments/bg/segment-02.gif', description: 'Log output' },
  { path: 'segments/bg/segment-03.gif', description: 'Command execution' },
  { path: 'segments/bg/segment-04.gif', description: 'Task queue' },
  { path: 'segments/bg/segment-05.gif', description: 'Ambient terminal' },
];

/**
 * Fallback GIF paths (used if segments don't exist)
 */
export const fallbackHero = 'demo.gif';
export const fallbackBackground = 'images/background.gif';

/**
 * Get hero GIF paths as string array
 */
export function getHeroGifPaths(): string[] {
  return heroSegments.map(s => s.path);
}

/**
 * Get background GIF paths as string array
 */
export function getBackgroundGifPaths(): string[] {
  return backgroundSegments.map(s => s.path);
}

/**
 * Rotation configuration
 */
export const rotationConfig = {
  interval: 10000,  // 10 seconds between rotations
  heroOpacity: 0.4,  // Hero is more visible
  backgroundOpacity: 0.15,  // Background is subtle (0.25 in dark mode via CSS)
  vhsGlitch: true,  // Enable full VHS effects
};
