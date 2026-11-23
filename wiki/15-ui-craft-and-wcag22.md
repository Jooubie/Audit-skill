# **Reference 15: Technical Design System & Accessibility Guidelines**

# **Overview & Scope**

This specification establishes structural refactoring principles for UI hierarchy, standardizes constrained CSS tokens via Tailwind CSS, and codifies WCAG 2.2 AA compliance standards. Developers and designers must adhere strictly to these patterns to ensure consistency, maintainability, and full accessibility across all application interfaces.

# **1\. Refactoring UI Hierarchy**

To eliminate visual noise and improve cognitive scannability, UI components must adhere to strict visual hierarchy refactoring guidelines.

## **Core Principles**

* **De-emphasize Borders in Favor of Elevation and Space:** Replace heavy, high-contrast borders with subtle background color shifts (`bg-slate-50`) or lightweight shadows (`shadow-sm`) to delineate container boundaries.  
* **Typographic Contrast over Font Size Variance:** Shift from relying solely on aggressive font size jumps to leveraging font weight (`font-semibold`, `font-bold`) and subtle color contrast reductions (`text-slate-900` vs `text-slate-600`) to signal visual hierarchy.  
* **Intentional Spacing Rhythms:** Establish clear proximity rules. Related elements (e.g., label and input) must sit closer together (`gap-1.5` or `gap-2`) than distinct content blocks (`gap-6` or `gap-8`).  
* **Secondary Actions De-emphasis:** Primary call-to-action (CTA) buttons must be solid fills, secondary actions neutral outlines or ghost buttons, and tertiary actions plain text buttons with hover states.

# **2\. Constrained Tailwind Tokens**

To prevent design drift and maintain strict design system integrity, arbitrary Tailwind utility usage (e.g., `w-[233px]` or `bg-[#123456]`) is disabled in favor of a strictly defined semantic design token subset.

## **Token Abstraction Layer**

| Token Category | Approved Utility Classes | Usage Guidelines |
| :---- | :---- | :---- |
| **Surface Colors** | `bg-surface-primarybg-surface-secondarybg-surface-tertiary` | `bg-white` / `#FFFFFFbg-slate-50` / `#F8FAFCbg-slate-100` / `#F1F5F9` |
| **Text Colors** | `text-content-primarytext-content-secondarytext-content-muted` | High-contrast body & headers (`slate-900`)Supporting labels & descriptions (`slate-600`)Disabled & metadata text (`slate-400`) |
| **Border Colors** | `border-subtleborder-defaultborder-strong` | Dividers & light cards (`slate-100`)Form controls & default cards (`slate-300`)Active states & focus rings (`blue-600`) |
| **Spacing Scale** | `p-1`, `p-2`, `p-3`, `p-4`, `p-6`, `p-8` | Strictly standard 4px grid steps (`4px`, `8px`, `12px`, `16px`, `24px`, `32px`). Arbitrary spacing values are disallowed. |
| **Corner Radius** | `rounded-none`, `rounded-sm`, `rounded`, `rounded-md`, `rounded-lg`, `rounded-full` | `rounded-sm` for tags/badges, `rounded-md` for inputs/buttons, `rounded-lg` for cards/modals. |

# **3\. WCAG 2.2 AA Compliance Standards**

All user interfaces must strictly fulfill WCAG 2.2 Level AA success criteria. Key requirements are codified below.

## **3.1 Color Contrast (SC 1.4.3 & 1.4.11)**

* **Text Contrast (SC 1.4.3):** Regular text (under 18pt / 24px) must maintain a minimum contrast ratio of **4.5:1** against its background. Large text (18pt+ or 14pt+ bold) must achieve at least **3.0:1**.  
* **Non-Text Contrast (SC 1.4.11):** Visual information used to identify user interface components and graphical objects (e.g., input borders, icon buttons, active state indicators) must maintain a minimum contrast ratio of **3.0:1** against adjacent colors.

## **3.2 Non-Color Encoding (SC 1.4.1)**

* Color must not be used as the sole visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element.  
* **Form Validation:** Error states must include an explanatory text message and an error icon (`alert-circle`) alongside a red border color change.  
* **Links:** Inline links embedded within body text must retain an explicit underline (`underline underline-offset-4`) or feature an accompanying trailing icon, rather than relying solely on color divergence.  
* **Status Badges:** System statuses must pair background/text colors with explicit iconography or structural text labels (e.g., "Active", "Pending", "Failed").

## **3.3 Target Size Minimum (SC 2.5.8)**

* All interactive pointer targets (buttons, checkable controls, icon triggers, link blocks) must have a visual or touch area of at least **24x24 CSS pixels**.  
* **Padding Enforcements:** If an icon or visual target is smaller than 24x24px (e.g., a 16x16px close icon), transparent padding must be added using utility classes (`p-1.5` or `min-w-[24px] min-h-[24px]`) to ensure the clickable bounding box meets the minimum size requirement.  
* **Spacing Offset:** Elements smaller than 24x24px that do not feature internal padding must maintain sufficient perimeter spacing so that a 24px diameter circle centered on the target does not intersect any adjacent target circle.

## **3.4 Focus Non-Obscured (SC 2.4.11 & 2.4.12)**

* When a component receives keyboard focus, the element must not be entirely obscured by author-created content, such as sticky headers, sticky footers, or floating notifications.  
* **Scroll Padding Management:** Sticky layouts (e.g., fixed top navigation bars) must apply CSS `scroll-padding-top` or `scroll-padding-bottom` equivalent to the height of the sticky container to prevent keyboard focus auto-scroll from tucking elements under sticky banners.  
* **Focus Indicator Visibility:** Focus indicators must feature a minimum 2px solid outline with a contrast ratio of at least 3.0:1 against surrounding backgrounds, utilizing `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600`.

# **4\. Compliance Verification Matrix**

| WCAG 2.2 SC | Standard Name | Design / Code Token Pattern | Verification Tool |
| :---- | :---- | :---- | :---- |
| **1.4.3** | Contrast (Minimum) | `text-content-primary`, `bg-surface-primary` | CCA,xe-core / Lighthouse |
| **1.4.1** | Use of Color | Icon \+ Text Badge \+ Border (Dual-encoding) | Colorblind Simulator / Manual Check |
| **2.5.8** | Target Size (Minimum) | `min-w-[24px] min-h-[24px]` / `p-2` on icons | Chrome DevTools Element Inspector |
| **2.4.11 / 12** | Focus Non-Obscured | `scroll-pt-16`, `focus-visible:outline-2` | Keyboard Navigation Testing (Tab / Shift+Tab) |

