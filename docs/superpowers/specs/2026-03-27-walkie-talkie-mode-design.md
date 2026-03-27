# Walkie-Talkie Mode - Design Spec

## Context

Users want a hands-free, walk-friendly way to exchange voice messages in a conversation. Currently, recording a voice message requires: tap record, tap share, tap send. Playing incoming voice messages requires manually pressing play. This is cumbersome when moving around. Walkie-talkie mode streamlines voice messaging per-chat: recordings auto-send on stop, incoming voice messages auto-play, and a large overlay button makes recording easy while on the move.

## Requirements

1. **Per-chat toggle**: Enable/disable walkie-talkie mode per conversation (1-on-1 and group)
2. **Persisted**: Setting survives app restart
3. **Auto-send on record stop**: When recording finishes, send immediately (no preview step)
4. **Auto-play incoming voice**: When viewing the chat, incoming voice messages play automatically
5. **Simplified input bar**: Hide emoji, attachment, and camera buttons; keep text input and record button
6. **Large overlay record button**: Toggled via a small walkie-talkie icon next to the record button; overlays the chat center for easy tap-while-walking
7. **Works for both 1-on-1 and MUC conversations**

## Architecture

### 1. Data Storage — `Conversation.java`

Add attribute constant alongside existing ones (line ~211):

```java
public static final String ATTRIBUTE_WALKIE_TALKIE = "walkie_talkie";
```

Add convenience method:

```java
public boolean isWalkieTalkieMode() {
    return getBooleanAttribute(ATTRIBUTE_WALKIE_TALKIE, false);
}
```

**No database migration needed** — uses existing JSON `attributes` column.

### 2. Menu Toggle — Overflow Menu

**`src/main/res/menu/fragment_conversation.xml`**: Add `action_toggle_walkie_talkie` item in the "More options" submenu, after `action_toggle_pinned` (~line 153):

```xml
<item
    android:id="@+id/action_toggle_walkie_talkie"
    android:orderInCategory="73"
    android:title="@string/enable_walkie_talkie"
    app:showAsAction="never" />
```

**`src/main/res/values/strings.xml`**: Add strings:

```xml
<string name="enable_walkie_talkie">Enable walkie-talkie</string>
<string name="disable_walkie_talkie">Disable walkie-talkie</string>
```

**`ConversationFragment.java`**: Follow the `togglePinned()` pattern:

- In `onCreateOptionsMenu` (~line 1848): Find `action_toggle_walkie_talkie`, set title based on `conversation.isWalkieTalkieMode()`
- In `onOptionsItemSelected`: Call `toggleWalkieTalkie()`:
  ```java
  private void toggleWalkieTalkie() {
      boolean current = conversation.isWalkieTalkieMode();
      conversation.setAttribute(Conversation.ATTRIBUTE_WALKIE_TALKIE, !current);
      activity.xmppConnectionService.updateConversation(conversation);
      activity.invalidateOptionsMenu();
      updateWalkieTalkieUI();
  }
  ```

### 3. Simplified Input Bar

**`ConversationFragment.java`** — add method `updateWalkieTalkieUI()`:

When walkie-talkie mode is ON:
- Hide `binding.emojiButton` (id: `emojiButton`) — emoji toggle
- Hide `binding.keyboardButton` (id: `keyboardButton`) — keyboard toggle
- Hide `binding.takePictureButton` (id: `takePictureButton`) — camera button
- Show a small walkie-talkie icon button next to the record button
- Keep `binding.textinput` visible
- Keep `binding.textSendButton` visible (users can still send text)
- Keep `binding.recordVoiceButton` visible

When OFF:
- Restore all buttons to normal visibility
- Hide walkie-talkie icon

Call `updateWalkieTalkieUI()` from:
- `toggleWalkieTalkie()`
- Fragment initialization / `refresh()` when conversation loads

**`src/main/res/layout/fragment_conversation.xml`**: Add a small ImageButton/MaterialButton for the walkie-talkie toggle icon in the input bar area, initially `GONE`.

### 4. Large Overlay Record Button

**`src/main/res/layout/fragment_conversation.xml`**: Add an overlay `FrameLayout` containing:
- A large circular `MaterialButton` (walkie-talkie record button) — e.g., 120dp x 120dp, centered
- A small "X" dismiss `ImageButton` in the corner
- Initially `GONE`

```xml
<FrameLayout
    android:id="@+id/walkie_talkie_overlay"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:visibility="gone"
    android:clickable="true"
    android:focusable="true">

    <com.google.android.material.button.MaterialButton
        android:id="@+id/walkie_talkie_record_button"
        style="@style/Widget.Material3.Button.IconButton.Filled.Tonal"
        android:layout_width="120dp"
        android:layout_height="120dp"
        android:layout_gravity="center"
        app:icon="@drawable/ic_mic_24dp"
        app:iconSize="48dp"
        app:cornerRadius="60dp" />

    <ImageButton
        android:id="@+id/walkie_talkie_dismiss"
        android:layout_width="40dp"
        android:layout_height="40dp"
        android:layout_gravity="top|end"
        android:layout_margin="16dp"
        android:src="@drawable/ic_clear_24dp"
        android:background="?selectableItemBackgroundBorderless"
        android:contentDescription="@string/close" />
</FrameLayout>
```

**`ConversationFragment.java`** — overlay logic:

- **Small WT icon tap**: Toggle `binding.walkieTalkieOverlay` visibility (VISIBLE/GONE)
- **Large button tap (not recording)**: Start recording (reuse `startRecording()` logic), change button appearance to red/recording state, show timer
- **Large button tap (recording)**: Stop recording + auto-send (see section 5)
- **X button tap**: Hide overlay, cancel any active recording

### 5. Auto-Send on Record Stop

**`ConversationFragment.java` — `Finisher.run()`** (~line 5926):

Currently the `Finisher` thread adds the output file to `mediaPreviewAdapter` for preview. Modify:

```java
// Inside the runOnUiThread callback (both opus and aac branches):
if (conversation.isWalkieTalkieMode()) {
    // Auto-send: skip preview, attach directly
    attachFileToConversation(conversation, Uri.fromFile(outputFile), mimeType, null);
} else {
    // Normal flow: add to preview
    mediaPreviewAdapter.addMediaPreviews(
        Attachment.of(activity, Uri.fromFile(outputFile), Attachment.Type.RECORDING));
    toggleInputMethod();
}
binding.recordingVoiceActivity.setVisibility(View.GONE);
```

This applies to both the regular bottom record button AND the large overlay button (both call into the same `stopRecording(true)` -> `Finisher` path).

### 6. Auto-Play Incoming Voice Messages

**`ConversationFragment.java`**:

Add field:
```java
private String lastAutoPlayedMessageUuid = null;
```

In `refresh(boolean notifyConversationRead)`, after `messageListAdapter.notifyDataSetChanged()` (~line 4830):

```java
if (conversation.isWalkieTalkieMode()) {
    autoPlayLatestVoiceMessage();
}
```

```java
private void autoPlayLatestVoiceMessage() {
    if (messageList.isEmpty()) return;
    Message lastMessage = messageList.get(messageList.size() - 1);

    if (lastMessage.getStatus() == Message.STATUS_RECEIVED
            && lastMessage.getFileParams() != null
            && lastMessage.getFileParams().runtime > 0
            && lastMessage.getTransferable() == null  // download complete
            && !lastMessage.getUuid().equals(lastAutoPlayedMessageUuid)) {

        File file = activity.xmppConnectionService.getFileBackend().getFile(lastMessage);
        if (file.exists()) {
            lastAutoPlayedMessageUuid = lastMessage.getUuid();
            messageListAdapter.getAudioPlayer().autoPlay(lastMessage);
        }
    }
}
```

**`AudioPlayer.java`** — add public method:

```java
public void autoPlay(Message message) {
    synchronized (LOCK) {
        if (player != null) {
            stopCurrent();
        }
        AudioPlayer.player = new MediaPlayer();
        try {
            AudioPlayer.currentlyPlayingMessage = message;
            AudioPlayer.player.setAudioStreamType(AudioManager.STREAM_MUSIC);
            AudioPlayer.player.setDataSource(
                messageAdapter.getFileBackend().getFile(message).getAbsolutePath());
            AudioPlayer.player.setOnCompletionListener(this);
            AudioPlayer.player.prepare();
            AudioPlayer.player.start();
            messageAdapter.flagScreenOn();
            // Update UI for any visible audio player view
            for (RelativeLayout layout : audioPlayerLayouts) {
                Message tag = (Message) layout.getTag();
                if (tag != null && tag.getUuid().equals(message.getUuid())) {
                    ViewHolder vh = ViewHolder.get(layout);
                    vh.playPause.setIconResource(R.drawable.rounded_pause_36);
                    vh.progress.setEnabled(true);
                    stopRefresher(true);
                    break;
                }
            }
        } catch (Exception e) {
            AudioPlayer.currentlyPlayingMessage = null;
        }
    }
}
```

**`MessageAdapter.java`** — expose audio player:

```java
public AudioPlayer getAudioPlayer() {
    return audioPlayer;
}
```

## Files to Modify

| File | Changes |
|------|---------|
| `src/main/java/eu/siacs/conversations/entities/Conversation.java` | Add `ATTRIBUTE_WALKIE_TALKIE` constant + `isWalkieTalkieMode()` method |
| `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java` | Menu toggle, `updateWalkieTalkieUI()`, overlay button logic, auto-send in `Finisher`, auto-play in `refresh()` |
| `src/main/java/eu/siacs/conversations/ui/service/AudioPlayer.java` | Add `autoPlay(Message)` method |
| `src/main/java/eu/siacs/conversations/ui/adapter/MessageAdapter.java` | Add `getAudioPlayer()` getter |
| `src/main/res/menu/fragment_conversation.xml` | Add `action_toggle_walkie_talkie` menu item |
| `src/main/res/layout/fragment_conversation.xml` | Add walkie-talkie overlay layout + small WT icon button in input bar |
| `src/main/res/values/strings.xml` | Add string resources for walkie-talkie labels |

## Verification

1. **Toggle persistence**: Enable walkie-talkie mode, restart app, verify it's still enabled
2. **Simplified input bar**: Verify emoji/attachment/camera buttons hidden in WT mode, visible when off
3. **Large overlay**: Tap WT icon, verify overlay appears centered. Tap X, verify it dismisses
4. **Record via overlay**: Tap large button to record, tap again to stop. Verify message sends immediately (no preview)
5. **Record via small button**: Use regular record button in WT mode. Verify auto-send (no preview)
6. **Auto-play**: Receive a voice message while viewing the chat in WT mode. Verify it plays automatically
7. **No double-play**: Verify the same message doesn't replay on each refresh
8. **Normal mode**: Disable WT mode. Verify everything works exactly as before (preview step, manual play, all buttons visible)
9. **Both chat types**: Test in 1-on-1 and group conversations
