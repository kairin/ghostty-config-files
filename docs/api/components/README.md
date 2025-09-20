# Component Documentation


## src/layouts/Layout.astro

**Props**:
```typescript
export interface Props {
  title: string;
  description?: string;
  showThemeToggle?: boolean;
}
```

**Location**: `src/layouts/Layout.astro`


## src/pages/index.astro

**Location**: `src/pages/index.astro`


## src/components/ui/CardHeader.astro

**Props**:
```typescript
export interface Props {
  class?: string;
}
```

**Location**: `src/components/ui/CardHeader.astro`


## src/components/ui/Button.astro

**Props**:
```typescript
export interface Props {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link' | 'success' | 'warning' | 'info';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  class?: string;
  href?: string;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
}
```

**Location**: `src/components/ui/Button.astro`


## src/components/ui/Textarea.astro

**Props**:
```typescript
export interface Props {
  placeholder?: string;
  value?: string;
  disabled?: boolean;
  required?: boolean;
  readonly?: boolean;
  rows?: number;
  cols?: number;
  maxlength?: number;
  minlength?: number;
  class?: string;
  id?: string;
  name?: string;
  'aria-describedby'?: string;
  'aria-invalid'?: boolean;
  'aria-label'?: string;
  'aria-labelledby'?: string;
  resize?: 'none' | 'both' | 'horizontal' | 'vertical';
}
```

**Location**: `src/components/ui/Textarea.astro`


## src/components/ui/CardContent.astro

**Props**:
```typescript
export interface Props {
  class?: string;
}
```

**Location**: `src/components/ui/CardContent.astro`


## src/components/ui/Card.astro

**Props**:
```typescript
export interface Props {
  class?: string;
}
```

**Location**: `src/components/ui/Card.astro`


## src/components/ui/ThemeToggle.astro

**Props**:
```typescript
export interface Props {
  class?: string;
  showLabel?: boolean;
  size?: 'sm' | 'md' | 'lg';
}
```

**Location**: `src/components/ui/ThemeToggle.astro`


## src/components/ui/CardTitle.astro

**Props**:
```typescript
export interface Props {
  class?: string;
  as?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
}
```

**Location**: `src/components/ui/CardTitle.astro`


## src/components/ui/Alert.astro

**Props**:
```typescript
export interface Props {
  variant?: 'default' | 'destructive' | 'warning' | 'success' | 'info';
  class?: string;
  role?: 'alert' | 'status' | 'none';
}
```

**Location**: `src/components/ui/Alert.astro`


## src/components/ui/Input.astro

**Props**:
```typescript
export interface Props {
  type?: 'text' | 'email' | 'password' | 'number' | 'search' | 'tel' | 'url';
  placeholder?: string;
  value?: string;
  disabled?: boolean;
  required?: boolean;
  readonly?: boolean;
  class?: string;
  id?: string;
  name?: string;
  autocomplete?: string;
  'aria-describedby'?: string;
  'aria-invalid'?: boolean;
  'aria-label'?: string;
  'aria-labelledby'?: string;
}
```

**Location**: `src/components/ui/Input.astro`


## src/components/ui/Badge.astro

**Props**:
```typescript
export interface Props {
  variant?: 'default' | 'secondary' | 'destructive' | 'outline' | 'success' | 'warning' | 'info';
  size?: 'default' | 'sm' | 'lg';
  class?: string;
  href?: string;
}
```

**Location**: `src/components/ui/Badge.astro`


## src/components/ui/Label.astro

**Props**:
```typescript
export interface Props {
  for?: string;
  required?: boolean;
  class?: string;
}
```

**Location**: `src/components/ui/Label.astro`


## src/components/ui/CardDescription.astro

**Props**:
```typescript
export interface Props {
  class?: string;
}
```

**Location**: `src/components/ui/CardDescription.astro`


## src/components/ui/AccessibilityValidator.astro

**Props**:
```typescript
export interface Props {
  showResults?: boolean;
  autoScan?: boolean;
  class?: string;
}
```

**Location**: `src/components/ui/AccessibilityValidator.astro`


## src/env.d.ts

**Exports**:
```typescript
export interface ComponentProps {
export interface PerformanceMetrics {
export interface ConstitutionalCompliance {
export interface LocalCiCdStatus {
export interface LayoutProps {
export interface CardProps extends ComponentProps {
export interface ButtonProps extends ComponentProps {
export interface FormValidation {
export type Theme = 'light' | 'dark' | 'system';
export interface ThemeConfig {
export interface BuildConfig {
export {};
```


## src/lib/index.ts

**Exports**:
```typescript
export * from './utils';
export * from './theme';
export * from './form';
export * from './accessibility';
export * from './performance';
```


## src/lib/form.ts

**Exports**:
```typescript
export interface ValidationRule {
export interface FormField {
export interface FormState {
export const formValidation = {
export class FormManager {
export const formAccessibility = {
export const formSerialization = {
export function getFormManager(): FormManager {
export const formHooks = {
```


## src/lib/theme.ts

**Exports**:
```typescript
export type Theme = 'light' | 'dark' | 'system';
export interface ThemeConfig {
export const defaultThemeConfig: ThemeConfig = {
export class ThemeProvider {
export function getThemeProvider(config?: Partial<ThemeConfig>): ThemeProvider {
export function initializeTheme(config?: Partial<ThemeConfig>): ThemeProvider {
export const themeUtils = {
export const cssTheme = {
export const themePerformance = {
```


## src/lib/utils.ts

**Exports**:
```typescript
export function cn(...inputs: ClassValue[]) {
export function formatBytes(bytes: number, decimals = 2): string {
export function generateId(prefix = 'id'): string {
export function debounce<T extends (...args: any[]) => any>(
export function throttle<T extends (...args: any[]) => any>(
export function deepMerge<T extends Record<string, any>>(target: T, source: Partial<T>): T {
export const isBrowser = typeof window !== 'undefined'
export function safeJsonParse<T>(str: string, fallback: T): T {
export const performance = {
export const constitutional = {
```


## src/lib/accessibility.ts

**Exports**:
```typescript
export interface AccessibilityConfig {
export const defaultAccessibilityConfig: AccessibilityConfig = {
export const screenReader = {
export const focusManagement = {
export const keyboardNavigation = {
export const colorContrast = {
export const userPreferences = {
export const accessibilityValidation = {
export class AccessibilityManager {
export function getAccessibilityManager(config?: Partial<AccessibilityConfig>): AccessibilityManager {
export function initializeAccessibility(config?: Partial<AccessibilityConfig>): AccessibilityManager {
```


## src/lib/performance.ts

**Exports**:
```typescript
export interface PerformanceMetrics {
export interface PerformanceTargets {
export const constitutionalTargets: PerformanceTargets = {
export const webVitals = {
export const resourceMonitoring = {
export const memoryMonitoring = {
export const performanceOptimization = {
export class PerformanceMonitor {
export function getPerformanceMonitor(): PerformanceMonitor {
export function initializePerformanceMonitoring(): PerformanceMonitor {
```

