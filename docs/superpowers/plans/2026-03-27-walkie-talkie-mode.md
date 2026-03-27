# Walkie-Talkie Mode Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-conversation walkie-talkie mode that auto-sends voice recordings, auto-plays incoming voice messages, and provides a large overlay record button for hands-free use.

**Architecture:** Follows existing Conversation attribute pattern (JSON attributes column, no DB migration). UI changes are isolated to ConversationFragment and its layout. AudioPlayer gets one new public method for auto-play.

**Tech Stack:** Android (Java), SQLite (existing JSON attributes), Material Design 3 components

**Spec:** `docs/superpowers/specs/2026-03-27-walkie-talkie-mode-design.md`

---

## Chunk 1: Data Model + Menu Toggle

### Task 1: Add walkie-talkie attribute to Conversation entity

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/entities/Conversation.java:211`

- [ ] **Step 1: Add attribute constant**

After line 211 (`ATTRIBUTE_PINNED_ON_TOP`), add:

```java
public static final String ATTRIBUTE_WALKIE_TALKIE = "walkie_talkie";
```

- [ ] **Step 2: Add convenience getter**

After the `alwaysNotify()` method (search for `public boolean alwaysNotify()`), add:

```java
public boolean isWalkieTalkieMode() {
    return getBooleanAttribute(ATTRIBUTE_WALKIE_TALKIE, false);
}
```

- [ ] **Step 3: Commit**

```bash
git add src/main/java/eu/siacs/conversations/entities/Conversation.java
git commit -m "feat(walkie-talkie): add ATTRIBUTE_WALKIE_TALKIE to Conversation entity"
```

---

### Task 2: Add string resources

**Files:**
- Modify: `src/main/res/values/strings.xml`

- [ ] **Step 1: Add walkie-talkie strings**

Find the `disable_notifications` / `enable_notifications` strings area and add nearby:

```xml
<string name="enable_walkie_talkie">Enable walkie-talkie</string>
<string name="disable_walkie_talkie">Disable walkie-talkie</string>
<string name="walkie_talkie_show_overlay">Show walkie-talkie</string>
```

- [ ] **Step 2: Commit**

```bash
git add src/main/res/values/strings.xml
git commit -m "feat(walkie-talkie): add string resources"
```

---

### Task 3: Add menu item to overflow menu

**Files:**
- Modify: `src/main/res/menu/fragment_conversation.xml:153`

- [ ] **Step 1: Add menu item**

After the `action_toggle_pinned` item (line ~153), add:

```xml
            <item
                android:id="@+id/action_toggle_walkie_talkie"
                android:orderInCategory="74"
                android:title="@string/enable_walkie_talkie"
                app:showAsAction="never" />
```

Note: Use `orderInCategory="74"` to place it after pinned (73) and before clear_history (74 — bump that to 75 if needed, or just use 73 since Android sorts stable within same order).

- [ ] **Step 2: Commit**

```bash
git add src/main/res/menu/fragment_conversation.xml
git commit -m "feat(walkie-talkie): add toggle menu item to overflow menu"
```

---

### Task 4: Wire up menu toggle in ConversationFragment

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java`

- [ ] **Step 1: Add menu item reference in onCreateOptionsMenu**

In `onCreateOptionsMenu`, after `menuTogglePinned` is found (line ~1848), add:

```java
final MenuItem menuToggleWalkieTalkie = menu.findItem(R.id.action_toggle_walkie_talkie);
```

Then in the `if (conversation != null)` block, after the pinned title logic (line ~1899), add:

```java
if (conversation.isWalkieTalkieMode()) {
    menuToggleWalkieTalkie.setTitle(R.string.disable_walkie_talkie);
} else {
    menuToggleWalkieTalkie.setTitle(R.string.enable_walkie_talkie);
}
```

- [ ] **Step 2: Handle menu item click in onOptionsItemSelected**

In the `switch` block, after `case R.id.action_toggle_pinned:` (line ~3008), add:

```java
case R.id.action_toggle_walkie_talkie:
    toggleWalkieTalkie();
    break;
```

- [ ] **Step 3: Add toggleWalkieTalkie method**

After the `togglePinned()` method (line ~3176), add:

```java
private void toggleWalkieTalkie() {
    final boolean current = conversation.isWalkieTalkieMode();
    conversation.setAttribute(Conversation.ATTRIBUTE_WALKIE_TALKIE, !current);
    activity.xmppConnectionService.updateConversation(conversation);
    activity.invalidateOptionsMenu();
    updateWalkieTalkieUI();
}
```

- [ ] **Step 4: Add stub updateWalkieTalkieUI method**

```java
private void updateWalkieTalkieUI() {
    if (conversation == null || binding == null) return;
    final boolean walkieTalkie = conversation.isWalkieTalkieMode();
    // UI updates will be added in subsequent tasks
}
```

- [ ] **Step 5: Build and verify**

Run: `./gradlew assembleMonocleschatDebug` (or project-specific build command)
Expected: Builds successfully. Menu toggle appears in overflow menu and persists across app restart.

- [ ] **Step 6: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/ConversationFragment.java
git commit -m "feat(walkie-talkie): wire up menu toggle for walkie-talkie mode"
```

---

## Chunk 2: Simplified Input Bar + Walkie-Talkie Icon

### Task 5: Add walkie-talkie icon drawable

**Files:**
- Create: `src/main/res/drawable/ic_walkie_talkie_24dp.xml`

- [ ] **Step 1: Create the drawable**

Create a simple walkie-talkie / two-way radio vector icon (Material Design style). Use the Material `campaign` or `cell_tower` icon as basis, or create a mic-with-waves icon:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorControlNormal"
    android:autoMirrored="true">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,1C10.34,1 9,2.34 9,4V12C9,13.66 10.34,15 12,15C13.66,15 15,13.66 15,12V4C15,2.34 13.66,1 12,1ZM12,13C11.45,13 11,12.55 11,12V4C11,3.45 11.45,3 12,3C12.55,3 13,3.45 13,4V12C13,12.55 12.55,13 12,13Z" />
    <path
        android:fillColor="@android:color/white"
        android:pathData="M5,12C5,15.53 7.61,18.43 11,18.92V21H9V23H15V21H13V18.92C16.39,18.43 19,15.53 19,12H17C17,14.76 14.76,17 12,17C9.24,17 7,14.76 7,12H5Z" />
    <path
        android:fillColor="@android:color/white"
        android:pathData="M3.5,9.5L1.5,9.5L1.5,12C1.5,14.5 2.5,16.5 4.5,18L6,16.5C4.5,15.5 3.5,13.8 3.5,12L3.5,9.5Z" />
    <path
        android:fillColor="@android:color/white"
        android:pathData="M20.5,9.5L22.5,9.5L22.5,12C22.5,14.5 21.5,16.5 19.5,18L18,16.5C19.5,15.5 20.5,13.8 20.5,12L20.5,9.5Z" />
</vector>
```

This is a microphone with sound waves icon. Alternatively, you can use the existing `ic_mic_24dp` with a different tint, but a distinct icon is better for discoverability.

- [ ] **Step 2: Commit**

```bash
git add src/main/res/drawable/ic_walkie_talkie_24dp.xml
git commit -m "feat(walkie-talkie): add walkie-talkie icon drawable"
```

---

### Task 6: Add walkie-talkie toggle button to input bar layout

**Files:**
- Modify: `src/main/res/layout/fragment_conversation.xml:600-611`

- [ ] **Step 1: Add the small walkie-talkie icon button**

After the `recordVoiceButton` (line ~611) and before `textSendButton` (line ~613), add:

```xml
                            <ImageButton
                                android:id="@+id/walkieTalkieToggleButton"
                                android:layout_width="36dp"
                                android:layout_height="36dp"
                                android:layout_marginEnd="3dp"
                                android:layout_toStartOf="@+id/textSendButton"
                                android:layout_toLeftOf="@+id/textSendButton"
                                android:layout_alignBottom="@+id/textinput_layout_new"
                                android:background="?attr/selectableItemBackgroundBorderless"
                                android:contentDescription="@string/walkie_talkie_show_overlay"
                                android:src="@drawable/ic_walkie_talkie_24dp"
                                android:visibility="gone" />
```

Also update `recordVoiceButton` to be `layout_toStartOf="@+id/walkieTalkieToggleButton"` instead of `layout_toStartOf="@+id/textSendButton"` so it positions correctly when the WT button is visible.

Wait — the current layout has `recordVoiceButton` positioned `layout_toStartOf="@+id/textSendButton"`. When the WT button is inserted between them, we need to adjust the chain:

- `takePictureButton` → `toStartOf` → `recordVoiceButton` (unchanged)
- `recordVoiceButton` → `toStartOf` → `walkieTalkieToggleButton` (change from `textSendButton`)
- `walkieTalkieToggleButton` → `toStartOf` → `textSendButton`
- `textSendButton` → `alignParentEnd` (unchanged)

So modify `recordVoiceButton`'s positioning:

```xml
android:layout_toStartOf="@+id/walkieTalkieToggleButton"
android:layout_toLeftOf="@+id/walkieTalkieToggleButton"
```

- [ ] **Step 2: Commit**

```bash
git add src/main/res/layout/fragment_conversation.xml
git commit -m "feat(walkie-talkie): add WT toggle button to input bar layout"
```

---

### Task 7: Implement simplified input bar logic

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java`

- [ ] **Step 1: Wire up the walkie-talkie toggle button**

In the fragment initialization code (search for `binding.recordVoiceButton` setup, around line ~1982 where `recordVoiceButton` click listener is set), add:

```java
binding.walkieTalkieToggleButton.setOnClickListener(v -> toggleWalkieTalkieOverlay());
```

- [ ] **Step 2: Implement updateWalkieTalkieUI**

Replace the stub `updateWalkieTalkieUI()` method with:

```java
private void updateWalkieTalkieUI() {
    if (conversation == null || binding == null) return;
    final boolean walkieTalkie = conversation.isWalkieTalkieMode();
    binding.emojiButton.setVisibility(walkieTalkie ? View.GONE : View.VISIBLE);
    binding.keyboardButton.setVisibility(walkieTalkie ? View.GONE : View.GONE);
    binding.takePictureButton.setVisibility(walkieTalkie ? View.GONE : View.VISIBLE);
    binding.walkieTalkieToggleButton.setVisibility(walkieTalkie ? View.VISIBLE : View.GONE);
    if (!walkieTalkie && binding.walkieTalkieOverlay.getVisibility() == View.VISIBLE) {
        binding.walkieTalkieOverlay.setVisibility(View.GONE);
    }
}
```

Note: `keyboardButton` is already `GONE` by default (it only shows when emoji picker is open). Setting it GONE in WT mode ensures it stays hidden even if emoji picker state leaks. The non-WT restore sets it to GONE too since it's controlled by emoji toggle logic separately.

- [ ] **Step 3: Add stub toggleWalkieTalkieOverlay method**

```java
private void toggleWalkieTalkieOverlay() {
    if (binding.walkieTalkieOverlay.getVisibility() == View.VISIBLE) {
        binding.walkieTalkieOverlay.setVisibility(View.GONE);
    } else {
        binding.walkieTalkieOverlay.setVisibility(View.VISIBLE);
    }
}
```

- [ ] **Step 4: Call updateWalkieTalkieUI on conversation load**

In `refresh(boolean notifyConversationRead)`, after `updateEditablity()` (line ~4843), add:

```java
updateWalkieTalkieUI();
```

- [ ] **Step 5: Build and verify**

Run: `./gradlew assembleMonocleschatDebug`
Expected: When WT mode is enabled via menu, emoji/camera buttons hide, small WT icon appears. When disabled, everything restores.

- [ ] **Step 6: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/ConversationFragment.java
git commit -m "feat(walkie-talkie): implement simplified input bar and WT icon toggle"
```

---

## Chunk 3: Large Overlay Record Button

### Task 8: Add overlay layout to fragment_conversation.xml

**Files:**
- Modify: `src/main/res/layout/fragment_conversation.xml`

- [ ] **Step 1: Add the overlay FrameLayout**

Inside the `RelativeLayout` (line 34), after the `unread_count_custom_view` (line ~248) and before the `input_area` `LinearLayout` (line ~250), add:

```xml
                <FrameLayout
                    android:id="@+id/walkie_talkie_overlay"
                    android:layout_width="match_parent"
                    android:layout_height="match_parent"
                    android:layout_above="@+id/input_area"
                    android:layout_below="@+id/pinned_message_container"
                    android:layout_alignStart="@+id/messages_view"
                    android:layout_alignEnd="@+id/messages_view"
                    android:visibility="gone"
                    android:elevation="10dp"
                    android:clickable="false"
                    android:focusable="false">

                    <com.google.android.material.button.MaterialButton
                        android:id="@+id/walkie_talkie_record_button"
                        style="@style/Widget.Material3.Button.IconButton.Filled.Tonal"
                        android:layout_width="160dp"
                        android:layout_height="160dp"
                        android:layout_gravity="center"
                        app:icon="@drawable/ic_mic_48dp"
                        app:iconSize="64dp"
                        app:cornerRadius="80dp" />

                    <ImageButton
                        android:id="@+id/walkie_talkie_dismiss"
                        android:layout_width="48dp"
                        android:layout_height="48dp"
                        android:layout_gravity="top|end"
                        android:layout_margin="16dp"
                        android:src="@drawable/ic_clear_24dp"
                        android:background="?selectableItemBackgroundBorderless"
                        android:contentDescription="@string/close" />

                    <TextView
                        android:id="@+id/walkie_talkie_timer"
                        android:layout_width="wrap_content"
                        android:layout_height="wrap_content"
                        android:layout_gravity="center_horizontal"
                        android:layout_marginTop="40dp"
                        android:text=""
                        android:textSize="24sp"
                        android:textStyle="bold"
                        android:typeface="monospace"
                        android:visibility="gone" />
                </FrameLayout>
```

Key layout decisions:
- `layout_above="@+id/input_area"` — overlay floats above input bar
- `layout_below="@+id/pinned_message_container"` — doesn't cover pinned messages
- `elevation="10dp"` — floats above messages list
- `clickable="false"` on the FrameLayout — allows tapping through to messages when not on the button
- 160dp x 160dp button — large enough to hit while walking
- Timer text for showing recording duration

- [ ] **Step 2: Commit**

```bash
git add src/main/res/layout/fragment_conversation.xml
git commit -m "feat(walkie-talkie): add large overlay record button layout"
```

---

### Task 9: Implement overlay record button logic

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java`

- [ ] **Step 1: Add recording state tracking field**

Near the existing `private boolean recording` field (search for `boolean recording`), add:

```java
private boolean walkieTalkieRecording = false;
```

- [ ] **Step 2: Wire up overlay button click listeners**

In the fragment initialization code (near where `recordVoiceButton` listeners are set up, around line ~1982), add:

```java
binding.walkieTalkieRecordButton.setOnClickListener(v -> onWalkieTalkieRecordButtonClick());
binding.walkieTalkieDismiss.setOnClickListener(v -> dismissWalkieTalkieOverlay());
```

- [ ] **Step 3: Implement onWalkieTalkieRecordButtonClick**

```java
private void onWalkieTalkieRecordButtonClick() {
    if (!walkieTalkieRecording) {
        // Start recording — reuse existing permission check and recording logic
        if (!hasPermissions(REQUEST_RECORD_AUDIO, Manifest.permission.RECORD_AUDIO)) {
            return;
        }
        recordVoice();
        walkieTalkieRecording = true;
        binding.walkieTalkieRecordButton.setIconResource(R.drawable.ic_stop_24dp);
        binding.walkieTalkieRecordButton.setIconTintResource(com.google.android.material.R.color.design_default_color_error);
        binding.walkieTalkieTimer.setVisibility(View.VISIBLE);
    } else {
        // Stop recording — triggers auto-send via Finisher
        mHandler.removeCallbacks(mTickExecutor);
        stopRecording(true);
        walkieTalkieRecording = false;
        binding.walkieTalkieRecordButton.setIconResource(R.drawable.ic_mic_48dp);
        binding.walkieTalkieRecordButton.setIconTintResource(android.R.color.white);
        binding.walkieTalkieTimer.setVisibility(View.GONE);
        binding.walkieTalkieTimer.setText("");
        binding.recordingVoiceActivity.setVisibility(View.GONE);
    }
}
```

Note: The `recordVoice()` method already handles starting the recorder. Check if it shows the `recordingVoiceActivity` view — if so, we need to hide it when using the overlay. Look at the `recordVoice()` method: it sets `binding.recordingVoiceActivity.setVisibility(View.VISIBLE)`. In WT overlay mode we should hide that and show our own timer instead. Add a check:

After calling `recordVoice()`, immediately hide the standard recording UI:
```java
if (binding.walkieTalkieOverlay.getVisibility() == View.VISIBLE) {
    binding.recordingVoiceActivity.setVisibility(View.GONE);
}
```

Also need to update the walkie-talkie timer during recording. Add a timer update in the `tick()` method (line ~6036). After the line `this.binding.timer.setText(time);` add:

```java
if (binding.walkieTalkieTimer.getVisibility() == View.VISIBLE) {
    binding.walkieTalkieTimer.setText(time);
}
```

- [ ] **Step 4: Implement dismissWalkieTalkieOverlay**

```java
private void dismissWalkieTalkieOverlay() {
    if (walkieTalkieRecording) {
        mHandler.removeCallbacks(mTickExecutor);
        stopRecording(false); // Cancel, don't save
        walkieTalkieRecording = false;
        binding.walkieTalkieRecordButton.setIconResource(R.drawable.ic_mic_48dp);
        binding.walkieTalkieRecordButton.setIconTintResource(android.R.color.white);
        binding.walkieTalkieTimer.setVisibility(View.GONE);
        binding.walkieTalkieTimer.setText("");
    }
    binding.walkieTalkieOverlay.setVisibility(View.GONE);
}
```

- [ ] **Step 5: Check for ic_stop drawable**

Search for an existing stop icon: `src/main/res/drawable/ic_stop*`. If it doesn't exist, create one:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorControlNormal">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M6,6h12v12H6z" />
</vector>
```

Save as `src/main/res/drawable/ic_stop_24dp.xml`.

- [ ] **Step 6: Build and verify**

Run: `./gradlew assembleMonocleschatDebug`
Expected: WT icon toggles overlay. Large button starts/stops recording. X dismisses. Timer shows during recording.

- [ ] **Step 7: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/ConversationFragment.java
git add src/main/res/drawable/ic_stop_24dp.xml
git commit -m "feat(walkie-talkie): implement overlay record button with start/stop/dismiss"
```

---

## Chunk 4: Auto-Send on Record Stop

### Task 10: Modify Finisher to auto-send in walkie-talkie mode

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java:5926-5984`

- [ ] **Step 1: Modify opus branch in Finisher.run()**

In the `Finisher.run()` method, find the opus branch `activity.runOnUiThread()` callback (line ~5953). Replace:

```java
activity.runOnUiThread(
        () -> {
            activity.setResult(
                    Activity.RESULT_OK, new Intent().setData(Uri.fromFile(outputFile)));
            mediaPreviewAdapter.addMediaPreviews(Attachment.of(activity, Uri.fromFile(outputFile), Attachment.Type.RECORDING));
            toggleInputMethod();
            //attachFileToConversation(conversation, Uri.fromFile(outputFile), "audio/oga;codecs=opus");
            binding.recordingVoiceActivity.setVisibility(View.GONE);
        });
```

With:

```java
activity.runOnUiThread(
        () -> {
            activity.setResult(
                    Activity.RESULT_OK, new Intent().setData(Uri.fromFile(outputFile)));
            if (conversation.isWalkieTalkieMode()) {
                attachFileToConversation(conversation, Uri.fromFile(outputFile), "audio/oga;codecs=opus", null);
            } else {
                mediaPreviewAdapter.addMediaPreviews(Attachment.of(activity, Uri.fromFile(outputFile), Attachment.Type.RECORDING));
                toggleInputMethod();
            }
            binding.recordingVoiceActivity.setVisibility(View.GONE);
        });
```

- [ ] **Step 2: Modify AAC branch in Finisher.run()**

Find the AAC branch `activity.runOnUiThread()` callback (line ~5974). Apply the same pattern:

```java
activity.runOnUiThread(
        () -> {
            activity.setResult(
                    Activity.RESULT_OK, new Intent().setData(Uri.fromFile(outputFile)));
            if (conversation.isWalkieTalkieMode()) {
                attachFileToConversation(conversation, Uri.fromFile(outputFile), "audio/mp4", null);
            } else {
                mediaPreviewAdapter.addMediaPreviews(Attachment.of(activity, Uri.fromFile(outputFile), Attachment.Type.RECORDING));
                toggleInputMethod();
            }
            binding.recordingVoiceActivity.setVisibility(View.GONE);
        });
```

Note: Check if there are additional codec branches (e.g., AMR_WB/3GPP). If so, apply the same pattern there too.

- [ ] **Step 3: Build and verify**

Run: `./gradlew assembleMonocleschatDebug`
Expected: In WT mode, recording via either the small button or large overlay sends immediately with no preview step. In normal mode, preview still appears.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/ConversationFragment.java
git commit -m "feat(walkie-talkie): auto-send voice recordings in walkie-talkie mode"
```

---

## Chunk 5: Auto-Play Incoming Voice Messages

### Task 11: Add autoPlay method to AudioPlayer

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/service/AudioPlayer.java`

- [ ] **Step 1: Add autoPlay method**

After the existing `startStopPending()` method (line ~262), add:

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
            for (final RelativeLayout layout : audioPlayerLayouts) {
                final Message tag = (Message) layout.getTag();
                if (tag != null && tag.getUuid().equals(message.getUuid())) {
                    final ViewHolder vh = ViewHolder.get(layout);
                    vh.playPause.setIconResource(R.drawable.rounded_pause_36);
                    vh.progress.setEnabled(true);
                    stopRefresher(true);
                    break;
                }
            }
        } catch (final Exception e) {
            Log.w(Config.LOGTAG, "autoPlay failed", e);
            AudioPlayer.currentlyPlayingMessage = null;
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/service/AudioPlayer.java
git commit -m "feat(walkie-talkie): add autoPlay method to AudioPlayer"
```

---

### Task 12: Expose AudioPlayer from MessageAdapter

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/adapter/MessageAdapter.java`

- [ ] **Step 1: Add getter**

After the existing `getFileBackend()` method (line ~2478), add:

```java
public AudioPlayer getAudioPlayer() {
    return audioPlayer;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/adapter/MessageAdapter.java
git commit -m "feat(walkie-talkie): expose AudioPlayer getter in MessageAdapter"
```

---

### Task 13: Implement auto-play in ConversationFragment

**Files:**
- Modify: `src/main/java/eu/siacs/conversations/ui/ConversationFragment.java`

- [ ] **Step 1: Add tracking field**

Near the other field declarations (around line ~326 where `mediaPreviewAdapter` is declared), add:

```java
private String lastAutoPlayedMessageUuid = null;
```

- [ ] **Step 2: Add auto-play call in refresh()**

In `refresh(boolean notifyConversationRead)`, after `this.messageListAdapter.notifyDataSetChanged();` (line ~4830), add:

```java
if (conversation.isWalkieTalkieMode()) {
    autoPlayLatestVoiceMessage();
}
```

- [ ] **Step 3: Implement autoPlayLatestVoiceMessage**

Add this method near the other walkie-talkie methods:

```java
private void autoPlayLatestVoiceMessage() {
    if (messageList.isEmpty()) return;
    final Message lastMessage = messageList.get(messageList.size() - 1);
    if (lastMessage.getStatus() == Message.STATUS_RECEIVED
            && lastMessage.getFileParams() != null
            && lastMessage.getFileParams().runtime > 0
            && lastMessage.getTransferable() == null
            && !lastMessage.getUuid().equals(lastAutoPlayedMessageUuid)) {
        final File file = activity.xmppConnectionService.getFileBackend().getFile(lastMessage);
        if (file.exists()) {
            lastAutoPlayedMessageUuid = lastMessage.getUuid();
            messageListAdapter.getAudioPlayer().autoPlay(lastMessage);
        }
    }
}
```

Note: `messageListAdapter` is the adapter for the messages ListView. Verify it's the correct reference — search for its declaration. It should be of type `MessageAdapter`. If the getter doesn't exist on it, check the actual adapter class name and adjust.

- [ ] **Step 4: Reset lastAutoPlayedMessageUuid when switching conversations**

Search for where conversation is set/changed (look for `this.conversation =` assignments). When the conversation changes, reset:

```java
lastAutoPlayedMessageUuid = null;
```

This is likely in a method like `setConversation()` or `reInit()`. Find it and add the reset.

- [ ] **Step 5: Build and verify**

Run: `./gradlew assembleMonocleschatDebug`
Expected: When WT mode is on and a new voice message arrives while viewing the chat, it auto-plays. Same message doesn't replay on refresh. Switching chats resets the tracking.

- [ ] **Step 6: Commit**

```bash
git add src/main/java/eu/siacs/conversations/ui/ConversationFragment.java
git commit -m "feat(walkie-talkie): auto-play incoming voice messages in walkie-talkie mode"
```

---

## Chunk 6: Final Verification

### Task 14: End-to-end testing

- [ ] **Step 1: Build the app**

Run: `./gradlew assembleMonocleschatDebug`
Expected: Clean build with no errors.

- [ ] **Step 2: Manual test checklist**

Test each item from the spec's verification section:

1. Toggle persistence: Enable WT mode → restart app → verify still enabled
2. Simplified input bar: Emoji/camera hidden in WT mode, visible when off
3. Large overlay: Tap WT icon → overlay appears. Tap X → overlay dismisses
4. Record via overlay: Tap large button → recording starts (red icon, timer). Tap again → stops and sends immediately (no preview)
5. Record via small button: Use regular record button in WT mode → auto-sends (no preview)
6. Auto-play: Send a voice message from another device → verify it plays automatically when chat is open
7. No double-play: Wait for refresh cycle → same message doesn't replay
8. Normal mode: Disable WT → verify everything works as before
9. Both chat types: Test in 1-on-1 and group chat

- [ ] **Step 3: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix(walkie-talkie): address issues found during testing"
```
