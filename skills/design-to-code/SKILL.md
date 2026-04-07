---
name: design-to-code
description: Use when the user provides screenshots, mockups, or design assets and wants implementation that stays visually close to the source.
---

# Design To Code

Use this skill for image-led UI implementation.

## Required process

Before coding, break down the design into these layers:

1. **Layout** — identify the grid, flexbox, or other layout system. Note container widths, alignment, and nesting depth. Map to existing layout components or patterns in the codebase.
2. **Typography** — font family, size, weight, line-height, letter-spacing for each text element. Map to the project's type scale or design tokens if they exist.
3. **Color** — exact color values for backgrounds, text, borders, and interactive elements. Map to the project's color tokens or variables. Flag any color not in the existing palette.
4. **Spacing** — margins, paddings, gaps between elements. Map to the project's spacing scale if it exists.
5. **Radius, border, shadow** — border-radius, border widths and styles, box-shadows. Note which elements have them and which do not.
6. **Interaction states** — default, hover, focus, active, disabled, loading, error, and empty states. If the design does not show all states, infer reasonable defaults and call them out.
7. **Responsive or device differences** — if the design shows multiple breakpoints, note the differences. If only one size is shown, state the assumed breakpoint and note what might need adaptation.

## Matching vs. inferring

At the end of the breakdown, explicitly separate:

- **Exact matches** — values and layouts clearly visible in the design
- **Inferences** — values you estimated because the design was incomplete or ambiguous

This lets the reviewer know what to double-check.

## Implementation guidelines

- **Reuse existing components** — before creating a new component, check if one already exists that can be extended or composed.
- **Use project tokens** — prefer design tokens, CSS variables, or theme values over hard-coded colors, sizes, and fonts.
- **Mobile-first is default** — unless the design clearly targets desktop-first, build for narrow viewports and scale up.
- **Accessibility minimums** — ensure sufficient color contrast (WCAG AA), semantic HTML elements, keyboard navigability, and alt text for images.
- **Do not redesign** — if the design is inconsistent with the project's existing patterns, implement the design as-is and flag the inconsistency in your output. Do not silently "fix" the design.

## Common mistakes to avoid

- Replacing a specific visual source with a generic template component
- Abstracting too early (creating a reusable component from a one-off screen)
- Hard-coding pixel values instead of using the project's spacing/sizing system
- Ignoring interaction states that the design didn't explicitly show
- Missing responsive behavior entirely

## Use this skill when

- the user provides screenshots, mockups, or design files
- the task is primarily about visual fidelity
- the deliverable is a UI component or page that must match a visual reference
