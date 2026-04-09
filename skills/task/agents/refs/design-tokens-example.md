# Design Tokens Example

## CSS Custom Properties

```css
:root {
  /* Colors */
  --color-primary: #3B82F6;
  --color-primary-hover: #2563EB;
  --color-secondary: #6B7280;
  --color-accent: #F59E0B;
  --color-bg-main: #FFFFFF;
  --color-bg-card: #F9FAFB;
  --color-text-heading: #111827;
  --color-text-body: #374151;
  --color-text-muted: #9CA3AF;
  --color-border: #E5E7EB;
  --color-success: #10B981;
  --color-error: #EF4444;

  /* Typography */
  --font-heading: 'Inter', sans-serif;
  --font-body: 'Inter', sans-serif;
  --text-h1: 2rem / 1.2;
  --text-body: 1rem / 1.5;
  --text-small: 0.875rem / 1.4;

  /* Spacing (base: 4px) */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;

  /* Border Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.07);
}
```

## Tailwind Config Equivalent

```js
// tailwind.config.js extend
{
  colors: {
    primary: { DEFAULT: '#3B82F6', hover: '#2563EB' },
    secondary: '#6B7280',
    accent: '#F59E0B',
  },
  fontFamily: {
    heading: ['Inter', 'sans-serif'],
    body: ['Inter', 'sans-serif'],
  },
}
```

## Responsive Tokens

```css
/* Responsive tokens -- breakpoint-keyed */
:root {
  --container-max: 1200px;
  --grid-columns: 12;
  --grid-gap: 1.5rem;
}

@media (max-width: 768px) {
  :root {
    --container-max: 100%;
    --grid-columns: 4;
    --grid-gap: 1rem;
  }
}

@media (max-width: 480px) {
  :root {
    --grid-columns: 1;
    --grid-gap: 0.75rem;
  }
}
```

Tailwind equivalent:

```js
// tailwind.config.js extend
{
  screens: {
    sm: '480px',
    md: '768px',
    lg: '1024px',
    xl: '1280px',
  },
  container: {
    center: true,
    padding: { DEFAULT: '1rem', md: '1.5rem', lg: '2rem' },
  },
}
```

## Dark Mode Tokens

```css
/* Dark mode tokens */
:root {
  --color-bg-main: #FFFFFF;
  --color-bg-surface: #F9FAFB;
  --color-text-heading: #111827;
  --color-text-body: #374151;
  --color-border: #E5E7EB;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-main: #111827;
    --color-bg-surface: #1F2937;
    --color-text-heading: #F9FAFB;
    --color-text-body: #D1D5DB;
    --color-border: #374151;
  }
}
```

Tailwind equivalent:

```js
// tailwind.config.js
{
  darkMode: 'class', // or 'media' for prefers-color-scheme
  theme: {
    extend: {
      colors: {
        surface: { light: '#F9FAFB', dark: '#1F2937' },
      },
    },
  },
}
```

Usage: `<div class="bg-surface-light dark:bg-surface-dark">`

## Animation Tokens

```css
/* Animation tokens */
:root {
  /* Durations */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;

  /* Easings */
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);

  /* Common transitions */
  --transition-colors: color var(--duration-fast) var(--ease-in-out),
                       background-color var(--duration-fast) var(--ease-in-out),
                       border-color var(--duration-fast) var(--ease-in-out);
  --transition-transform: transform var(--duration-normal) var(--ease-out);
  --transition-shadow: box-shadow var(--duration-normal) var(--ease-in-out);
}

/* Keyframes */
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from { transform: translateY(8px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

Tailwind equivalent:

```js
// tailwind.config.js extend
{
  transitionDuration: {
    fast: '150ms',
    normal: '300ms',
    slow: '500ms',
  },
  transitionTimingFunction: {
    'in-out': 'cubic-bezier(0.4, 0, 0.2, 1)',
    'out': 'cubic-bezier(0, 0, 0.2, 1)',
    'bounce': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
  },
  keyframes: {
    'fade-in': { from: { opacity: '0' }, to: { opacity: '1' } },
    'slide-up': {
      from: { transform: 'translateY(8px)', opacity: '0' },
      to: { transform: 'translateY(0)', opacity: '1' },
    },
  },
  animation: {
    'fade-in': 'fade-in 300ms ease-out',
    'slide-up': 'slide-up 300ms ease-out',
  },
}
```
