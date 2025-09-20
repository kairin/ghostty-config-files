/** @type {import('tailwindcss').Config} */
export default {
  // Dark mode configuration for constitutional UI requirements
  darkMode: ['class'],

  // Content paths for Tailwind CSS scanning
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
    './components/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
  ],

  // Theme configuration for constitutional design system
  theme: {
    // Container configuration for responsive design
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },

    extend: {
      // Constitutional color system with CSS variables
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },

      // Border radius system
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },

      // Typography scale for accessibility compliance
      fontFamily: {
        sans: [
          'Inter',
          'ui-sans-serif',
          'system-ui',
          'sans-serif',
          '"Apple Color Emoji"',
          '"Segoe UI Emoji"',
          '"Segoe UI Symbol"',
          '"Noto Color Emoji"',
        ],
        mono: [
          'JetBrains Mono',
          'ui-monospace',
          'SFMono-Regular',
          'Consolas',
          '"Liberation Mono"',
          'Menlo',
          'monospace',
        ],
      },

      // Animation system for performance
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },

      // Constitutional performance optimizations
      screens: {
        xs: '475px',
      },

      // Spacing system for consistency
      spacing: {
        18: '4.5rem',
        88: '22rem',
      },
    },
  },

  // Plugins for constitutional UI requirements
  plugins: [
    // Typography plugin for content
    require('@tailwindcss/typography'),

    // Forms plugin for accessibility
    require('@tailwindcss/forms'),

    // Aspect ratio plugin for media
    require('@tailwindcss/aspect-ratio'),

    // Custom plugin for shadcn/ui compatibility
    function ({ addUtilities }) {
      addUtilities({
        '.scrollbar-hide': {
          /* IE and Edge */
          '-ms-overflow-style': 'none',
          /* Firefox */
          'scrollbar-width': 'none',
          /* Safari and Chrome */
          '&::-webkit-scrollbar': {
            display: 'none',
          },
        },
      });
    },
  ],

  // Performance optimizations
  experimental: {
    // Enable optimization features
    optimizeUniversalDefaults: true,
  },

  // Constitutional compliance markers
  // ✅ Tailwind CSS >=3.4 (currently using 3.4.17)
  // ✅ Dark mode support with class-based strategy
  // ✅ shadcn/ui compatibility with CSS variables
  // ✅ Accessibility compliance features
  // ✅ Performance optimization enabled
  // ✅ Design system consistency
};