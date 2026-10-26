#include QMK_KEYBOARD_H
#include "version.h"
#include "raw_hid.h"

#define DUAL_FUNC_0 LT(15, KC_F13)

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT_ergodox_pretty(
    KC_ESCAPE,      KC_1,           KC_2,           KC_3,           KC_4,           KC_5,           KC_LEFT,                                        KC_RIGHT,       KC_6,           KC_7,           KC_8,           KC_9,           KC_0,           DUAL_FUNC_0,
    KC_TAB,         KC_Q,           KC_D,           KC_R,           KC_W,           KC_B,           TG(1),                                          TG(1),          KC_J,           KC_F,           KC_U,           KC_P,           KC_SCLN,        LT(2, KC_BSLS),
    KC_BSPC,        KC_A,           KC_S,           KC_H,           KC_T,           KC_G,                                                                           KC_Y,           KC_N,           KC_E,           KC_O,           KC_I,           KC_QUOTE,
    KC_LEFT_SHIFT,  KC_Z,           KC_X,           KC_M,           KC_C,           KC_V,           KC_HYPR,                                        KC_MEH,         KC_K,           KC_L,           KC_COMMA,       KC_DOT,         KC_SLASH,       KC_RIGHT_SHIFT,
    MT(MOD_LCTL, KC_GRAVE),MT(MOD_LALT, KC_QUOTE),KC_LEFT_GUI,    KC_LEFT,        KC_RIGHT,                                                                                                       KC_UP,          KC_DOWN,        KC_LBRC,        KC_RBRC,        MT(MOD_RCTL, KC_EQUAL),
                                                                                                    KC_APPLICATION, KC_PSCR,        KC_LEFT_ALT,    KC_ESCAPE,
                                                                                                                    KC_HOME,        KC_PAGE_UP,
                                                                                    KC_SPACE,       KC_DELETE,      KC_END,         KC_PGDN,        CW_TOGG,        KC_ENTER
  ),
  [1] = LAYOUT_ergodox_pretty(
    KC_ESCAPE,      KC_F1,          KC_F2,          KC_F3,          KC_F4,          KC_F5,          KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_F6,          KC_F7,          KC_F8,          KC_F9,          KC_F10,         KC_F11,
    KC_TRANSPARENT, KC_EXLM,        KC_AT,          KC_LCBR,        KC_RCBR,        KC_PIPE,        KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_UP,          KC_7,           KC_8,           KC_9,           KC_ASTR,        KC_F12,
    KC_TRANSPARENT, KC_HASH,        KC_DLR,         KC_LPRN,        KC_RPRN,        KC_GRAVE,                                                                       KC_DOWN,        KC_4,           KC_5,           KC_6,           KC_PLUS,        KC_TRANSPARENT,
    KC_TRANSPARENT, KC_PERC,        KC_CIRC,        KC_LBRC,        KC_RBRC,        KC_TILD,        KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_AMPR,        KC_1,           KC_2,           KC_3,           KC_BSLS,        KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_DOT,         KC_0,           KC_EQUAL,       KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
  [2] = LAYOUT_ergodox_pretty(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, QK_BOOT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, MS_UP,       KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, MS_LEFT,     MS_DOWN,     MS_RGHT,    KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_MEDIA_PLAY_PAUSE,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_MEDIA_PREV_TRACK,KC_MEDIA_NEXT_TRACK,KC_TRANSPARENT, KC_TRANSPARENT,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, MS_BTN1,     MS_BTN2,                                                                                                     KC_AUDIO_VOL_UP,KC_AUDIO_VOL_DOWN,KC_AUDIO_MUTE,  KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_WWW_BACK
  ),
  [3] = LAYOUT_ergodox_pretty(
    KC_ESCAPE,      KC_1,           KC_2,           KC_3,           KC_4,           KC_5,           KC_BSLS,                                        KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, TO(0),
    KC_TAB,         KC_Q,           KC_W,           KC_E,           KC_R,           KC_T,           KC_LBRC,                                        KC_TRANSPARENT, KC_Y,           KC_U,           KC_I,           KC_O,           KC_P,           KC_TRANSPARENT,
    KC_TRANSPARENT, KC_A,           KC_S,           KC_D,           KC_F,           KC_G,                                                                           KC_H,           KC_J,           KC_K,           KC_L,           KC_M,           KC_TRANSPARENT,
    KC_TRANSPARENT, KC_Z,           KC_X,           KC_C,           KC_V,           KC_B,           KC_RBRC,                                        KC_TRANSPARENT, KC_N,           KC_COMMA,       KC_SCLN,        KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
    KC_LEFT_CTRL,   KC_LEFT_ALT,    KC_TRANSPARENT, KC_LEFT,        KC_RIGHT,                                                                                                       KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                                                    KC_TRANSPARENT, KC_TRANSPARENT,
                                                                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
};








bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {

    case DUAL_FUNC_0:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_MINUS);
        } else {
          unregister_code16(KC_MINUS);
        }
      } else {
        if (record->event.pressed) {
          layer_move(3);
        } else {
          layer_move(3);
        }  
      }  
      return false;
  }
  return true;
}

// Live layer for the desktop bar over raw HID (usage page 0xFF60). The host pings with 0x01
// every ~2 s and gets {'L', layer} on each layer change; with no ping for 5 s the board goes
// quiet, because a raw HID write blocks (~10 ms) when nothing is reading. 0x02 unsubscribes.
// Layer numbers only, never keys.
#define LAYER_PING_TIMEOUT_MS 5000
#define RAW_REPORT_SIZE 32 // LUFA raw endpoint; RAW_EPSIZE is not visible to keymaps

static bool     layer_subscribed = false;
static uint32_t layer_ping_timer = 0;

static void send_layer(uint8_t layer) {
  if (!layer_subscribed) return;
  if (timer_elapsed32(layer_ping_timer) >= LAYER_PING_TIMEOUT_MS) {
    layer_subscribed = false;
    return;
  }
  uint8_t report[RAW_REPORT_SIZE] = {'L', layer};
  raw_hid_send(report, sizeof(report));
}

void raw_hid_receive(uint8_t *data, uint8_t length) {
  if (length == 0) return;
  switch (data[0]) {
    case 0x01:
      layer_subscribed = true;
      layer_ping_timer = timer_read32();
      send_layer(get_highest_layer(layer_state | default_layer_state));
      break;
    case 0x02:
      layer_subscribed = false;
      break;
  }
}

layer_state_t layer_state_set_user(layer_state_t state) {
  uint8_t layer = get_highest_layer(state);
  send_layer(layer);
  ergodox_board_led_off();
  ergodox_right_led_1_off();
  ergodox_right_led_2_off();
  ergodox_right_led_3_off();
  switch (layer) {
    case 1:
      ergodox_right_led_1_on();
      break;
    case 2:
      ergodox_right_led_2_on();
      break;
    case 3:
      ergodox_right_led_3_on();
      break;
    case 4:
      ergodox_right_led_1_on();
      ergodox_right_led_2_on();
      break;
    case 5:
      ergodox_right_led_1_on();
      ergodox_right_led_3_on();
      break;
    case 6:
      ergodox_right_led_2_on();
      ergodox_right_led_3_on();
      break;
    case 7:
      ergodox_right_led_1_on();
      ergodox_right_led_2_on();
      ergodox_right_led_3_on();
      break;
    default:
      break;
  }
  return state;
};

