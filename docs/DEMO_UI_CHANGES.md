# Demo-Based UI Change List

This document lists the CSS/UI updates needed to align the current app UI with the visual style and interaction patterns shown in `demo.html`.

## Scope

- Source of truth for target look: `demo.html` (inline style block and UI sections).
- Current implementation files to update: styles under `app/assets/stylesheets/`.

## Required UI Changes

### 1) Global Theme Tokens (required)

Files:
- `app/assets/stylesheets/colors.css`
- `app/assets/stylesheets/base.css`

Changes:
- Add demo-aligned semantic tokens and keep existing tokens backward compatible:
  - `--bg-purple: #742e7b`
  - `--surface: #ffffff`
  - `--surface-alt: #fafafa`
  - `--text-primary: #111111`
  - `--text-secondary: #777777`
  - `--border-color: #eaeaea`
  - `--msg-bg: #f4f4f3`
  - `--pill-hover: #f0f0f0`
  - `--accent-red`, `--accent-green`, `--accent-blue`, `--accent-purple`
- Map existing app tokens (`--color-bg`, `--color-text`, `--color-border`, etc.) to the new semantic layer where possible.
- Update global typography scale to match demo emphasis:
  - Header title around `20px`, card title around `16px`, metadata around `12-13px`.

### 2) App Shell Layout (required)

Files:
- `app/assets/stylesheets/layout.css`

Changes:
- Convert top-level page framing to demo shell:
  - Purple page background.
  - Centered white container with rounded corners.
  - `max-width` around `1200px`, `height` around `90vh`.
  - Soft elevation shadow.
- Keep current grid logic, but move visual framing from full-bleed layout into the container shell.
- Add clear split between main pane and right sidebar with a subtle border.

### 3) Header / Top Navigation (required)

Files:
- `app/assets/stylesheets/nav.css`

Changes:
- Restyle header as a sticky white bar with bottom border (`1px solid var(--border-color)`).
- Increase header padding to match demo spacing (`~20px 24px`).
- Introduce visual primitives used by demo:
  - circular brand icon (`32x32`)
  - black rounded section pill
  - bold title text
- Keep current behavior (room/search state) but simplify heavy blur overlays to demo-like flat surfaces.

### 4) Sidebar Visual Language (required)

Files:
- `app/assets/stylesheets/sidebar.css`

Changes:
- Set sidebar width and visual rhythm to demo:
  - fixed width near `300px`
  - white background
  - vertical grouped sections with uppercase mini titles
- Update room/channel pills:
  - rounded pill shape
  - transparent default state
  - subtle hover background
  - active state with dark border and slightly stronger weight
- Add nested thread visual hierarchy (indented sub-items and left guide line).
- Keep existing unread affordances, but visually align them with demo chip/pill styling.

### 5) Card System for Dashboards and Settings (required)

Files:
- `app/assets/stylesheets/panels.css`
- `app/assets/stylesheets/utilities.css`

Changes:
- Add reusable card primitives to support dashboard/overview screens:
  - white card surface
  - 1px border
  - `10-12px` radius
  - light shadow
  - consistent internal padding (`20-24px`)
- Add utility classes for:
  - dashboard grids
  - metric cards
  - badges (red/orange/green/gray/blue)
  - section headers with uppercase labels

### 6) Message Feed + Topic Blocks (required)

Files:
- `app/assets/stylesheets/messages.css`

Changes:
- Shift message area surface from full-bleed to demo feed blocks:
  - feed background using `--surface-alt`
  - grouped blocks/cards for topic streams where applicable
- Update message bubble styling:
  - background `--msg-bg`
  - asymmetric radius pattern similar to demo
  - max width about `85%`
  - tighter sender/timestamp metadata row
- Align avatar sizes and spacing:
  - avatar near `36px`
  - `12px` gap between avatar and message content.

### 7) Composer / Input Pill (required)

Files:
- `app/assets/stylesheets/composer.css`
- `app/assets/stylesheets/inputs.css`

Changes:
- Restyle composer into a pill input container:
  - rounded full pill (`50px` style)
  - muted background
  - horizontal icon + input alignment
  - top border separator above composer area
- Preserve attachment and rich text workflows, but migrate to the simplified visual container.
- Ensure focused state uses a clear border/outline consistent with demo black accent.

### 8) Buttons and Action Chips (required)

Files:
- `app/assets/stylesheets/buttons.css`

Changes:
- Add explicit demo variants:
  - primary black button with white text
  - neutral outlined action button
  - danger action button (light red surface + red text)
- Normalize button radii to `6px` for action buttons and `50px` for navigation pills.
- Keep existing accessibility focus styles and disabled behavior.

### 9) Tables, Forms, and Settings Cards (required)

Files:
- `app/assets/stylesheets/inputs.css`
- `app/assets/stylesheets/panels.css`
- (optional split) new partial if preferred for settings/table styles

Changes:
- Add demo-aligned settings cards:
  - bordered containers
  - section title with bottom divider
  - tighter vertical spacing
- Add data table style layer:
  - uppercase small headers
  - row separators
  - readable cell spacing
- Align form controls to demo style (`8-10px` radius, subtle border, clear focus state).

### 10) Motion and Interaction (required)

Files:
- `app/assets/stylesheets/animation.css`
- `app/assets/stylesheets/sidebar.css`
- `app/assets/stylesheets/messages.css`

Changes:
- Use subtle, purposeful transitions:
  - hover background and border transitions (`~0.2s`)
  - slight card lift on interactive cards
  - sidebar/drawer slide transitions
- Avoid strong blur-heavy effects where demo uses flat or lightly elevated surfaces.

### 11) Responsive Behavior (required)

Files:
- `app/assets/stylesheets/layout.css`
- `app/assets/stylesheets/sidebar.css`
- `app/assets/stylesheets/messages.css`

Changes:
- Match demo breakpoints for major layout shifts:
  - collapse multi-column cards to single column around `1024-1100px`
  - stack briefing/project grids on narrow widths
  - preserve usable composer/message spacing on mobile
- Ensure right sidebar behavior remains usable on small screens (slide in/out if retained).

### 12) Accessibility and Contrast Checks (required)

Files:
- All touched stylesheets

Changes:
- Validate contrast for secondary text and badges on white/light backgrounds.
- Preserve keyboard focus visibility for nav pills, channel items, message actions, and inputs.
- Ensure sticky header and side navigation do not trap focus or hide content at zoomed sizes.

## Priority Order

1. Theme tokens + app shell (`colors.css`, `base.css`, `layout.css`)
2. Header + sidebar (`nav.css`, `sidebar.css`)
3. Message/feed + composer (`messages.css`, `composer.css`, `inputs.css`)
4. Cards/forms/tables/buttons (`panels.css`, `buttons.css`, `utilities.css`)
5. Motion + responsive refinements (`animation.css` and media queries)

## Acceptance Checklist

- Page uses purple outer background and centered rounded app shell.
- Main header appears as a sticky white bar with clear section identity.
- Sidebar uses pill-based channel navigation with clear active/hover states.
- Message feed uses soft cards/bubbles and improved spacing hierarchy.
- Composer appears as a rounded input pill with clean actions.
- Dashboard/settings views use consistent card, badge, and table styles.
- Mobile layout remains readable and navigable without overlap issues.