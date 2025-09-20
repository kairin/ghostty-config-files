import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

// Modern Web Development Stack Configuration
// Constitutional compliance: Astro.build (>=4.0) with TypeScript strict mode
export default defineConfig({
  // GitHub Pages deployment configuration
  site: 'https://kairin.github.io',
  base: '/ghostty-config-files',

  // Integrations following constitutional requirements
  integrations: [
    tailwind({
      // Disable base styles to use custom shadcn/ui styles
      applyBaseStyles: false,
    }),
  ],

  // TypeScript strict mode enforcement (constitutional requirement)
  typescript: {
    strict: true,
  },

  // Build optimization for constitutional performance targets
  build: {
    // Inline stylesheets for better performance
    inlineStylesheets: 'auto',
    // Asset optimization
    assets: '_astro',
  },

  // Vite configuration for performance optimization
  vite: {
    build: {
      // Constitutional requirement: JavaScript bundles <100KB
      rollupOptions: {
        output: {
          manualChunks: {
            // Keep vendor dependencies separate and small
            vendor: ['astro'],
          },
        },
      },
      // Minification for production
      minify: 'esbuild',
      // Source maps for debugging
      sourcemap: false, // Disable for smaller bundles
    },
    // Development optimizations
    server: {
      // Hot reload performance target: <1 second
      hmr: {
        overlay: false, // Reduce overhead
      },
    },
  },

  // Output configuration for GitHub Pages
  output: 'static',

  // Adapter configuration (none needed for static sites)
  // adapter: undefined,

  // Security and best practices
  security: {
    // Content Security Policy will be handled by deployment
  },

  // SEO and accessibility optimization
  compilerOptions: {
    // Enable optimizations for Lighthouse scores 95+
    preserveComments: false,
  },

  // Constitutional compliance markers
  // ✅ Astro.build >=4.0 (currently using 5.x)
  // ✅ TypeScript strict mode enabled
  // ✅ Performance optimization configured
  // ✅ GitHub Pages deployment ready
  // ✅ Bundle size optimization enabled
});