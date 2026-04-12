import { Controller } from "@hotwired/stimulus"

// arcade_bridge_controller
//
// Installs `window.Arcade` before the MLX42 wasm module starts running, so
// that the C SDK in vendor/arcade_sdk/arcade.c can call into it via EM_JS.
// Handles:
//   - starting a PlaySession on connect (mint server-side token)
//   - submitting scores with the session token
//   - deep-merging save state patches server-side
//   - preloading save state into a sync-readable cache (loadState())
//   - marking completion
//   - closing the session on disconnect / beforeunload
//
// This controller is mounted on the wrapper element around the mlx42
// canvas when the game is rendered inside the arcade layout — it does
// nothing on blog pages, so Mlx42Block continues to work as before.
export default class extends Controller {
  static values = {
    gameSlug: String,
    csrfToken: String
  }

  connect() {
    this.stateCache = null
    this.stateReady = false
    this.sessionId = null
    this.sessionToken = null
    this.completed = false

    this.installBridge()
    this.startSession()
    this.preloadState()

    this.boundBeforeUnload = this.closeSession.bind(this)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.boundBeforeUnload)
    this.closeSession()
    delete window.Arcade
  }

  // ------------------------------------------------------------------
  // window.Arcade — the JS side of the C SDK
  // ------------------------------------------------------------------
  installBridge() {
    const bridge = {
      submitScore: (value, metaJson) => this.submitScore(value, metaJson),
      saveState:   (patchJson)        => this.saveState(patchJson),
      loadState:   ()                 => this.stateCache,  // sync cached read
      stateReady:  false,
      event:       (name, payload)    => this.event(name, payload),
      markCompleted: ()               => { this.completed = true }
    }
    window.Arcade = bridge
  }

  // ------------------------------------------------------------------
  // sessions
  // ------------------------------------------------------------------
  async startSession() {
    try {
      const res  = await this.post(`/arcade/games/${this.gameSlugValue}/play_sessions`)
      const data = await res.json()
      this.sessionId    = data.session_id
      this.sessionToken = data.token
      this.scoring      = data.scoring
    } catch (e) {
      console.warn("[arcade] could not start session", e)
    }
  }

  async closeSession() {
    if (!this.sessionId) return

    // Use the dedicated POST /close endpoint (sendBeacon can only POST).
    const url  = `/arcade/games/${this.gameSlugValue}/play_sessions/${this.sessionId}/close`
    const body = JSON.stringify({ completed: this.completed })

    try {
      if (navigator.sendBeacon) {
        const blob = new Blob([body], { type: "application/json" })
        navigator.sendBeacon(url, blob)
      } else {
        await fetch(url, { method: "POST", headers: this.headers(), body, keepalive: true })
      }
    } catch (_) { /* best effort */ }

    this.sessionId = null
  }

  // ------------------------------------------------------------------
  // scores
  // ------------------------------------------------------------------
  async submitScore(value, metaJson) {
    if (!this.sessionToken) {
      console.warn("[arcade] submitScore before session ready; dropping")
      return
    }

    let meta = {}
    if (metaJson) {
      try { meta = JSON.parse(metaJson) } catch (_) { meta = {} }
    }

    try {
      await this.post(`/arcade/games/${this.gameSlugValue}/scores`, {
        value,
        meta,
        session_token: this.sessionToken
      })
    } catch (e) {
      console.warn("[arcade] submitScore failed", e)
    }
  }

  // ------------------------------------------------------------------
  // state
  // ------------------------------------------------------------------
  async preloadState() {
    try {
      const res  = await fetch(`/arcade/games/${this.gameSlugValue}/state`, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      const data = await res.json()
      this.stateCache = Object.keys(data.data || {}).length
        ? JSON.stringify(data.data)
        : null
    } catch (_) {
      this.stateCache = null
    } finally {
      this.stateReady = true
      if (window.Arcade) window.Arcade.stateReady = true
    }
  }

  async saveState(patchJson) {
    let patch = {}
    try { patch = JSON.parse(patchJson) } catch (_) { return }

    try {
      const res = await fetch(`/arcade/games/${this.gameSlugValue}/state`, {
        method: "PUT",
        headers: this.headers(),
        credentials: "same-origin",
        body: JSON.stringify(patch)
      })
      const data = await res.json()
      if (data.data) this.stateCache = JSON.stringify(data.data)
    } catch (e) {
      console.warn("[arcade] saveState failed", e)
    }
  }

  // ------------------------------------------------------------------
  // events (fire-and-forget analytics)
  // ------------------------------------------------------------------
  async event(_name, _payloadJson) {
    // Placeholder: will POST to /events in a later slice. For now we just
    // no-op so games that call arcade_event() don't break. Keeping this
    // stub here so the SDK surface stays stable.
  }

  // ------------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------------
  headers() {
    return {
      "Content-Type": "application/json",
      "Accept":       "application/json",
      "X-CSRF-Token": this.csrfTokenValue
    }
  }

  async post(url, body = {}) {
    return fetch(url, {
      method:      "POST",
      headers:     this.headers(),
      credentials: "same-origin",
      body:        JSON.stringify(body)
    })
  }
}
