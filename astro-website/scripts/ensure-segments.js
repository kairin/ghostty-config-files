#!/usr/bin/env node
/**
 * ensure-segments.js
 * Prebuild script to ensure GIF segments exist
 * Runs before Astro build to auto-generate segments if missing
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SEGMENTS_DIR = path.join(__dirname, '../public/segments');
const HERO_DIR = path.join(SEGMENTS_DIR, 'hero');
const BG_DIR = path.join(SEGMENTS_DIR, 'bg');

// Expected segment files
const HERO_SEGMENTS = [
  'segment-01.gif',
  'segment-02.gif',
  'segment-03.gif',
  'segment-04.gif',
  'segment-05.gif',
];

const BG_SEGMENTS = [
  'segment-01.gif',
  'segment-02.gif',
  'segment-03.gif',
  'segment-04.gif',
  'segment-05.gif',
];

function checkSegmentsExist() {
  // Check if directories exist
  if (!fs.existsSync(HERO_DIR) || !fs.existsSync(BG_DIR)) {
    return false;
  }

  // Check hero segments
  for (const segment of HERO_SEGMENTS) {
    const filePath = path.join(HERO_DIR, segment);
    if (!fs.existsSync(filePath)) {
      console.log(`Missing segment: hero/${segment}`);
      return false;
    }
  }

  // Check background segments
  for (const segment of BG_SEGMENTS) {
    const filePath = path.join(BG_DIR, segment);
    if (!fs.existsSync(filePath)) {
      console.log(`Missing segment: bg/${segment}`);
      return false;
    }
  }

  return true;
}

function generateSegments() {
  const scriptPath = path.join(__dirname, '../../scripts/vhs/generate-demos.sh');

  if (!fs.existsSync(scriptPath)) {
    console.error('Error: generate-demos.sh not found at', scriptPath);
    console.log('Skipping segment generation - segments must be created manually');
    return false;
  }

  console.log('Generating GIF segments...');
  try {
    execSync(`bash "${scriptPath}" --segments`, {
      stdio: 'inherit',
      cwd: path.join(__dirname, '../..'),
    });
    return true;
  } catch (error) {
    console.error('Segment generation failed:', error.message);
    return false;
  }
}

function createPlaceholders() {
  // Create directories
  fs.mkdirSync(HERO_DIR, { recursive: true });
  fs.mkdirSync(BG_DIR, { recursive: true });

  console.log('Creating placeholder notice...');

  // Create a README to explain missing segments
  const readme = `# GIF Segments

These directories should contain optimized GIF segments (<2MB each) for the website rotation.

## Generate Segments

Run from repository root:
\`\`\`bash
./scripts/vhs/generate-demos.sh --segments
\`\`\`

## Required Files

### hero/
- segment-01.gif - Installation start
- segment-02.gif - System audit
- segment-03.gif - Tool installation
- segment-04.gif - Configuration
- segment-05.gif - Verification

### bg/
- segment-01.gif - Terminal activity
- segment-02.gif - Log output
- segment-03.gif - Command execution
- segment-04.gif - Task queue
- segment-05.gif - Ambient terminal

## Source

Segments are extracted from VHS recordings in \`logs/video/\`.
`;

  fs.writeFileSync(path.join(SEGMENTS_DIR, 'README.md'), readme);
}

function main() {
  console.log('Checking for GIF segments...');

  if (checkSegmentsExist()) {
    console.log('All segments present.');
    return;
  }

  console.log('Some segments missing. Attempting to generate...');

  // Try to generate segments
  const generated = generateSegments();

  if (!generated || !checkSegmentsExist()) {
    console.log('Could not generate all segments.');
    createPlaceholders();
    console.log('Build will continue with fallback images.');
  } else {
    console.log('All segments generated successfully.');
  }
}

main();
