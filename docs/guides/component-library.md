# Component Library Documentation

## 🎨 shadcn/ui + Astro Integration

This project uses a custom implementation of shadcn/ui components built specifically for Astro.build with constitutional compliance and performance optimization.

## 🏗️ Architecture

### Component Structure
```
src/components/ui/
├── Button.astro              # Primary action components
├── Input.astro               # Form input elements
├── Textarea.astro            # Multi-line text input
├── Card.astro               # Content containers
├── Badge.astro              # Status indicators
├── Alert.astro              # Notification components
├── Label.astro              # Form labels
├── ThemeToggle.astro        # Dark mode toggle
└── AccessibilityValidator.astro # WCAG compliance validator
```

### Utility Libraries
```
src/lib/
├── utils.ts                 # General utilities (cn, clsx integration)
├── theme.ts                 # Theme management system
├── form.ts                  # Form validation utilities
├── accessibility.ts         # Accessibility helpers
└── performance.ts           # Performance monitoring utilities
```

## 📚 Component Documentation

### Button Component

**Location**: `src/components/ui/Button.astro`

**Props**:
```typescript
interface Props {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  class?: string;
}
```

**Usage**:
```astro
---
import Button from '@/components/ui/Button.astro';
---

<!-- Primary button -->
<Button variant="default">Click me</Button>

<!-- Secondary button -->
<Button variant="secondary" size="lg">Large Button</Button>

<!-- Disabled state -->
<Button disabled>Disabled</Button>
```

**Constitutional Compliance**:
- ✅ Accessibility: Full keyboard navigation, ARIA labels
- ✅ Performance: Zero JavaScript, CSS-only interactions
- ✅ Theme Support: Automatic dark/light mode adaptation

### Input Component

**Location**: `src/components/ui/Input.astro`

**Props**:
```typescript
interface Props {
  type?: string;
  placeholder?: string;
  value?: string;
  disabled?: boolean;
  required?: boolean;
  class?: string;
  'aria-label'?: string;
}
```

**Usage**:
```astro
---
import Input from '@/components/ui/Input.astro';
import Label from '@/components/ui/Label.astro';
---

<div class="space-y-2">
  <Label for="email">Email Address</Label>
  <Input
    id="email"
    type="email"
    placeholder="Enter your email"
    required
  />
</div>
```

**Constitutional Compliance**:
- ✅ Accessibility: Proper labeling, validation states
- ✅ Performance: No JavaScript dependencies
- ✅ Security: Input sanitization built-in

### Card Component

**Location**: `src/components/ui/Card.astro`

**Usage**:
```astro
---
import Card from '@/components/ui/Card.astro';
---

<Card>
  <div class="card-header">
    <h3 class="card-title">Card Title</h3>
    <p class="card-description">Card description text</p>
  </div>
  <div class="card-content">
    <p>Card content goes here</p>
  </div>
  <div class="card-footer">
    <Button>Action</Button>
  </div>
</Card>
```

**Constitutional Compliance**:
- ✅ Accessibility: Semantic structure, proper heading hierarchy
- ✅ Performance: Minimal CSS footprint
- ✅ Responsive: Mobile-first design

### ThemeToggle Component

**Location**: `src/components/ui/ThemeToggle.astro`

**Features**:
- System preference detection
- Smooth theme transitions
- Accessibility announcements
- FOUC (Flash of Unstyled Content) prevention

**Usage**:
```astro
---
import ThemeToggle from '@/components/ui/ThemeToggle.astro';
---

<!-- Add to navigation or header -->
<ThemeToggle />
```

**Constitutional Compliance**:
- ✅ Accessibility: Keyboard navigation, screen reader support
- ✅ Performance: Minimal JavaScript, efficient theme switching
- ✅ User Experience: Remembers preference across sessions

### AccessibilityValidator Component

**Location**: `src/components/ui/AccessibilityValidator.astro`

**Features**:
- Real-time WCAG 2.1 AA compliance checking
- Alt text validation for images
- Form label validation
- Color contrast checking
- Heading structure validation

**Usage**:
```astro
---
import AccessibilityValidator from '@/components/ui/AccessibilityValidator.astro';
---

<!-- Add to main layout for development -->
<AccessibilityValidator />
```

**Constitutional Compliance**:
- ✅ WCAG 2.1 AA: Real-time compliance monitoring
- ✅ Performance: Development-only, zero production impact
- ✅ Reporting: Comprehensive accessibility audit reports

## 🎨 Design System

### Color Palette

The component library uses CSS custom properties for consistent theming:

```css
/* Light theme */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 222.2 47.4% 11.2%;
  --secondary: 210 40% 96%;
  --accent: 210 40% 96%;
  --destructive: 0 84.2% 60.2%;
  --border: 214.3 31.8% 91.4%;
  --ring: 222.2 84% 4.9%;
}

/* Dark theme */
.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --primary: 210 40% 98%;
  --secondary: 217.2 32.6% 17.5%;
  --accent: 217.2 32.6% 17.5%;
  --destructive: 0 62.8% 30.6%;
  --border: 217.2 32.6% 17.5%;
  --ring: 212.7 26.8% 83.9%;
}
```

### Typography Scale

```css
h1 { @apply text-4xl font-extrabold lg:text-5xl; }
h2 { @apply text-3xl font-semibold tracking-tight; }
h3 { @apply text-2xl font-semibold tracking-tight; }
h4 { @apply text-xl font-semibold tracking-tight; }
p  { @apply leading-7 [&:not(:first-child)]:mt-6; }
```

### Spacing System

Following Tailwind CSS spacing with constitutional enhancements:

```css
.section-spacing { @apply py-16 lg:py-24; }
.container { @apply mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8; }
.grid-responsive { @apply grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3; }
```

## 🚀 Performance Optimizations

### Bundle Size Optimization
- **CSS Purging**: Unused styles automatically removed
- **Component Tree Shaking**: Only used components included
- **Zero JavaScript**: Most components work without JS
- **Critical CSS**: Above-the-fold styles inlined

### Constitutional Performance Targets
- **Component Load Time**: <50ms individual component render
- **CSS Bundle**: <20KB total component styles
- **Accessibility Check**: <10ms validation per component
- **Theme Switch**: <100ms transition time

### Core Web Vitals Impact
- **CLS (Cumulative Layout Shift)**: 0 - No layout shifts
- **FCP (First Contentful Paint)**: Optimized critical CSS path
- **LCP (Largest Contentful Paint)**: Efficient component rendering

## 🔧 Development Workflow

### Creating New Components

1. **Component Structure**:
```astro
---
// Props interface
interface Props {
  // Define props with TypeScript
}

// Component logic (if needed)
const { class: className, ...props } = Astro.props;
---

<!-- Component template -->
<div class={cn("base-styles", className)} {...props}>
  <slot />
</div>

<style>
  /* Component-specific styles */
</style>
```

2. **Constitutional Requirements**:
- ✅ TypeScript interface for all props
- ✅ Accessibility attributes included
- ✅ Performance optimization applied
- ✅ Theme support implemented
- ✅ Zero JavaScript preference

3. **Testing Checklist**:
- [ ] Accessibility validation passes
- [ ] Theme switching works correctly
- [ ] Responsive design tested
- [ ] Performance targets met
- [ ] Cross-browser compatibility verified

### Component Customization

**Using the `cn` utility**:
```astro
---
import { cn } from '@/lib/utils';

interface Props {
  class?: string;
}

const { class: className } = Astro.props;
---

<div class={cn(
  "default-styles",
  "hover:enhanced-styles",
  className
)}>
  <slot />
</div>
```

**Constitutional Styling Patterns**:
```css
/* Performance-first classes */
.constitutional-component {
  @apply
    /* Layout */
    relative flex items-center justify-center

    /* Typography */
    text-sm font-medium

    /* Theming */
    bg-background text-foreground

    /* Accessibility */
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring

    /* Performance */
    transition-colors duration-200

    /* Responsive */
    px-4 py-2 sm:px-6 sm:py-3;
}
```

## 📋 Testing & Validation

### Accessibility Testing
```bash
# Run accessibility validation
python3 scripts/accessibility_validator.py --component-check

# Test with screen readers
# - NVDA (Windows)
# - VoiceOver (macOS)
# - Orca (Linux)
```

### Performance Testing
```bash
# Component performance benchmarks
./local-infra/runners/benchmark-runner.sh --components

# Bundle size analysis
npm run build:analyze
```

### Constitutional Compliance
```bash
# Validate component library compliance
python3 scripts/constitutional_automation.py --components

# Check design system consistency
./local-infra/runners/test-runner-local.sh --design-system
```

## 🎯 Best Practices

### Component Development
1. **Start with Accessibility**: Design with screen readers in mind
2. **Performance First**: Minimize JavaScript dependencies
3. **Theme Support**: Use CSS custom properties consistently
4. **Responsive Design**: Mobile-first approach
5. **Constitutional Compliance**: Follow all framework requirements

### Styling Guidelines
1. **Use Tailwind Classes**: Prefer utility classes over custom CSS
2. **CSS Custom Properties**: For theme-aware values
3. **Logical Properties**: Use `margin-inline` instead of `margin-left/right`
4. **Container Queries**: For component-based responsive design
5. **Reduced Motion**: Respect user preferences

### Integration Patterns
1. **Composition Over Inheritance**: Use slots and composition
2. **Prop Drilling Avoidance**: Use context when needed
3. **Performance Monitoring**: Measure component impact
4. **Error Boundaries**: Graceful degradation
5. **Progressive Enhancement**: Work without JavaScript

## 🔗 Resources

### Documentation Links
- [Astro Components Guide](https://docs.astro.build/en/core-concepts/astro-components/)
- [shadcn/ui Documentation](https://ui.shadcn.com/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

### Internal Resources
- [Performance Guide](../performance/README.md)
- [Accessibility Documentation](../constitutional/README.md)
- [Development Guide](development.md)
- [API Documentation](../api/components/README.md)

---

**Constitutional Component Library v2.0**
**Last Updated**: 2025-09-20
**Compliance Status**: ✅ All constitutional requirements met
**Performance Targets**: ✅ All targets achieved