# SVG Helper Guide

## Overview

The `SvgHelper` module provides a clean, standardized way to use SVG icons in your ERB views, significantly reducing HTML clutter and ensuring consistency.

## Basic Usage

### Predefined Icon Helpers

Use shorthand helpers for common icons:

```erb
<%= icon_document %>
<%= icon_eye %>
<%= icon_users %>
<%= icon_blocks %>
<%= icon_arrow_left %>
<%= icon_external_link %>
<%= icon_expand %>
<%= icon_collapse_all %>
<%= icon_expand_all %>
<%= icon_drag_handle %>
```

### Size Options

#### Predefined Sizes

```erb
<%= icon_document size: :xs %>   <!-- 12px / 0.75rem -->
<%= icon_document size: :sm %>   <!-- 16px / 1rem -->
<%= icon_document size: :md %>   <!-- 20px / 1.25rem (default) -->
<%= icon_document size: :lg %>   <!-- 24px / 1.5rem -->
<%= icon_document size: :xl %>   <!-- 32px / 2rem -->
<%= icon_document size: "2xl" %> <!-- 48px / 3rem -->
<%= icon_document size: "3xl" %> <!-- 64px / 4rem -->
```

#### Custom Sizes

```erb
<%= icon_document size: "2.5rem" %>
<%= icon_document size: "40px" %>
```

### Color Options

#### Predefined Colors

```erb
<%= icon_document color: :blue %>   <!-- rgb(59, 130, 246) -->
<%= icon_document color: :green %>  <!-- rgb(16, 185, 129) -->
<%= icon_document color: :purple %> <!-- rgb(139, 92, 246) -->
<%= icon_document color: :orange %> <!-- rgb(245, 158, 11) -->
<%= icon_document color: :red %>    <!-- rgb(239, 68, 68) -->
<%= icon_document color: :gray %>   <!-- rgb(107, 114, 128) -->
<%= icon_document color: :teal %>   <!-- rgb(20, 184, 166) -->
<%= icon_document color: :current %><!-- currentColor (inherits from parent) -->
```

#### Custom Colors

```erb
<%= icon_document fill: "#ff0000" %>
<%= icon_document stroke: "rgb(255, 0, 0)" %>
<%= icon_document color: :blue, fill: :red %> <!-- stroke blue, fill red -->
```

### CSS Classes

```erb
<%= icon_document class: "mr-2" %>
<%= icon_document class: "text-blue-500" %> <!-- Uses currentColor -->
```

### Combined Options

```erb
<%= icon_document size: "2xl", color: :blue, class: "mr-2" %>
<%= icon_eye size: :lg, stroke: :green %>
<%= icon_users size: :xl, color: :purple, class: "hover:text-blue-500" %>
```

## Advanced Usage

### Generic SVG Icon Helper

For icons not predefined:

```erb
<%= svg_icon "custom-name", size: :md, color: :blue %>
```

This will:
1. First try to load from `app/assets/images/icons/custom-name.svg`
2. Fallback to a generic icon if not found

### Custom SVG Assets

To use custom SVG files:

1. Place your SVG files in: `app/assets/images/icons/`
2. Name them descriptively: `settings.svg`, `notification.svg`, etc.
3. Use them: `<%= svg_icon "settings", size: :md, color: :blue %>`

**SVG File Requirements:**
- Should contain only the `<path>` or `<g>` elements (no outer `<svg>`)
- OR include the full `<svg>` tag (the helper will use it as-is)
- Use `currentColor` for parts that should inherit color

## Before & After Examples

### Before (Old Way)

```erb
<div class="text-blue-500">
  <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
  </svg>
</div>
```

### After (New Way)

```erb
<div class="text-blue-500">
  <%= icon_document size: "2xl", color: :blue %>
</div>
```

**Reduction:** 5 lines → 1 line (80% less code!)

## Benefits

1. **Cleaner Code:** 70-80% reduction in SVG markup
2. **Consistency:** Standardized sizes and colors across the app
3. **Maintainability:** Update icons in one place
4. **Flexibility:** Mix predefined and custom options
5. **Performance:** Icons can be cached
6. **Type Safety:** Predefined size/color constants prevent typos

## Adding New Icons

To add a new predefined icon helper:

1. Open `app/helpers/svg_helper.rb`
2. Add a new method:

```ruby
def icon_your_name(**options)
  svg_tag(<<-SVG, **options)
    <path d="YOUR_SVG_PATH_HERE" />
  SVG
end
```

3. Use it: `<%= icon_your_name size: :md, color: :blue %>`

## Tailwind Integration

The helper works seamlessly with Tailwind:

```erb
<!-- Using Tailwind classes for color -->
<div class="text-red-500">
  <%= icon_document color: :current %> <!-- Inherits red-500 -->
</div>

<!-- Using Tailwind classes for sizing and spacing -->
<%= icon_document class: "w-4 h-4 mr-2" %>

<!-- Hover states -->
<%= icon_document class: "hover:text-blue-500 transition-colors" color: :current %>
```

## Migration Strategy

1. **Start with high-traffic views** (dashboard, headers)
2. **Replace inline SVGs** with helper calls
3. **Test thoroughly** to ensure visual consistency
4. **Gradually refactor** other views

## Notes

- Default size is `:md` (20px)
- Default stroke is `currentColor` (inherits text color)
- Default fill is `none` (for outline icons)
- All icons have `aria-hidden="true"` for accessibility
