/// <reference path="../.astro/types.d.ts" />
/// <reference types="astro/client" />

// Constitutional compliance types
declare global {
  namespace App {
    // Astro.locals interface for request context
    interface Locals {
      // Add any local context properties here
      buildInfo?: {
        timestamp: string;
        env: string;
        version: string;
      };
    }
  }

  // Performance monitoring types
  interface Window {
    // Core Web Vitals types
    webVitals?: {
      fcp?: number;
      lcp?: number;
      cls?: number;
      fid?: number;
    };

    // Constitutional compliance monitoring
    constitutionalCompliance?: {
      bundleSize: {
        js: number;
        css: number;
        total: number;
      };
      lighthouseScores: {
        performance: number;
        accessibility: number;
        bestPractices: number;
        seo: number;
      };
      coreWebVitals: {
        fcp: number;
        lcp: number;
        cls: number;
        fid: number;
      };
    };
  }

  // Environment variables with strict typing
  interface ImportMetaEnv {
    readonly MODE: 'development' | 'production' | 'test';
    readonly PROD: boolean;
    readonly DEV: boolean;
    readonly SSR: boolean;
    readonly SITE?: string;
    readonly BASE_URL: string;

    // Add custom environment variables here with proper typing
    readonly PUBLIC_SITE_URL?: string;
    readonly PUBLIC_GA_ID?: string;
    readonly PUBLIC_PLAUSIBLE_DOMAIN?: string;
  }

  interface ImportMeta {
    readonly env: ImportMetaEnv;
  }
}

// shadcn/ui component props types
export interface ComponentProps {
  className?: string;
  children?: React.ReactNode;
}

// Constitutional performance types
export interface PerformanceMetrics {
  lighthouse: {
    performance: number;
    accessibility: number;
    bestPractices: number;
    seo: number;
  };
  coreWebVitals: {
    fcp: number; // First Contentful Paint (ms)
    lcp: number; // Largest Contentful Paint (ms)
    cls: number; // Cumulative Layout Shift
    fid: number; // First Input Delay (ms)
  };
  bundleSize: {
    js: number;   // JavaScript bundle size (bytes)
    css: number;  // CSS bundle size (bytes)
    total: number; // Total bundle size (bytes)
  };
}

// Constitutional compliance validation types
export interface ConstitutionalCompliance {
  zeroGitHubActions: boolean;
  uvFirstPython: boolean;
  typeScriptStrict: boolean;
  performanceTargets: boolean;
  localCiCd: boolean;
  branchPreservation: boolean;
}

// Local CI/CD runner types
export interface LocalCiCdStatus {
  runners: {
    astroBuild: boolean;
    ghWorkflow: boolean;
    performanceMonitor: boolean;
    preCommit: boolean;
    logging: boolean;
    configManagement: boolean;
  };
  lastRun: {
    timestamp: string;
    success: boolean;
    errors: string[];
  };
  metrics: PerformanceMetrics;
}

// Astro component prop types for better type safety
export interface LayoutProps {
  title: string;
  description?: string;
}

export interface CardProps extends ComponentProps {
  title?: string;
  description?: string;
  footer?: React.ReactNode;
}

export interface ButtonProps extends ComponentProps {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link' | 'success' | 'warning' | 'info';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  asChild?: boolean;
  disabled?: boolean;
  onClick?: () => void;
}

// Form and validation types
export interface FormValidation {
  isValid: boolean;
  errors: Record<string, string[]>;
  warnings: Record<string, string[]>;
}

// Theme types for dark mode support
export type Theme = 'light' | 'dark' | 'system';

export interface ThemeConfig {
  defaultTheme: Theme;
  enableSystemTheme: boolean;
  themes: Record<string, any>;
}

// Constitutional build configuration types
export interface BuildConfig {
  astro: {
    version: string;
    strictMode: boolean;
    ssr: boolean;
    output: 'static' | 'server' | 'hybrid';
  };
  tailwind: {
    version: string;
    darkMode: 'class' | 'media';
    designSystem: 'shadcn' | 'custom';
  };
  constitutional: {
    zeroGitHubActions: boolean;
    localCiCd: boolean;
    performanceTargets: PerformanceMetrics;
    complianceChecks: ConstitutionalCompliance;
  };
}

export {};