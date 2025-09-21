import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files',
  integrations: [
    tailwind(),
    sitemap()
  ],
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true
    }
  },
  vite: {
    optimizeDeps: {
      exclude: ['@astrojs/tailwind']
    }
  },
  output: 'static',
  outDir: '../docs',
  publicDir: './public',
  build: {
    assets: 'assets'
  }
});
