/*
 * arcade.c — Arcade C SDK implementation.
 *
 * All the bridging happens via EM_ASM/EM_JS: each C function delegates to
 * `window.Arcade.*` on the JS side. The runner (see the
 * arcade_bridge_controller Stimulus controller) installs that object
 * before the wasm module starts running, so by the time user_main() is
 * called these functions are safe to call.
 */

#include "arcade.h"

#include <emscripten.h>
#include <stdlib.h>
#include <string.h>

/* ---------- score submission ---------- */

EM_JS(void, js_arcade_submit_score, (double value, const char *meta_json), {
    if (!window.Arcade || !window.Arcade.submitScore) return;
    const meta = meta_json ? UTF8ToString(meta_json) : null;
    window.Arcade.submitScore(value, meta);
});

void arcade_submit_score(long long value) {
    js_arcade_submit_score((double)value, NULL);
}

void arcade_submit_score_with_meta(long long value, const char *meta_json) {
    js_arcade_submit_score((double)value, meta_json);
}

/* ---------- state save / load ---------- */

EM_JS(void, js_arcade_save_state, (const char *patch_json), {
    if (!window.Arcade || !window.Arcade.saveState) return;
    window.Arcade.saveState(UTF8ToString(patch_json));
});

void arcade_save_state(const char *patch_json) {
    if (!patch_json) return;
    js_arcade_save_state(patch_json);
}

/*
 * Returns a malloc'd copy of the current cached state JSON (or NULL).
 * We return malloc'd memory (not an EM_JS string) so the caller can free()
 * it the normal way.
 */
EM_JS(char *, js_arcade_load_state_raw, (void), {
    if (!window.Arcade || !window.Arcade.loadState) return 0;
    const s = window.Arcade.loadState();
    if (s == null) return 0;
    const len = lengthBytesUTF8(s) + 1;
    const buf = _malloc(len);
    stringToUTF8(s, buf, len);
    return buf;
});

char *arcade_load_state(void) {
    return js_arcade_load_state_raw();
}

EM_JS(int, js_arcade_state_ready, (void), {
    return (window.Arcade && window.Arcade.stateReady) ? 1 : 0;
});

int arcade_state_ready(void) {
    return js_arcade_state_ready();
}

/* ---------- events ---------- */

EM_JS(void, js_arcade_event, (const char *name, const char *payload_json), {
    if (!window.Arcade || !window.Arcade.event) return;
    const n = name ? UTF8ToString(name) : "";
    const p = payload_json ? UTF8ToString(payload_json) : null;
    window.Arcade.event(n, p);
});

void arcade_event(const char *name, const char *payload_json) {
    if (!name) return;
    js_arcade_event(name, payload_json);
}

/* ---------- session completion ---------- */

EM_JS(void, js_arcade_mark_completed, (void), {
    if (!window.Arcade || !window.Arcade.markCompleted) return;
    window.Arcade.markCompleted();
});

void arcade_mark_completed(void) {
    js_arcade_mark_completed();
}
