// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files/',
  outDir: '../docs',
  vite: {
    plugins: [tailwindcss()],
  },
});
