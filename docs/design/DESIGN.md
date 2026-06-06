---
name: Modern Gastronomy
colors:
  surface: '#f4faff'
  surface-dim: '#d1dce2'
  surface-bright: '#f4faff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eaf5fc'
  surface-container: '#e5eff6'
  surface-container-high: '#dfeaf1'
  surface-container-highest: '#d9e4eb'
  on-surface: '#131d22'
  on-surface-variant: '#41484b'
  inverse-surface: '#283237'
  inverse-on-surface: '#e8f2f9'
  outline: '#71787c'
  outline-variant: '#c1c7cb'
  surface-tint: '#3d6374'
  primary: '#375d6e'
  on-primary: '#ffffff'
  primary-container: '#507687'
  on-primary-container: '#edf8ff'
  inverse-primary: '#a5ccdf'
  secondary: '#755a28'
  on-secondary: '#ffffff'
  secondary-container: '#fdd79a'
  on-secondary-container: '#785c2a'
  tertiary: '#455c65'
  on-tertiary: '#ffffff'
  tertiary-container: '#5d747e'
  on-tertiary-container: '#ebf8ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c1e8fc'
  primary-fixed-dim: '#a5ccdf'
  on-primary-fixed: '#001f29'
  on-primary-fixed-variant: '#244b5b'
  secondary-fixed: '#ffdeaa'
  secondary-fixed-dim: '#e6c185'
  on-secondary-fixed: '#271900'
  on-secondary-fixed-variant: '#5b4313'
  tertiary-fixed: '#cee6f2'
  tertiary-fixed-dim: '#b2cad6'
  on-tertiary-fixed: '#051e27'
  on-tertiary-fixed-variant: '#334a53'
  background: '#f4faff'
  on-background: '#131d22'
  surface-variant: '#d9e4eb'
typography:
  headline-xl:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '600'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '500'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '500'
    lineHeight: 36px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
  section-gap: 80px
---

## Brand & Style
The brand personality is rooted in the intersection of architectural precision and culinary artistry. It evokes a sense of hushed luxury—professional, calm, and deeply intentional. The visual narrative avoids the typical high-contrast aggression of modern tech, opting instead for a "Modern Minimalist" approach with atmospheric depth. 

Targeting a discerning audience that values craft and composure, the UI feels like a curated gallery space. It utilizes generous whitespace, refined tonal shifts, and a singular focal point strategy to guide the user through a high-end gastronomic journey. The emotional response is one of trust, serenity, and quiet confidence.

## Colors
The palette is anchored by a sophisticated, muted blue-grey teal—extracted from the ambient architectural surfaces of the reference environment. This primary tone provides a calm, structural foundation. To maintain the "Modern Gastronomy" aesthetic, the palette is balanced with a secondary "Gilded Gold" accent, reflecting the warm, atmospheric lighting found in high-end dining spaces.

**Light Mode:** Employs an "Airy Studio" feel. Surfaces are near-white with soft teal-tinted neutrals to maintain a cool, professional atmosphere. Text contrast is kept high with a deep charcoal-teal neutral.

**Dark Mode:** Transitions into an "Evening Lounge" experience. The background shifts to a deep, ink-like teal-black, utilizing the primary teal in desaturated, lower-luminance containers to create depth without sacrificing the calm, professional tone.

## Typography
The typographic system emphasizes clarity and modern structure. **Manrope** is utilized for headlines to provide a balanced, geometric yet friendly appearance that feels contemporary. **Inter** handles all functional and body text, ensuring maximum legibility across all digital touchpoints.

Hierarchy is established through weight and purposeful letter-spacing rather than excessive scale. Labels are treated with slight tracking and uppercase styling to denote a sense of "Curated Metadata," reminiscent of a fine-dining menu's utilitarian elegance.

## Layout & Spacing
The design system follows a **Fixed Grid** philosophy for desktop to maintain a controlled, editorial feel, while transitioning to a fluid model for mobile devices. 

- **Desktop (1440px+):** A 12-column grid with a 1120px max-width container. Large 80px gaps between sections create a "Gallery" effect, giving content room to breathe.
- **Mobile (<768px):** A 4-column fluid grid. Margins are reduced to 16px to maximize real estate while keeping gutters at 16px to prevent visual clutter.

Spacing follows an 8px rhythmic scale, ensuring all elements—from icons to containers—align to a consistent vertical and horizontal beat.

## Elevation & Depth
This design system avoids heavy drop shadows in favor of **Tonal Layering** and **Subtle Ambient Shadows**. Depth is primarily conveyed through the "Surface-over-Background" technique.

1.  **Level 0 (Background):** The base canvas color.
2.  **Level 1 (Card/Container):** A subtle shift in hex value (lighter in light mode, lighter/tinted in dark mode) with a very soft, 10% opacity shadow (0px 4px 20px).
3.  **Level 2 (Modals/Popovers):** Higher contrast shifts with a medium-diffused shadow (0px 12px 40px) to indicate temporary overlay status.

In Dark Mode, elevation is further reinforced by increasing the "Primary Teal" tint of the surface—the higher the element, the more primary color is mixed into the neutral base to simulate proximity to a light source.

## Shapes
The shape language is "Soft Professional." By utilizing a **0.25rem (4px) base roundedness**, the UI maintains a structured, architectural precision that aligns with the professional gastronomy theme. 

- **Standard Elements (Buttons, Inputs):** 4px (Soft)
- **Large Containers (Cards, Modals):** 8px (rounded-lg)
- **Interactive Accents:** 12px (rounded-xl)

This subtle rounding prevents the interface from feeling "sharp" or "hostile" while avoiding the playfulness of fully rounded pill shapes.

## Components

- **Buttons:** Primary buttons use the brand teal (`#507687`) with white text. Secondary buttons use an outline style with the primary teal border. For high-action prompts, the "Gilded Gold" secondary color is used sparingly.
- **Input Fields:** Minimalist design with a 1px border using `tertiary_color`. On focus, the border transitions to `primary_color` with a subtle 2px outer glow in the same hue.
- **Cards:** No heavy borders. Use tonal layering (Level 1 elevation) with a clean 24px internal padding. Titles within cards use `headline-lg` (at a reduced 20px size).
- **Chips/Badges:** Small, subtle backgrounds using the `primary_container` color with `on_primary_container` text. This provides category distinction without overwhelming the layout.
- **Lists:** High use of whitespace between items. Dividers are low-contrast (3-5% opacity of the neutral color) to provide structure without creating visual noise.
- **Selection Controls:** Checkboxes and Radios use the `primary_color` for the active state, maintaining the sophisticated blue-grey aesthetic across all functional interactions.