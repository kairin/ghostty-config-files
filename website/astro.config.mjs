// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

// Modern Astro + Tailwind v4 configuration
// Simplified from 115 lines to 26 lines (77% reduction)
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files',
  output: 'static',

  vite: {
    plugins: [tailwindcss()]
  },

  integrations: [sitemap()],

  build: {
    assets: '_astro'
  },

  // Build output directory (GitHub Pages serves from ../docs/ relative to website/)
  outDir: '../docs'
});
