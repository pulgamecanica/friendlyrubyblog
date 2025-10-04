# Simple Toast Notification System

A clean, Rails-native toast system using Stimulus controllers. Each toast is an individual Stimulus controller instance that shows and auto-hides.

## How It Works

1. **Helper creates turbo stream** that appends toast div to container
2. **Stimulus connects** to the new div automatically
3. **Toast shows** with CSS animations and auto-hides
4. **DOM cleanup** happens after animation completes

## Usage in Turbo Stream Views

```erb
<!-- In your .turbo_stream.erb files -->

<!-- Success toast -->
<%= success_toast "Document updated successfully!" %>

<!-- Error toast -->
<%= error_toast "Failed to save changes" %>

<!-- Warning toast -->
<%= warning_toast "Please review your input" %>

<!-- Info toast -->
<%= info_toast "Document unpublished" %>

<!-- With custom duration (milliseconds) -->
<%= success_toast "Saved!", duration: 5000 %>
```

## Available Toast Types

- `success` - Green gradient
- `error` - Red gradient
- `warning` - Orange gradient
- `info` - Blue gradient

## Options

- `duration`: Time in milliseconds before auto-hide (default: 3000)

## Layout Setup

The author layout includes a toast container:

```html
<div id="toast_container" class="toast-container"></div>
```

## Toast Behavior

- **Auto-show**: Appears immediately when appended
- **Auto-hide**: Disappears after duration expires
- **Click to dismiss**: Click any toast to hide it immediately
- **Stacking**: Multiple toasts stack vertically
- **Smooth animations**: CSS transitions for show/hide

## Example Controller Usage

```ruby
class Author::DocumentsController < ApplicationController
  include ToastHelper

  def update
    if @document.update(params)
      respond_to do |format|
        format.turbo_stream # renders update.turbo_stream.erb
      end
    end
  end
end
```

And in `update.turbo_stream.erb`:

```erb
<!-- Update content -->
<%= turbo_stream.replace "document_form" do %>
  <%= render "form", document: @document %>
<% end %>

<!-- Show success toast -->
<%= success_toast "Document updated successfully!" %>
```

## No JavaScript Globals

Unlike many toast libraries, this system doesn't pollute the global namespace. Each toast is self-contained and managed by its own Stimulus controller instance.