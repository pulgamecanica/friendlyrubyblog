/*
 * arcade.h — Arcade C SDK for MLX42 games submitted to friendlyrubyblog.
 *
 * This header is auto-included and arcade.c is auto-linked by the server
 * compiler when your MLX42 block is owned by a Game. You do NOT need to
 * ship these files yourself — just #include <arcade.h> in your code.
 *
 * All functions are non-blocking and best-effort: they post to the Rails
 * backend via fetch() on the JS side. If the network is down or the page
 * is closing, the call returns immediately; no error is surfaced to C.
 *
 * Example:
 *
 *   #include <arcade.h>
 *
 *   void on_level_complete(int level, int time_ms) {
 *     arcade_submit_score(time_ms);
 *     arcade_save_state("{\"level\":4,\"best_ms\":48210}");
 *     arcade_event("level_complete", "{\"level\":4}");
 *   }
 */

#ifndef ARCADE_H
#define ARCADE_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Submit a numeric score for the current play session.
 * The score is validated server-side against the game's scoring config
 * (direction, min, max, monotonic). Call this as often as you want; the
 * server keeps the best-per-session for leaderboards.
 */
void arcade_submit_score(long long value);

/*
 * Submit a score with JSON metadata (level reached, seed, time_ms, ...).
 * `meta_json` MUST be a valid JSON object as a C string, or NULL.
 */
void arcade_submit_score_with_meta(long long value, const char *meta_json);

/*
 * Save arbitrary JSON state for the current player + current game.
 * The server deep-merges this into any existing state row, so you can
 * patch individual fields without sending the whole blob each time.
 *
 * `patch_json` MUST be a valid JSON object as a C string.
 */
void arcade_save_state(const char *patch_json);

/*
 * Load the current player's saved state for this game.
 *
 * Returns a heap-allocated JSON string the CALLER must free(), or NULL if
 * there is no saved state yet (or if the load hasn't arrived yet — see
 * arcade_state_ready()).
 *
 * Because fetch() is async on the JS side, the first call after page load
 * may return NULL while the request is in flight. Poll arcade_state_ready()
 * or call arcade_load_state() again on the next frame.
 */
char *arcade_load_state(void);

/*
 * Non-zero once the initial state load has completed (success OR "no
 * state"). Use this to gate your game intro while waiting for save data.
 */
int arcade_state_ready(void);

/*
 * Report a named gameplay event. Used for analytics and for the player
 * dashboard timeline. `payload_json` MUST be a valid JSON object or NULL.
 */
void arcade_event(const char *name, const char *payload_json);

/*
 * Mark the current play session as completed (e.g. the player reached the
 * end of the game). Affects the "completion rate" stat on the dashboard.
 */
void arcade_mark_completed(void);

#ifdef __cplusplus
}
#endif

#endif /* ARCADE_H */
