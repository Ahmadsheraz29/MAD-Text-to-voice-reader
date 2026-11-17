# Voice Reader (MAD Project – Text to Speech Reader)

A Flutter mobile app that reads text aloud. Paste text or upload a document (PDF, DOCX, TXT) and listen to it in a choice of voices, with adjustable speed and pitch. The UI uses a modern "glassmorphism" design with blurred, translucent cards.

---

## Features

- **Real text-to-speech** powered by the device's speech engine (`flutter_tts`)
- **Paste Text** – paste or type up to 500 words, with live word count and estimated read time
- **Upload Document** – pick a PDF, DOCX or TXT file (up to 25 MB) and have its text extracted and read aloud
- **Audio Player** – play, pause, seek bar and elapsed/remaining time
- **Voices** – four voices (Nova, Echo, Onyx, Alloy) with preview, gender filter, and Speed/Pitch sliders
- **My Library** – In Progress and Completed tabs
- **Sign Up / Login** – form validation for email, name and password
- **Glass UI** – reusable `GlassCard`, `GlassButton`, `GlassField` and `GlassBackground` widgets

---

## Screens

| # | Screen | Description |
|---|--------|-------------|
| 1 | Sign Up | Create an account (email, first name, last name, password) |
| 2 | Login | Sign in with email and password |
| 3 | Home | Greeting, Paste Text / Upload File shortcuts, recent readings, now-playing bar, bottom navigation |
| 4 | Paste Text | Text area with a 500-word limit, voice dropdown and Listen button |
| 5 | Upload Document | File browser, type filters, recent uploads and Continue button |
| 6 | Audio Player | Full player with seek bar and play/pause |
| 7 | Voices | Voice cards with preview, filters, speed and pitch settings |
| 8 | My Library | Tabs for in-progress and completed items |

---

## Tech Stack

| Purpose | Package |
|---------|---------|
| Framework | Flutter (Material 3) |
| Text-to-speech | [`flutter_tts`](https://pub.dev/packages/flutter_tts) |
| File picking | [`file_picker`](https://pub.dev/packages/file_picker) |
| PDF text extraction | [`syncfusion_flutter_pdf`](https://pub.dev/packages/syncfusion_flutter_pdf) |
| DOCX (zip) reading | [`archive`](https://pub.dev/packages/archive) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Android Studio or VS Code with the Flutter extension
- A **real Android device** is recommended (emulators often have no TTS engine)

### Installation

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd <your-project-folder>

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

If you are setting up the dependencies manually:

```bash
flutter pub add flutter_tts file_picker syncfusion_flutter_pdf archive
```

### Android configuration

Add the following inside `<manifest>` (before `<application>`) in `android/app/src/main/AndroidManifest.xml`. Without it, speech does not work on Android 11 and above:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
</queries>
```

On the phone, make sure a speech engine is selected under
**Settings → System → Text-to-speech output** (for example, *Speech Services by Google*). To get more distinct voices, download additional English voices in the engine's settings.

---

## Project Structure

```
lib/
└── main.dart     # All screens, widgets, and the TtsService
```

Main building blocks inside `main.dart`:

- `TtsService` – wraps `flutter_tts` (init, speak, stop, voice/speed/pitch setup)
- `kVoices` – list of available `VoiceOption`s
- `selectedVoice`, `voiceSpeed`, `voicePitch` – shared `ValueNotifier`s used across screens
- `WordLimitFormatter` – enforces the 500-word limit on pasted text
- Screens: `SignUpScreen`, `LoginScreen`, `HomeScreen`, `PasteTextScreen`, `UploadDocumentScreen`, `AudioPlayerScreen`, `VoicesScreen`, `LibraryScreen`

---

## How It Works

1. **Choose a voice** on the Voices screen and tap *Apply Voice* (speed and pitch are saved too).
2. **Paste text** or **upload a file**. For uploads, the app reads the file, extracts the text (TXT directly, PDF via Syncfusion, DOCX by reading `word/document.xml`) and passes it to the player.
3. The **Audio Player** speaks the text with the selected voice. Pausing stops speech; pressing play resumes from the same position.

---

## Known Limitations

- **No backend.** Sign Up and Login only validate input locally; there is no real authentication yet.
- **Placeholder data.** Recent Readings and My Library show sample items.
- **Not yet implemented.** Notifications, Profile, Next chapter and password reset show a "coming soon" message.
- **Long documents.** Android TTS handles roughly 4,000 characters at once, so uploaded files are limited to the first ~3,900 characters. Chunked reading is a planned improvement.
- **Scanned PDFs.** Image-only PDFs have no extractable text (OCR is not included).
- **Pause behaviour.** Android TTS has no true pause; the app stops and restarts from the current position.
- **Voices.** Voices are mapped to the English voices installed on the device, with a different pitch applied to each. If the device has only one English voice, the difference will be mainly in pitch.

---

## Future Improvements

- Firebase (or another backend) authentication
- Reading long documents in chunks
- Saving library items and reading progress to local storage
- OCR support for scanned PDFs
- Profile and notification screens
- Support for more languages

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No sound | Test on a real device; check the TTS engine in system settings; confirm the `<queries>` block is in `AndroidManifest.xml` |
| Slow first build | The first Gradle build can take several minutes; later builds are faster |
| Kotlin Gradle Plugin warning from `flutter_tts` | Only a warning; try `flutter pub upgrade flutter_tts` |
| Strange build errors | Run `flutter clean`, then `flutter pub get`, then `flutter run` |

---

## Author

Developed by **Ahmad Sheraz and Abdul Wahab** as a Mobile Application Development (MAD) course project.

---

## License

This project is for educational purposes.
