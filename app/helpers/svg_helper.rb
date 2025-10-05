# frozen_string_literal: true

require_dependency Rails.root.join("lib/merge_preserve_all_hash").to_s
using MergePreserveAllHash

module SvgHelper
  # Size presets (in rem for consistency with Tailwind)
  SIZES = {
    xs: "0.75rem",    # 12px - w-3 h-3
    sm: "1rem",       # 16px - w-4 h-4
    md: "1.25rem",    # 20px - w-5 h-5
    lg: "1.5rem",     # 24px - w-6 h-6
    xl: "2rem",       # 32px - w-8 h-8
    "2xl": "3rem",    # 48px - w-12 h-12
    "3xl": "4rem"     # 64px - w-16 h-16
  }.freeze

  # Color presets matching your Tailwind theme
  COLORS = {
    primary: "currentColor",
    blue: "rgb(59, 130, 246)",
    green: "rgb(16, 185, 129)",
    purple: "rgb(139, 92, 246)",
    orange: "rgb(245, 158, 11)",
    red: "rgb(239, 68, 68)",
    gray: "rgb(107, 114, 128)",
    teal: "rgb(20, 184, 166)",
    white: "rgb(255, 255, 255)",
    current: "currentColor"
  }.freeze

  # Main SVG helper
  # Usage:
  #   <%= svg_icon "document", size: :md, color: :blue %>
  #   <%= svg_icon "arrow-left", size: "1.5rem", fill: "red" %>
  #   <%= svg_icon "eye", class: "custom-class" %>
  def svg_icon(name, **options)
    # Resolve size
    size = resolve_size(options[:size] || :md)

    # Resolve colors
    fill = resolve_color(options[:fill])
    stroke = resolve_color(options[:stroke] || options[:color])

    # Build attributes
    attrs = {
      class: options[:class],
      width: size,
      height: size,
      fill: fill || "none",
      stroke: stroke || "currentColor",
      viewBox: options[:viewBox] || "0 0 24 24",
      "stroke-width": options[:stroke_width] || options[:"stroke-width"],
      "stroke-linecap": options[:stroke_linecap] || options[:"stroke-linecap"],
      "stroke-linejoin": options[:stroke_linejoin] || options[:"stroke-linejoin"]
    }.compact

    # Try to load from assets first, fallback to inline definition
    svg_content = load_svg_from_assets(name) || inline_svg_content(name, attrs)

    return svg_content if svg_content

    # Fallback: generic icon
    content_tag(:svg, **attrs) do
      tag.path(d: "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5")
    end
  end

  # Shortcut helpers for common icons
  def icon_document(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
    SVG
  end

  def icon_eye(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
    SVG
  end

  def icon_users(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
    SVG
  end

  def icon_blocks(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-3zM14 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1h-4a1 1 0 01-1-1v-3z" />
    SVG
  end

  def icon_arrow_left(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
    SVG
  end

  def icon_external_link(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
    SVG
  end

  def icon_expand(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"></path>
    SVG
  end

  def icon_collapse_all(**options)
    svg_tag(<<-SVG, **{ viewBox: "0 0 48 48", fill: "currentColor", stroke: "none" }.merge_preserve_all(options))
      <path d="M22.6,15.4a1.9,1.9,0,0,0,2.8,0l6-5.9a2.1,2.1,0,0,0,.2-2.7,1.9,1.9,0,0,0-3-.2L26,9.2V4a2,2,0,0,0-4,0V9.2L19.4,6.6a1.9,1.9,0,0,0-3,.2,2.1,2.1,0,0,0,.2,2.7Z"></path>
      <path d="M25.4,32.6a1.9,1.9,0,0,0-2.8,0l-6,5.9a2.1,2.1,0,0,0-.2,2.7,1.9,1.9,0,0,0,3,.2L22,38.8V44a2,2,0,0,0,4,0V38.8l2.6,2.6a1.9,1.9,0,0,0,3-.2,2.1,2.1,0,0,0-.2-2.7Z"></path>
      <path d="M6,22H42a2,2,0,0,0,0-4H6a2,2,0,0,0,0,4Z"></path>
      <path d="M42,26H6a2,2,0,0,0,0,4H42a2,2,0,0,0,0-4Z"></path>
    SVG
  end

  def icon_expand_all(**options)
    svg_tag(<<-SVG, **{ viewBox: "0 0 48 48", fill: "currentColor", stroke: "none" }.merge_preserve_all(options))
      <path style="rotate: 180deg; transform-origin: 0; transform: translate(-100%, 65%);" d="M22.6,15.4a1.9,1.9,0,0,0,2.8,0l6-5.9a2.1,2.1,0,0,0,.2-2.7,1.9,1.9,0,0,0-3-.2L26,9.2V4a2,2,0,0,0-4,0V9.2L19.4,6.6a1.9,1.9,0,0,0-3,.2,2.1,2.1,0,0,0,.2,2.7Z"></path>
      <path style="rotate: 180deg; transform-origin: 0; transform: translate(-100%, -65%);" d="M25.4,32.6a1.9,1.9,0,0,0-2.8,0l-6,5.9a2.1,2.1,0,0,0-.2,2.7,1.9,1.9,0,0,0,3,.2L22,38.8V44a2,2,0,0,0,4,0V38.8l2.6,2.6a1.9,1.9,0,0,0,3-.2,2.1,2.1,0,0,0-.2-2.7Z"></path>
      <path d="M6,22H42a2,2,0,0,0,0-4H6a2,2,0,0,0,0,4Z"></path>
      <path d="M42,26H6a2,2,0,0,0,0,4H42a2,2,0,0,0,0-4Z"></path>
    SVG
  end

  def icon_drag_handle(**options)
    svg_tag(<<-SVG, **{ fill: "currentColor" }.merge_preserve_all(options))
      <path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"></path>
    SVG
  end

  def icon_plus(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
    SVG
  end

  def icon_trash(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
    SVG
  end

  def icon_clock(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    SVG
  end

  def icon_checkmark_circle(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    SVG
  end

  def icon_x_circle(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    SVG
  end

  def icon_grid(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path>
    SVG
  end

  def icon_list(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
    SVG
  end

  def icon_chevron_right(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
    SVG
  end

  def icon_chevron_down(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
    SVG
  end

  def icon_chat(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
    SVG
  end

  def icon_shield(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
    SVG
  end

  def icon_archive(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"></path>
    SVG
  end

  def icon_info(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    SVG
  end

  def icon_code(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"></path>
    SVG
  end

  def icon_markdown(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM16 7a1 1 0 011-1h2a1 1 0 011 1v11a1 1 0 01-1 1h-2a1 1 0 01-1-1V7z"></path>
    SVG
  end

  def icon_monitor(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
    SVG
  end

  def icon_image(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
    SVG
  end

  def icon_photo(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
    SVG
  end

  def icon_mlx42(**options)
    svg_tag(<<-SVG, **options)
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
    SVG
  end

  def icon_spinner(**options)
    svg_tag(<<-SVG, **{ fill: "none", class: "animate-spin" }.merge_preserve_all(options))
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    SVG
  end

  private

  # Generic SVG wrapper for paths
  def svg_tag(content, **options)
    size = resolve_size(options[:size] || :md)
    fill = resolve_color(options[:fill])
    stroke = resolve_color(options[:stroke] || options[:color])

    attrs = {
      class: options[:class],
      width: size,
      height: size,
      fill: fill || "none",
      stroke: stroke || "currentColor",
      viewBox: options[:viewBox] || "0 0 24 24",
      "aria-hidden": "true"
    }.compact

    attrs.merge!(options)

    content_tag(:svg, **attrs) do
      content.html_safe
    end
  end

  def resolve_size(size)
    return SIZES[:md] if size.nil?
    return size if size.is_a?(String) && (size.include?("px") || size.include?("rem"))

    SIZES[size.to_sym] || SIZES[:md]
  end

  def resolve_color(color)
    return nil if color.nil?
    return color if color.is_a?(String) && (color.start_with?("#") || color.start_with?("rgb"))

    COLORS[color.to_sym]
  end

  def load_svg_from_assets(name)
    # Try to load SVG from app/assets/images/icons/
    path = Rails.root.join("app", "assets", "images", "icons", "#{name}.svg")
    return nil unless File.exist?(path)

    File.read(path).html_safe
  rescue StandardError
    nil
  end

  def inline_svg_content(name, _attrs)
    # Map common icon names to their SVG paths
    # This is a fallback system
    nil
  end
end
