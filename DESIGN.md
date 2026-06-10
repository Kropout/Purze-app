---
name: Luminous Obsidian
colors:
  surface: '#0f141b'
  surface-dim: '#0f141b'
  surface-bright: '#343941'
  surface-container-lowest: '#090f15'
  surface-container-low: '#171c23'
  surface-container: '#1b2027'
  surface-container-high: '#252a32'
  surface-container-highest: '#30353d'
  on-surface: '#dee2ec'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#dee2ec'
  inverse-on-surface: '#2c3138'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#ddb7ff'
  on-tertiary: '#490080'
  tertiary-container: '#b76dff'
  on-tertiary-container: '#400071'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#f0dbff'
  tertiary-fixed-dim: '#ddb7ff'
  on-tertiary-fixed: '#2c0051'
  on-tertiary-fixed-variant: '#6900b3'
  background: '#0f141b'
  on-background: '#dee2ec'
  surface-variant: '#30353d'
typography:
  headline-xl:
    fontFamily: Geist
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
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
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  margin-desktop: 64px
  margin-mobile: 20px
  container-max: 1280px
---

## Brand & Style

This design system is defined by a sophisticated, "liquid glass" aesthetic that balances high-end technical precision with a softened, approachable dark mode. The personality is premium and cutting-edge, yet avoids the harshness of pure black interfaces by utilizing a deep, atmospheric charcoal navy.

The visual style employs **Glassmorphism** as its core driver. Interfaces should feel layered, with semi-transparent surfaces that catch light at the edges, creating a sense of depth and fluid motion. This approach evokes a feeling of transparency and clarity, aimed at professional users who value both aesthetic beauty and functional accessibility.

## Colors

The palette transitions away from high-intensity blacks toward a softer, more legible charcoal navy (`#161b22`). This base color reduces eye strain while maintaining a premium "obsidian" feel. 

- **Primary & Secondary:** A vibrant pairing of Electric Blue and Cyan provides high-contrast interaction points that remain accessible against the navy backdrop.
- **Accents:** A soft Violet is used sparingly for tertiary highlights and state changes.
- **Surface Strategy:** Backgrounds are not flat. They use subtle radial gradients that are 5-10% lighter in the center of the viewport to simulate a light source behind the glass.

## Typography

The typography system relies on the technical precision of **Geist** for headings and UI labels, paired with the universal readability of **Inter** for long-form content. 

To maintain the "liquid" feel, headings use tighter letter spacing and heavier weights. Body text remains generous in line height to ensure maximum legibility against the semi-transparent glass surfaces. For mobile views, large display type is scaled down to prevent excessive wrapping while maintaining its bold, geometric character.

## Layout & Spacing

This design system utilizes a **12-column fluid grid** for desktop and a **4-column fluid grid** for mobile devices. The layout philosophy emphasizes breathable white space (or "empty depth") to allow the glass effects to shine without feeling cluttered.

- **Desktop:** 64px outer margins with 24px gutters.
- **Mobile:** 20px outer margins with 16px gutters.
- **Rhythm:** All internal spacing follows a 4px baseline grid. Components typically use 16px or 24px padding to create a sense of internal "air."

## Elevation & Depth

Depth is conveyed through **backlight and refraction** rather than traditional drop shadows.

1.  **Glass Layers:** Use a background-blur of `12px` to `20px` on all container surfaces.
2.  **Tonal Stacking:** Higher elevation levels are represented by increasing the opacity of the surface's white tint (from 4% to 12%) and increasing the thickness of a 1px "inner glow" border.
3.  **Refraction:** Components at the highest elevation use a subtle linear gradient border (top-left to bottom-right) that transitions from a low-opacity white to a completely transparent stroke.
4.  **Shadows:** When used, shadows are extremely diffused, using the primary accent color at 5% opacity to simulate colored light passing through the glass.

## Shapes

The shape language is smooth and organic. A standard radius of `0.5rem` (8px) is applied to most UI components, while larger containers and cards utilize `1rem` (16px). 

Interactive elements like buttons and chips should feel "tactile" but not fully circular unless they are icon-only actions. The goal is to simulate high-quality machined glass with polished edges.

## Components

- **Buttons:** Primary buttons use a vibrant solid-to-gradient fill with a white 10% overlay on hover. Secondary buttons use a glass-blur background with a 1px border.
- **Input Fields:** Inputs should be semi-transparent with a 1px bottom border that glows (intensifies in color) when focused. 
- **Cards:** Cards are the primary expression of the "liquid obsidian" style. They must feature a `backdrop-filter: blur()` and a subtle gradient stroke to separate them from the background.
- **Chips:** Small, pill-shaped elements with high-saturation backgrounds and white text, used for status indicators.
- **Lists:** List items are separated by low-opacity "ghost" lines (1px height, 5% white) rather than heavy dividers to maintain the fluid aesthetic.