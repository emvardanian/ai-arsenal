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
