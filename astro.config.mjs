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
      // Enable base styles for CSS custom properties
      applyBaseStyles: true,
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

  // Build output directory - FIXED to ./docs for GitHub Pages deployment
  outDir: './docs',

  // Vite configuration for performance optimization
  vite: {
    plugins: [
      // Automatically create .nojekyll file for GitHub Pages (Secondary Protection Layer)
      // Primary layer: public/.nojekyll (auto-copied by Astro)
      {
        name: 'create-nojekyll',
        async writeBundle() {
          const fs = await import('fs');
          const path = await import('path');
          const nojekyllPath = path.join('./docs', '.nojekyll');

          // Ensure docs directory exists
          if (!fs.existsSync('./docs')) {
            console.warn('⚠️ WARNING: docs directory not found for .nojekyll creation');
            return;
          }

          // Create .nojekyll file (redundant protection - also in public/)
          fs.writeFileSync(nojekyllPath, '');
          console.log('✅ Created .nojekyll file for GitHub Pages (Secondary Layer)');

          // Verify _astro directory exists (critical for asset loading)
          const astroDir = path.join('./docs', '_astro');
          if (fs.existsSync(astroDir)) {
            const files = fs.readdirSync(astroDir);
            console.log(`✅ _astro directory confirmed (${files.length} files)`);
          } else {
            console.warn('⚠️ WARNING: _astro directory not found - assets may not load');
          }
        }
      }
    ],
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
  // ✅ GitHub Pages deployment ready (outDir: ./docs)
  // ✅ Bundle size optimization enabled
  // ✅ .nojekyll multi-layer protection
});
