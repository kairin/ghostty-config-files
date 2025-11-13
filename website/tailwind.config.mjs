/**
 * Tailwind CSS v4 Configuration
 * NOTE: DaisyUI v5 plugin is now loaded via CSS (@plugin "daisyui" in global.css)
 * This is the Tailwind v4 pattern - plugins are no longer loaded here
 * @type {import('tailwindcss').Config}
 */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
  ],
  darkMode: 'class', // Enable class-based dark mode
  // Theme customization moved to CSS (@theme in global.css)
  // DaisyUI plugin loaded via CSS import
};
