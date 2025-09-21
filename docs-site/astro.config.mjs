import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import tailwind from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files',
  integrations: [
    sitemap()
  ],
  vite: {
    plugins: [tailwind()],
    optimizeDeps: {
      exclude: ['@tailwindcss/vite']
    }
  },
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true
    }
  },
  output: 'static',
  outDir: '../docs',
  publicDir: './public',
  build: {
    assets: 'assets'
  }
});
