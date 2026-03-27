# Walkie-Talkie Mode

Walkie-talkie mode is a per-chat setting that streamlines voice messaging for hands-free use. When enabled, voice recordings send immediately without a preview step, and incoming voice messages play automatically.

## Enabling

1. Open a chat (1-on-1 or group)
2. Tap the three-dot overflow menu
3. Under "More options", tap **Enable walkie-talkie**

The setting persists across app restarts. To disable, repeat the steps and tap **Disable walkie-talkie**.

## What changes in walkie-talkie mode

### Simplified input bar

- Emoji, camera, and thread identicon buttons are hidden
- Text input and send button remain (you can still type and send text)
- Two new buttons appear next to the send button:
  - **Keyboard toggle** (keyboard icon) — controls whether the keyboard stays visible after recording
  - **Overlay toggle** (toggle switch icon) — shows/hides the large record button overlay

### Large overlay record button

Tap the toggle switch icon to show a large circular microphone button overlaying the chat area. This button is designed to be easy to tap while walking.

- **Tap once** to start recording (icon changes to a stop square, timer appears)
- **Tap again** to stop recording and send immediately
- **X button** (top-right) dismisses the overlay and cancels any active recording

The button is positioned in the lower portion of the screen so it remains accessible when the keyboard is visible.

### Auto-send

Voice recordings sent via either the regular record button or the large overlay button are sent immediately when recording stops. There is no preview/confirmation step.

### Auto-play incoming voice messages

When you are viewing a chat with walkie-talkie mode enabled:

- New incoming voice messages play automatically
- Multiple voice messages play sequentially (first finishes, then the next starts)
- Messages that were already in the chat when you opened it do not auto-play
- Playback stops automatically when you start a new recording

### Keyboard toggle

The keyboard icon in the input bar controls keyboard behavior:

- **Dimmed** (default) — keyboard hides after recording via the overlay button
- **Bright** (active) — keyboard stays visible after recording; tapping the toggle also shows/hides the keyboard

## Technical details

- Stored as a JSON attribute (`walkie_talkie`) on the Conversation entity
- No database migration required
- Works for both single chats (MODE_SINGLE) and group chats (MODE_MULTI)
