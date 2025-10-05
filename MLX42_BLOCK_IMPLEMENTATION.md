# MLX42 Block Implementation Plan

## Overview
WebAssembly-based MLX42 graphics block for running C code with MLX42 library in the browser.

---

## ✅ Completed Backend

### 1. Model: `Mlx42Block < Block`
- **Location**: `app/models/mlx42_block.rb`
- **Active Storage Attachments**:
  - `wasm_file` - Compiled WebAssembly binary
  - `js_file` - Emscripten JavaScript loader
  - `data_file` - Optional preloaded data
  - `assets` (many) - User-uploaded assets (images, etc.)
- **Data Fields** (stored in JSON):
  - `width` - Canvas width (default: 800)
  - `height` - Canvas height (default: 600)
  - `compiler_args` - Custom emcc arguments
  - `compilation_status` - queued/compiling/success/failed/error
  - `compilation_error` - Error message if compilation fails

### 2. Service: `Mlx42CompilerService`
- **Location**: `app/services/mlx42_compiler_service.rb`
- **Wrapper Template**:
  ```c
  #define WIDTH <user_width>
  #define HEIGHT <user_height>
  mlx_t *mlx; // Global, user can extern
  extern void user_main(int argc, char **argv); // User entry point
  ```
- **Compilation**:
  - Creates temp directory
  - Writes user code to `user_code.c`
  - Writes wrapper to `wrapper_main.c`
  - Copies assets to `assets/` directory
  - Runs `emcc` with MLX42 flags
  - Uses `--preload-file assets` if assets exist
  - Attaches output files to Active Storage

### 3. Job: `Mlx42CompilationJob`
- **Location**: `app/jobs/mlx42_compilation_job.rb`
- **Async Compilation**:
  - Sets status to "compiling"
  - Calls `Mlx42CompilerService`
  - Updates status to "success" or "failed"
  - Broadcasts Turbo Stream update

### 4. Controller Action
- **Location**: `app/controllers/author/blocks_controller.rb`
- **Route**: `POST /author/documents/:document_id/blocks/:id/compile_mlx42`
- **Action**: `compile_mlx42`
  - Validates block type
  - Sets status to "queued"
  - Enqueues `Mlx42CompilationJob`
  - Returns JSON with status

---

## 🚧 TODO: Frontend Implementation

### 1. Block Partial Views

#### A. Edit View (`app/views/author/blocks/_block.html.erb`)
Add MLX42Block case with dual preview mode:

```erb
<% when Mlx42Block %>
  <!-- NORMAL MODE: Dual Preview (Content or Canvas) -->
  <div data-block-editor-target="content">
    <!-- Content Preview (code, assets) -->
    <div data-mlx42-preview-target="contentView" class="bg-white rounded-lg p-6">
      <h3 class="text-sm font-medium text-gray-700 mb-2">MLX42 Code</h3>
      <pre class="bg-gray-900 text-gray-100 p-4 rounded font-mono text-sm overflow-auto"><%= block.text %></pre>

      <% if block.assets.attached? %>
        <h3 class="text-sm font-medium text-gray-700 mt-4 mb-2">Assets</h3>
        <div class="space-y-1">
          <% block.assets.each do |asset| %>
            <div class="text-sm font-mono text-gray-600">assets/<%= asset.filename %></div>
          <% end %>
        </div>
      <% end %>

      <% unless block.compiled? %>
        <div class="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded">
          <p class="text-sm text-yellow-800">⚠️ Not compiled yet. Click "Compile" to build.</p>
        </div>
      <% end %>
    </div>

    <!-- Canvas Preview (MLX42 running) -->
    <div data-mlx42-preview-target="canvasView" style="display: none;">
      <% if block.compiled? %>
        <%= render "author/blocks/mlx42_canvas", block: block %>
      <% else %>
        <div class="bg-gray-100 p-8 rounded text-center">
          <p class="text-gray-600">Compile your code to see the canvas</p>
        </div>
      <% end %>
    </div>
  </div>

  <!-- EDIT MODE: Code editor -->
  <div data-block-editor-target="editor" style="display: none;">
    <%= form_with model: block, url: author_document_block_path(block.document, block) do |f| %>
      <!-- Code textarea -->
      <textarea name="block[text]"
                data-block-editor-target="textarea"
                data-action="input->block-editor#autoResize"
                class="w-full font-mono text-sm bg-gray-900 text-gray-100 p-4 rounded border-0 focus:ring-2 focus:ring-purple-500"
                placeholder="Enter your C code here...
Example:
void user_main(int argc, char **argv) {
  extern mlx_t *mlx;
  // Your MLX42 code here
}"><%= block.text %></textarea>

      <!-- Assets upload -->
      <%= render "author/blocks/mlx42_assets", block: block, form: f %>

      <!-- Hidden submit -->
      <button type="submit" data-block-editor-target="hiddenSubmit" style="display:none;"></button>
    <% end %>
  </div>
<% end %>
```

#### B. Public View (`app/views/public/blocks/_block.html.erb`)
Display compiled MLX42:

```erb
<% when Mlx42Block %>
  <% if block.compiled? %>
    <%= render "public/blocks/mlx42_runner", block: block %>
  <% else %>
    <p class="text-gray-500 italic">MLX42 block not available</p>
  <% end %>
<% end %>
```

### 2. Canvas & Console Partials

#### A. `app/views/author/blocks/_mlx42_canvas.html.erb`
```erb
<div id="mlx42_preview_<%= block.id %>"
     data-controller="mlx42-runner"
     data-mlx42-runner-block-id-value="<%= block.id %>"
     data-mlx42-runner-js-url-value="<%= rails_blob_url(block.js_file) %>"
     data-mlx42-runner-wasm-url-value="<%= rails_blob_url(block.wasm_file) %>"
     data-mlx42-runner-data-url-value="<%= block.data_file.attached? ? rails_blob_url(block.data_file) : '' %>"
     class="relative">

  <!-- Canvas Container -->
  <div class="border-2 border-gray-300 rounded-lg overflow-hidden bg-black relative">
    <canvas id="mlx42_canvas_<%= block.id %>"
            data-mlx42-runner-target="canvas"
            tabindex="-1"
            class="w-full"></canvas>

    <!-- Mouse Capture Indicator -->
    <div data-mlx42-runner-target="captureIndicator"
         style="display: none;"
         class="absolute top-2 right-2 bg-red-600 text-white text-xs px-2 py-1 rounded">
      🖱️ Mouse Captured (ESC to release)
    </div>
  </div>

  <!-- Console Output -->
  <div class="mt-4">
    <div class="text-sm font-medium text-gray-700 mb-2">Console Output:</div>
    <textarea id="mlx42_console_<%= block.id %>"
              data-mlx42-runner-target="console"
              rows="8"
              readonly
              class="w-full font-mono text-xs bg-gray-900 text-green-400 p-4 rounded border border-gray-700"></textarea>
  </div>

  <!-- Loading State -->
  <div data-mlx42-runner-target="loader"
       class="absolute inset-0 bg-white bg-opacity-95 flex items-center justify-center rounded-lg">
    <div class="text-center">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-purple-500 border-t-transparent"></div>
      <p class="mt-2 text-gray-600 text-sm">Loading WebAssembly...</p>
      <p data-mlx42-runner-target="loadProgress" class="text-xs text-gray-500 mt-1"></p>
    </div>
  </div>
</div>
```

#### B. `app/views/author/blocks/_mlx42_assets.html.erb`
```erb
<div class="mt-4 p-4 bg-gray-50 rounded-lg">
  <h4 class="text-sm font-medium text-gray-700 mb-3">Assets (Images, Files)</h4>

  <!-- Upload -->
  <div class="mb-3">
    <%= form.file_field :assets,
        multiple: true,
        direct_upload: true,
        class: "block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-md file:border-0
                file:text-sm file:font-semibold
                file:bg-purple-50 file:text-purple-700
                hover:file:bg-purple-100" %>
    <p class="mt-1 text-xs text-gray-500">Upload images or other files to use in your MLX42 program</p>
  </div>

  <!-- Existing Assets -->
  <% if block.assets.attached? %>
    <div class="space-y-2">
      <div class="text-xs font-medium text-gray-600 uppercase tracking-wide mb-2">Uploaded Assets:</div>
      <% block.assets.each do |asset| %>
        <div class="flex items-center justify-between bg-white p-2 rounded border border-gray-200">
          <code class="text-sm text-purple-600">assets/<%= asset.filename %></code>
          <button type="button"
                  onclick="navigator.clipboard.writeText('assets/<%= asset.filename %>'); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy Path', 1000)"
                  class="text-xs px-2 py-1 bg-purple-100 text-purple-700 rounded hover:bg-purple-200 transition-colors">
            Copy Path
          </button>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="text-xs text-gray-500 italic">No assets uploaded yet</p>
  <% end %>
</div>
```

### 3. Toolbar Updates

#### `app/views/author/blocks/_toolbar.html.erb`
Add MLX42 controls to normal tools:

```erb
<!-- MLX42 Controls (only for Mlx42Block) -->
<% if block.is_a?(Mlx42Block) %>
  <div class="border-t pt-3">
    <div class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-2">
      MLX42 Controls
    </div>

    <!-- Toggle View Button -->
    <button data-action="click->mlx42-preview#toggleView"
            data-mlx42-preview-target="toggleButton"
            class="w-full px-2 py-1.5 text-xs border border-purple-300 text-purple-700 rounded hover:bg-purple-50 transition-colors mb-2">
      📺 Show Canvas
    </button>

    <!-- Capture Mouse Button (only visible in canvas view) -->
    <button data-action="click->mlx42-runner#toggleCapture"
            data-mlx42-preview-target="captureButton"
            style="display: none;"
            class="w-full px-2 py-1.5 text-xs border border-blue-300 text-blue-700 rounded hover:bg-blue-50 transition-colors mb-2">
      🖱️ Capture Mouse
    </button>

    <!-- Compile Button -->
    <button data-action="click->mlx42-compiler#compile"
            data-block-id="<%= block.id %>"
            class="w-full px-2 py-1.5 text-xs bg-purple-600 text-white rounded hover:bg-purple-700 transition-colors">
      🔨 Compile
    </button>

    <!-- Compilation Status -->
    <div id="mlx42_compilation_status_<%= block.id %>"
         data-turbo-stream-target
         class="mt-2 text-xs">
      <%= render "author/blocks/mlx42_compilation_status", block: block %>
    </div>
  </div>
<% end %>
```

#### `app/views/author/blocks/_mlx42_compilation_status.html.erb`
```erb
<% status = block.data.to_h["compilation_status"] %>
<% case status %>
<% when "queued", "compiling" %>
  <div class="flex items-center text-yellow-600 bg-yellow-50 p-2 rounded">
    <svg class="animate-spin h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
    <%= status.capitalize %>...
  </div>
<% when "success" %>
  <div class="flex items-center text-green-600 bg-green-50 p-2 rounded">
    <svg class="h-4 w-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
    </svg>
    Compiled successfully
  </div>
<% when "failed", "error" %>
  <div class="text-red-600 bg-red-50 p-2 rounded">
    <div class="flex items-center">
      <svg class="h-4 w-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
      </svg>
      Compilation failed
    </div>
    <% if block.compilation_error.present? %>
      <details class="mt-2">
        <summary class="cursor-pointer text-xs hover:underline">Show error details</summary>
        <pre class="mt-2 text-xs bg-gray-900 text-red-400 p-2 rounded overflow-auto max-h-40"><%= block.compilation_error %></pre>
      </details>
    <% end %>
  </div>
<% else %>
  <div class="text-gray-500 bg-gray-50 p-2 rounded text-center">
    Not compiled yet
  </div>
<% end %>
```

### 4. Form Update

#### `app/views/author/blocks/_form.html.erb`
Add Mlx42Block to type dropdown:

```erb
<option value="Mlx42Block">🎮 MLX42 Graphics</option>
```

And add initial form fields:
```erb
<% when "Mlx42Block" %>
  <textarea name="block[text]"
            placeholder="void user_main(int argc, char **argv) {
  extern mlx_t *mlx;
  // Your MLX42 code here
}"
            rows="10"
            class="w-full font-mono text-sm bg-gray-900 text-gray-100 p-4 rounded"></textarea>
```

### 5. Stimulus Controllers

#### A. `app/javascript/controllers/mlx42_preview_controller.js`
**Purpose**: Toggles between content and canvas views

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentView", "canvasView", "toggleButton", "captureButton"]

  connect() {
    this.showingCanvas = false
  }

  toggleView() {
    this.showingCanvas = !this.showingCanvas

    if (this.showingCanvas) {
      // Show canvas, hide content
      this.contentViewTarget.style.display = "none"
      this.canvasViewTarget.style.display = "block"
      this.toggleButtonTarget.textContent = "📄 Show Content"

      // Show capture button if canvas is available
      if (this.hasCaptureButtonTarget) {
        this.captureButtonTarget.style.display = "block"
      }
    } else {
      // Show content, hide canvas
      this.contentViewTarget.style.display = "block"
      this.canvasViewTarget.style.display = "none"
      this.toggleButtonTarget.textContent = "📺 Show Canvas"

      // Hide capture button
      if (this.hasCaptureButtonTarget) {
        this.captureButtonTarget.style.display = "none"
      }
    }
  }
}
```

#### B. `app/javascript/controllers/mlx42_compiler_controller.js`
**Purpose**: Handles compilation requests

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async compile(event) {
    const blockId = event.currentTarget.dataset.blockId
    const button = event.currentTarget
    const documentId = window.location.pathname.split("/")[3] // Extract from URL

    button.disabled = true
    button.innerHTML = '<span class="animate-spin inline-block">⏳</span> Compiling...'

    try {
      const response = await fetch(`/author/documents/${documentId}/blocks/${blockId}/compile_mlx42`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.status === "queued") {
        button.innerHTML = '🔨 Compile'
        // Job queued, status will update via Turbo Stream
      } else {
        throw new Error(data.error || "Compilation failed")
      }
    } catch (error) {
      console.error("Compilation error:", error)
      button.innerHTML = '🔨 Compile'
      alert(`Compilation error: ${error.message}`)
    } finally {
      button.disabled = false
    }
  }
}
```

#### C. `app/javascript/controllers/mlx42_runner_controller.js`
**Purpose**: Loads and runs WASM, handles mouse capture

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "console", "loader", "loadProgress", "captureIndicator"]
  static values = {
    blockId: Number,
    jsUrl: String,
    wasmUrl: String,
    dataUrl: String
  }

  connect() {
    this.isCapturing = false
    this.loadWasm()
  }

  disconnect() {
    this.releasePointer()
  }

  async loadWasm() {
    const canvas = this.canvasTarget
    const consoleEl = this.consoleTarget

    // Setup Module for Emscripten
    window.Module = {
      canvas: canvas,
      print: (...args) => {
        const text = args.join(" ")
        console.log(text)
        if (consoleEl) {
          consoleEl.value += text + "\n"
          consoleEl.scrollTop = consoleEl.scrollHeight
        }
      },
      setStatus: (text) => {
        if (this.hasLoadProgressTarget) {
          this.loadProgressTarget.textContent = text
        }
      },
      monitorRunDependencies: (left) => {
        if (left === 0) {
          this.hideLoader()
        }
      },
      totalDependencies: 0
    }

    // Load the JS file
    const script = document.createElement("script")
    script.async = true
    script.src = this.jsUrlValue
    script.onload = () => {
      console.log("MLX42 WASM loaded successfully")
    }
    script.onerror = () => {
      this.showError("Failed to load WebAssembly module")
    }

    document.body.appendChild(script)
  }

  toggleCapture() {
    if (this.isCapturing) {
      this.releasePointer()
    } else {
      this.requestPointer()
    }
  }

  requestPointer() {
    this.canvasTarget.requestPointerLock()
    this.isCapturing = true
    if (this.hasCaptureIndicatorTarget) {
      this.captureIndicatorTarget.style.display = "block"
    }
  }

  releasePointer() {
    if (document.pointerLockElement === this.canvasTarget) {
      document.exitPointerLock()
    }
    this.isCapturing = false
    if (this.hasCaptureIndicatorTarget) {
      this.captureIndicatorTarget.style.display = "none"
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = "none"
    }
  }

  showError(message) {
    if (this.hasLoaderTarget) {
      this.loaderTarget.innerHTML = `
        <div class="text-center">
          <div class="text-red-600 text-4xl mb-2">⚠️</div>
          <p class="font-medium text-red-600">Error</p>
          <p class="text-sm text-gray-600 mt-1">${message}</p>
        </div>
      `
    }
  }
}
```

---

## Environment Setup

### Required System Dependencies
- **emcc** (Emscripten compiler)
- **MLX42** library compiled for web
  - Set `MLX42_LIB_PATH` env variable or use default: `MLX42/build_web/libmlx42_web.a`

### Installation
```bash
# Install Emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh

# Build MLX42 for web
git clone https://github.com/codam-coding-college/MLX42.git
cd MLX42
mkdir build_web && cd build_web
emcmake cmake ..
emmake make
```

---

## User Documentation

### How to Use MLX42 Blocks

**Entry Point:**
Your code must define:
```c
void user_main(int argc, char **argv) {
  // Your code here
}
```

**Available Globals:**
```c
extern mlx_t *mlx;  // Pre-initialized MLX instance
#define WIDTH 800   // Canvas width
#define HEIGHT 600  // Canvas height
```

**Example:**
```c
#include <MLX42/MLX42.h>

extern mlx_t *mlx;
static mlx_image_t *image;

static void my_hook(void *param) {
  // Update logic
}

void user_main(int argc, char **argv) {
  image = mlx_new_image(mlx, 128, 128);
  mlx_image_to_window(mlx, image, 0, 0);
  mlx_loop_hook(mlx, my_hook, NULL);
}
```

**Using Assets:**
```c
// Reference uploaded files by path
mlx_texture_t *tex = mlx_load_png("assets/texture.png");
```

**Controls:**
- 📺 **Show Canvas** - View running program
- 📄 **Show Content** - View code and assets
- 🖱️ **Capture Mouse** - Enable mouse input for canvas
- 🔨 **Compile** - Build your code

---

## Testing Checklist

- [ ] Can create Mlx42Block
- [ ] Can toggle between content/canvas views
- [ ] Can upload assets and copy paths
- [ ] Compile button works
- [ ] Compilation shows queued/compiling/success states
- [ ] WASM loads and shows canvas
- [ ] Console output displays
- [ ] Mouse capture works (shows indicator)
- [ ] ESC releases mouse capture
- [ ] Loading spinner shows/hides
- [ ] Compilation errors display
- [ ] Works in public view
- [ ] Multiple blocks on same page work

---

## Future Enhancements

1. **Syntax Highlighting** - CodeMirror/Monaco for C
2. **Canvas Size Controls** - Adjustable WIDTH/HEIGHT
3. **Full Screen Mode** - Expand canvas
4. **Performance Metrics** - FPS, memory
5. **Shared Headers** - Common includes
6. **Auto-recompile** - On code change
