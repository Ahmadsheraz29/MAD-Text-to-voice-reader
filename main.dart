// lib/main.dart
// Voice Reader App - 8 Screens with REAL Text-to-Speech
// Packages: flutter_tts, file_picker, syncfusion_flutter_pdf, archive
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceReaderApp());
}

// ---------------------------------------------------------------------------
// Colors & helpers
// ---------------------------------------------------------------------------
const kIndigo = Color(0xFF1E1E8F);
const kPurple = Color(0xFF8B87E8);
const kNavy = Color(0xFF0A0A4A);
const kInk = Color(0xFF14143C);
const kMuted = Color(0xFF6B6F8D);

Color alpha(Color c, double o) => c.withAlpha((o * 255).round());

// Shared state
final ValueNotifier<String> selectedVoice =
ValueNotifier<String>('Nova (Natural, English)');
final ValueNotifier<double> voiceSpeed = ValueNotifier<double>(1.0);
final ValueNotifier<double> voicePitch = ValueNotifier<double>(1.0);

const String kSampleText =
    'Artificial intelligence is the ability of machines to perform tasks that '
    'normally require human intelligence. This includes learning from '
    'experience, understanding language, recognizing images, and making '
    'decisions. Today, artificial intelligence is used in many areas such as '
    'healthcare, education, finance, and transportation. As the technology '
    'grows, it is important to use it responsibly and to understand both its '
    'benefits and its limits.';

// ---------------------------------------------------------------------------
// Voice options (shared by Paste Text, Voices, TTS service)
// ---------------------------------------------------------------------------
class VoiceOption {
  final String name;
  final String label;
  final String style;
  final String gender;
  final String language;
  final IconData icon;
  final double pitchShift; // makes each voice sound different
  const VoiceOption({
    required this.name,
    required this.label,
    required this.style,
    required this.gender,
    required this.language,
    required this.icon,
    this.pitchShift = 1.0,
  });
}

const List<VoiceOption> kVoices = [
  VoiceOption(
      name: 'Nova',
      label: 'Nova (Natural, English)',
      style: 'Natural',
      gender: 'Female',
      language: 'English',
      icon: Icons.record_voice_over_rounded,
      pitchShift: 1.15),
  VoiceOption(
      name: 'Echo',
      label: 'Echo (Calm, English)',
      style: 'Calm',
      gender: 'Male',
      language: 'English',
      icon: Icons.spa_rounded,
      pitchShift: 0.9),
  VoiceOption(
      name: 'Onyx',
      label: 'Onyx (Deep, English)',
      style: 'Deep',
      gender: 'Male',
      language: 'English',
      icon: Icons.graphic_eq_rounded,
      pitchShift: 0.7),
  VoiceOption(
      name: 'Alloy',
      label: 'Alloy (Neutral, English)',
      style: 'Neutral',
      gender: 'Neutral',
      language: 'English',
      icon: Icons.equalizer_rounded,
      pitchShift: 1.0),
];

// ---------------------------------------------------------------------------
// TTS Service (real speech)
// ---------------------------------------------------------------------------
class TtsService {
  static final FlutterTts engine = FlutterTts();
  static bool _ready = false;
  static final List<Map<String, String>> _enVoices = [];

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await engine.setLanguage('en-US');
      await engine.setVolume(1.0);
      final dynamic v = await engine.getVoices;
      if (v is List) {
        for (final e in v) {
          if (e is Map) {
            final name = e['name']?.toString();
            final locale = e['locale']?.toString();
            if (name == null || locale == null) continue;
            final l = locale.toLowerCase().replaceAll('_', '-');
            if (l.startsWith('en')) {
              _enVoices.add({'name': name, 'locale': locale});
            }
          }
        }
        _enVoices.sort((a, b) => a['name']!.compareTo(b['name']!));
      }
    } catch (_) {}
  }

  static Future<void> _apply(String label, double speed, double pitch) async {
    await init();
    final idx = kVoices.indexWhere((v) => v.label == label);
    final i = idx < 0 ? 0 : idx;
    final opt = kVoices[i];
    if (_enVoices.isNotEmpty) {
      final pick = _enVoices[i % _enVoices.length];
      try {
        await engine.setVoice({'name': pick['name']!, 'locale': pick['locale']!});
      } catch (_) {}
    }
    try {
      await engine.setSpeechRate((0.5 * speed).clamp(0.1, 1.0).toDouble());
      await engine.setPitch((pitch * opt.pitchShift).clamp(0.5, 2.0).toDouble());
    } catch (_) {}
  }

  static Future<void> speak(
      String text, {
        required String voiceLabel,
        required double speed,
        required double pitch,
      }) async {
    if (text.trim().isEmpty) return;
    try {
      await engine.stop();
      await _apply(voiceLabel, speed, pitch);
      await engine.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await engine.stop();
    } catch (_) {}
  }

  static void clearHandlers() {
    engine.setCompletionHandler(() {});
    engine.setErrorHandler((_) {});
    engine.setProgressHandler((a, b, c, d) {});
  }
}

class VoiceReaderApp extends StatelessWidget {
  const VoiceReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kIndigo),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const SignUpScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable glass widgets
// ---------------------------------------------------------------------------
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAEAFB), Color(0xFFF6F7FD), Color(0xFFD9DBF7)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, left: -60, child: _blob(240, kPurple, 0.45)),
          Positioned(
              top: 260,
              right: -90,
              child: _blob(260, const Color(0xFF6C8CFF), 0.30)),
          Positioned(bottom: -80, left: -40, child: _blob(260, kIndigo, 0.25)),
          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: alpha(color, opacity),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = tint ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [alpha(base, 0.70), alpha(base, 0.35)],
                ),
                border: Border.all(color: alpha(Colors.white, 0.75), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: alpha(kIndigo, 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: filled ? alpha(kIndigo, 0.92) : alpha(Colors.white, 0.6),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              height: 50,
              width: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: alpha(Colors.white, 0.8)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: filled ? Colors.white : kIndigo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const GlassField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  State<GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<GlassField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboard,
          obscureText: widget.isPassword && _hidden,
          validator: widget.validator,
          style: const TextStyle(fontSize: 14, color: kInk),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
            filled: true,
            fillColor: alpha(Colors.white, 0.55),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _hidden ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: kMuted,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: alpha(Colors.white, 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: alpha(Colors.white, 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kIndigo, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

String? requiredValidator(String? v, String msg) =>
    (v == null || v.trim().isEmpty) ? msg : null;

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
  return ok ? null : 'Enter a valid email';
}

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'At least 6 characters';
  return null;
}

// ---------------------------------------------------------------------------
// SCREEN 1: Sign Up
// ---------------------------------------------------------------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _first.dispose();
    _last.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: _first.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              radius: 28,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq_rounded,
                        size: 44, color: kIndigo),
                    const SizedBox(height: 8),
                    const Text(
                      'Create account',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kIndigo),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign up to listen to text in voice',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: kMuted),
                    ),
                    const SizedBox(height: 22),
                    GlassField(
                      hint: 'Enter your email',
                      controller: _email,
                      keyboard: TextInputType.emailAddress,
                      validator: emailValidator,
                    ),
                    const SizedBox(height: 14),
                    GlassField(
                      hint: 'Your first name',
                      controller: _first,
                      validator: (v) =>
                          requiredValidator(v, 'First name is required'),
                    ),
                    const SizedBox(height: 14),
                    GlassField(
                      hint: 'Last Name',
                      controller: _last,
                      validator: (v) =>
                          requiredValidator(v, 'Last name is required'),
                    ),
                    const SizedBox(height: 14),
                    GlassField(
                      hint: 'Password',
                      controller: _password,
                      isPassword: true,
                      validator: passwordValidator,
                    ),
                    const SizedBox(height: 24),
                    GlassButton(
                        label: 'Sign Up', onPressed: _signUp, filled: true),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(fontSize: 12, color: kMuted)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kIndigo),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: Login
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final name = _email.text.trim().split('@').first;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(userName: name)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  radius: 28,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 42, color: kIndigo),
                        const SizedBox(height: 8),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: kIndigo),
                        ),
                        const SizedBox(height: 22),
                        GlassField(
                          hint: 'Enter your email',
                          controller: _email,
                          keyboard: TextInputType.emailAddress,
                          validator: emailValidator,
                        ),
                        const SizedBox(height: 16),
                        GlassField(
                          hint: 'Password',
                          controller: _password,
                          isPassword: true,
                          validator: passwordValidator,
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                            label: 'Login', onPressed: _login, filled: true),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Password reset is coming soon')),
                              ),
                          child: const Text('Forget Password?',
                              style: TextStyle(fontSize: 12, color: kMuted)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: kInk),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 3: Home
// ---------------------------------------------------------------------------
class ReadingItem {
  final String title;
  final String info;
  final IconData icon;
  const ReadingItem(this.title, this.info, this.icon);
}

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _muted = true;
  bool _playing = true;

  static const _readings = [
    ReadingItem('AI Over Review.Pdf', '8 mins left  •  45% completed',
        Icons.picture_as_pdf_outlined),
    ReadingItem('AI Over Review.Image', '8 mins left  •  45% completed',
        Icons.image_outlined),
    ReadingItem('AI Over Review.Text', '8 mins left  •  45% completed',
        Icons.description_outlined),
  ];

  @override
  void initState() {
    super.initState();
    TtsService.init(); // warm up the speech engine
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _soon(String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName.isEmpty ? 'User' : widget.userName;
    return Scaffold(
      body: GlassBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting, $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: kIndigo),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'what would you like to listen today?',
                              style: TextStyle(fontSize: 12, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        radius: 30,
                        onTap: () => _soon('Notifications'),
                        child: const Icon(Icons.notifications,
                            size: 22, color: kInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          tint: kPurple,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PasteTextScreen()),
                          ),
                          child: const SizedBox(
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.content_paste_rounded,
                                    size: 26, color: kNavy),
                                Spacer(),
                                Text('Paste Text',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                SizedBox(height: 2),
                                Text('Read clipboard\nInstantly',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GlassCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const UploadDocumentScreen()),
                          ),
                          child: const SizedBox(
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.upload_file_rounded,
                                    size: 26, color: kInk),
                                Spacer(),
                                Text('Upload File',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: kInk)),
                                SizedBox(height: 2),
                                Text('PDF,DOCx,TXT',
                                    style: TextStyle(
                                        fontSize: 10, color: kMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Recent Readings',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kIndigo)),
                  const SizedBox(height: 12),
                  for (final r in _readings) ...[
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      radius: 16,
                      child: Row(
                        children: [
                          Icon(r.icon, size: 28, color: kInk),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: kInk)),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 11, color: kMuted),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(r.info,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 10, color: kMuted)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AudioPlayerScreen(title: r.title)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: alpha(kIndigo, 0.08),
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  size: 22, color: kInk),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            // Now playing bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  color: kNavy,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AudioPlayerScreen()),
                          ),
                          child: const Text('Chapter 1: The Beginning',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _playing = !_playing),
                        child: Icon(
                            _playing ? Icons.pause : Icons.play_arrow,
                            size: 20,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () => _soon('Next chapter'),
                        child: const Icon(Icons.skip_next,
                            size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom navigation (glass)
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: alpha(Colors.white, 0.55),
                    border: Border(
                        top: BorderSide(color: alpha(Colors.white, 0.9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(0, Icons.home_rounded, 'Home'),
                      _navItem(1, Icons.mic_none_rounded, 'Voices'),
                      _navItem(2, Icons.menu_book_rounded, 'Library'),
                      _navItem(
                        -1,
                        _muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        _muted ? 'Volume Off' : 'Volume On',
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      _navItem(3, Icons.person_outline_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {VoidCallback? onTap}) {
    final selected = index == _tab;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ??
              () {
            if (index == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoicesScreen()),
              );
              return;
            }
            if (index == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
              return;
            }
            setState(() => _tab = index);
            if (index != 0) _soon(label);
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: selected ? kIndigo : kInk),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? kIndigo : kInk)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 4: Paste Text (max 500 words)
// ---------------------------------------------------------------------------
class WordLimitFormatter extends TextInputFormatter {
  final int maxWords;
  WordLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final matches = RegExp(r'\S+').allMatches(newValue.text).toList();
    if (matches.length <= maxWords) return newValue;
    final end = matches[maxWords - 1].end;
    return TextEditingValue(
      text: newValue.text.substring(0, end),
      selection: TextSelection.collapsed(offset: end),
    );
  }
}

class PasteTextScreen extends StatefulWidget {
  const PasteTextScreen({super.key});

  @override
  State<PasteTextScreen> createState() => _PasteTextScreenState();
}

class _PasteTextScreenState extends State<PasteTextScreen> {
  static const int maxWords = 500;
  final _controller = TextEditingController();
  late String _voice = selectedVoice.value;

  int get _words => RegExp(r'\S+').allMatches(_controller.text).length;

  String get _readTime {
    if (_words == 0) return '0 mins read';
    final mins = (_words / 200).ceil();
    return '$mins ${mins == 1 ? 'min' : 'mins'} read';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    final formatted = WordLimitFormatter(maxWords).formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    if (!mounted) return;
    setState(() => _controller.value = formatted);
    final total = RegExp(r'\S+').allMatches(text).length;
    if (total > maxWords) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only the first $maxWords words were kept')));
    }
  }

  void _listen() {
    if (_words == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste or type text first')));
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AudioPlayerScreen(title: 'Pasted Text', text: _controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _words >= maxWords;
    return Scaffold(
      body: GlassBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: kInk),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text('Paste Content',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _paste,
                    child: const Text('Paste',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: kIndigo)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _controller.clear()),
                    child: const Text('Clear',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: kMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          inputFormatters: [WordLimitFormatter(maxWords)],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14, color: kInk),
                          decoration: const InputDecoration(
                            hintText:
                            'Paste or type your text here to convert into natural speech...',
                            hintStyle: TextStyle(fontSize: 12, color: kMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_readTime,
                              style: const TextStyle(
                                  fontSize: 11, color: kMuted)),
                          Text('$_words / $maxWords words',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                  atLimit ? Colors.redAccent : kMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                radius: 14,
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, size: 18, color: kInk),
                    const SizedBox(width: 8),
                    const Text('Voice: ',
                        style: TextStyle(fontSize: 12, color: kInk)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _voice,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: kInk),
                          style: const TextStyle(fontSize: 12, color: kInk),
                          dropdownColor: const Color(0xFFF1F2FD),
                          items: [
                            for (final v in kVoices)
                              DropdownMenuItem(
                                  value: v.label, child: Text(v.label)),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _voice = v);
                            selectedVoice.value = v;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassButton(label: 'Listen', onPressed: _listen, filled: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 5: Upload Document
// ---------------------------------------------------------------------------
class UploadedFile {
  final String name;
  final int bytes;
  final Uint8List? data;
  bool selected;
  UploadedFile(this.name, this.bytes, {this.data, this.selected = false});

  String get ext =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  static const int maxBytes = 25 * 1024 * 1024;
  static const int maxChars = 3900; // Android TTS limit is ~4000 chars
  static const _types = ['PDF', 'DOCX', 'TXT'];

  final Set<String> _filter = {};
  bool _busy = false;

  final List<UploadedFile> _recent = [
    UploadedFile('Document_01.pdf', 1200000, selected: true),
  ];

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _browse() async {
    final allowed = (_filter.isEmpty ? _types : _filter.toList())
        .map((e) => e.toLowerCase())
        .toList();
    try {
      // dynamic is liye ke file_picker ke alag versions mein return type alag hai
      final dynamic res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowed,
      );
      if (res == null) return;

      final List<dynamic> list = (res is List) ? res : (res.files as List);
      if (list.isEmpty) return;
      final dynamic f = list.first;

      final String? path = f.path as String?;
      if (path == null) {

        _snack('Could not read file');
        return;
      }
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        _snack('File is larger than 25MB');
        return;
      }
      final name = path.split(RegExp(r'[\\/]')).last;

      if (!mounted) return;
      setState(() {
        for (final r in _recent) {
          r.selected = false;
        }
        _recent.insert(
            0, UploadedFile(name, bytes.length, data: bytes, selected: true));
      });
    } catch (e) {
      _snack('Could not select file');
    }
  }

  IconData _iconFor(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'docx':
        return Icons.article_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _size(int b) => b >= 1024 * 1024
      ? '${(b / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(b / 1024).toStringAsFixed(0)} KB';

  // Extract readable text from the file.
  String _extract(UploadedFile f) {
    final data = f.data;
    if (data == null) return kSampleText; // demo file without real data
    try {
      switch (f.ext) {
        case 'txt':
          return utf8.decode(data, allowMalformed: true);
        case 'pdf':
          final doc = sfpdf.PdfDocument(inputBytes: data);
          final text = sfpdf.PdfTextExtractor(doc).extractText();
          doc.dispose();
          return text;
        case 'docx':
          final archive = ZipDecoder().decodeBytes(data);
          for (final file in archive) {
            if (file.name == 'word/document.xml') {
              final xml = utf8.decode(file.content as List<int>,
                  allowMalformed: true);
              return xml
                  .replaceAll('</w:p>', '\n')
                  .replaceAll(RegExp(r'<[^>]+>'), '')
                  .replaceAll('&amp;', '&')
                  .replaceAll('&lt;', '<')
                  .replaceAll('&gt;', '>')
                  .replaceAll('&quot;', '"')
                  .replaceAll('&apos;', "'");
            }
          }
          return '';
        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _continue() async {
    final sel = _recent.where((e) => e.selected).toList();
    if (sel.isEmpty) {
      _snack('Please select a file first');
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    String text = _extract(sel.first).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!mounted) return;
    setState(() => _busy = false);

    if (text.isEmpty) {
      _snack('Is file mein se text nahi mila');
      return;
    }
    if (text.length > maxChars) {
      text = text.substring(0, maxChars);
      _snack('Pehle $maxChars characters parhe jayenge');
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudioPlayerScreen(title: sel.first.name, text: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kInk),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('Upload Document',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              radius: 20,
              tint: const Color(0xFFE4E5FF),
              onTap: _browse,
              padding: EdgeInsets.zero,
              child: Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: const Color(0xFF6C6CF0), width: 1.4),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 46, color: Color(0xFF5A4FCF)),
                    SizedBox(height: 14),
                    Text('Browse files to upload',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                    SizedBox(height: 4),
                    Text('Supports PDF, DOCX, TXT up to 25MB',
                        style: TextStyle(fontSize: 10, color: kMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in _types)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _typeChip(t),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Recent Uploads',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 14),
            if (_recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No files uploaded yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ),
            for (final f in _recent) ...[
              GlassCard(
                radius: 14,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(_iconFor(f.ext), size: 30, color: kInk),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kInk)),
                          const SizedBox(height: 2),
                          Text(_size(f.bytes),
                              style: const TextStyle(
                                  fontSize: 10, color: kMuted)),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: f.selected,
                      activeColor: const Color(0xFF5A4FCF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() {
                        for (final r in _recent) {
                          r.selected = false;
                        }
                        f.selected = v ?? false;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            Center(
              child: _busy
                  ? const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()))
                  : GlassButton(
                  label: 'Continue', onPressed: _continue, filled: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String t) {
    final on = _filter.contains(t);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: on ? alpha(kIndigo, 0.9) : alpha(Colors.white, 0.55),
          child: InkWell(
            onTap: () => setState(() {
              on ? _filter.remove(t) : _filter.add(t);
            }),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: alpha(Colors.white, 0.8)),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : kInk)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 6: Full Audio Player (REAL speech)
// ---------------------------------------------------------------------------
class AudioPlayerScreen extends StatefulWidget {
  final String title;
  final String? text;
  const AudioPlayerScreen(
      {super.key, this.title = 'Chapter 1: The Beginning', this.text});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final String _text;
  late final int _total; // estimated duration in seconds
  int _position = 0;
  bool _playing = false;
  bool _bookmarked = false;
  bool _hasProgress = false;
  int _baseOffset = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    var t = (widget.text ?? '').trim();
    if (t.isEmpty) t = kSampleText;
    if (t.length > 3900) t = t.substring(0, 3900);
    _text = t;

    final words = RegExp(r'\S+').allMatches(_text).length;
    final wpm = 150 * voiceSpeed.value;
    _total = ((words / wpm) * 60).ceil().clamp(3, 100000).toInt();

    final engine = TtsService.engine;
    engine.setCompletionHandler(() {
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = _total;
      });
    });
    engine.setErrorHandler((msg) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _playing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Speech error: $msg')));
    });
    engine.setProgressHandler((String t, int start, int end, String word) {
      if (!mounted || !_playing) return;
      _hasProgress = true;
      final abs = _baseOffset + start;
      final pos = ((abs / _text.length) * _total).round().clamp(0, _total);
      setState(() => _position = pos);
    });

    _play();
  }

  int _snapToWord(int o) {
    if (o <= 0) return 0;
    if (o >= _text.length) return _text.length - 1;
    while (o > 0 && _text[o - 1].trim().isNotEmpty) {
      o--;
    }
    return o;
  }

  Future<void> _play() async {
    if (_position >= _total) _position = 0;
    final raw = ((_text.length * _position) / _total).floor();
    _baseOffset = _snapToWord(raw);
    _hasProgress = false;
    if (mounted) setState(() => _playing = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_playing || _hasProgress) return;
      if (_position < _total - 1) {
        setState(() => _position++);
      }
    });

    await TtsService.speak(
      _text.substring(_baseOffset),
      voiceLabel: selectedVoice.value,
      speed: voiceSpeed.value,
      pitch: voicePitch.value,
    );
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await TtsService.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.stop();
    TtsService.clearHandlers();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  void _togglePlay() {
    if (_playing) {
      _pause();
    } else {
      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _total - _position;
    return Scaffold(
      body: GlassBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 30, color: kInk),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text('Now Playing',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ),
                    IconButton(
                      icon: Icon(
                        _bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: kInk,
                      ),
                      onPressed: () =>
                          setState(() => _bookmarked = !_bookmarked),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A1F8F), Color(0xFF4A3FE0)],
                    ),
                    border: Border.all(color: alpha(Colors.white, 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: alpha(kIndigo, 0.35),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                        _playing
                            ? Icons.graphic_eq_rounded
                            : Icons.music_note_rounded,
                        size: 54,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 4),
              Text('Voice: ${selectedVoice.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: kIndigo)),
              const SizedBox(height: 22),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: const Color(0xFF4A3FE0),
                  inactiveTrackColor: alpha(kIndigo, 0.15),
                  thumbColor: const Color(0xFF4A3FE0),
                  thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _position.toDouble().clamp(0, _total.toDouble()),
                  min: 0,
                  max: _total.toDouble(),
                  onChanged: (v) => setState(() => _position = v.round()),
                  onChangeEnd: (_) {
                    if (_playing) _play();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF4A3FE0))),
                    Text(_fmt(remaining < 0 ? 0 : remaining),
                        style: const TextStyle(fontSize: 10, color: kMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A3FE0),
                    boxShadow: [
                      BoxShadow(
                        color: alpha(const Color(0xFF4A3FE0), 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 7: Voices (real preview)
// ---------------------------------------------------------------------------
class VoicesScreen extends StatefulWidget {
  const VoicesScreen({super.key});

  @override
  State<VoicesScreen> createState() => _VoicesScreenState();
}

class _VoicesScreenState extends State<VoicesScreen> {
  static const _filters = ['All', 'Female', 'Male', 'Neutral'];

  String _filter = 'All';
  late String _selected = selectedVoice.value;
  String? _previewing;
  Timer? _previewTimer;
  double _speed = voiceSpeed.value;
  double _pitch = voicePitch.value;

  List<VoiceOption> get _visible => _filter == 'All'
      ? kVoices
      : kVoices.where((v) => v.gender == _filter).toList();

  @override
  void initState() {
    super.initState();
    TtsService.init();
    TtsService.engine.setCompletionHandler(() {
      _previewTimer?.cancel();
      if (mounted) setState(() => _previewing = null);
    });
    TtsService.engine.setErrorHandler((_) {
      if (mounted) setState(() => _previewing = null);
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    TtsService.stop();
    TtsService.clearHandlers();
    super.dispose();
  }

  Future<void> _preview(VoiceOption v) async {
    _previewTimer?.cancel();
    if (_previewing == v.label) {
      await TtsService.stop();
      if (mounted) setState(() => _previewing = null);
      return;
    }
    setState(() => _previewing = v.label);
    // safety timeout in case a platform doesn't send a completion event
    _previewTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _previewing = null);
    });
    await TtsService.speak(
      'Hello, I am ${v.name}. This is how I sound when I read your text.',
      voiceLabel: v.label,
      speed: _speed,
      pitch: _pitch,
    );
  }

  void _apply() {
    selectedVoice.value = _selected;
    voiceSpeed.value = _speed;
    voicePitch.value = _pitch;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Voice set to $_selected')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      body: GlassBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: kInk),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text('Voices',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kInk)),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Choose your reading voice',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kIndigo)),
                  const SizedBox(height: 2),
                  const Text('Tap play to preview, tap a card to select',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _filters) ...[
                          _filterChip(f),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No voices found',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ),
                  for (final v in list) ...[
                    _voiceCard(v),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  const Text('Voice Settings',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kIndigo)),
                  const SizedBox(height: 12),
                  GlassCard(
                    radius: 16,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        _sliderRow(
                          icon: Icons.speed_rounded,
                          label: 'Speed',
                          value: _speed,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (v) => setState(() => _speed = v),
                        ),
                        _sliderRow(
                          icon: Icons.tune_rounded,
                          label: 'Pitch',
                          value: _pitch,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (v) => setState(() => _pitch = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GlassButton(
                        label: 'Apply Voice', onPressed: _apply, filled: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String t) {
    final on = _filter == t;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: on ? alpha(kIndigo, 0.9) : alpha(Colors.white, 0.55),
          child: InkWell(
            onTap: () => setState(() => _filter = t),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: alpha(Colors.white, 0.8)),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : kInk)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _voiceCard(VoiceOption v) {
    final isSelected = _selected == v.label;
    final isPreviewing = _previewing == v.label;
    return GlassCard(
      radius: 18,
      tint: isSelected ? const Color(0xFFE4E5FF) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => setState(() => _selected = v.label),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A3FE0), kPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: alpha(const Color(0xFF4A3FE0), 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(v.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                const SizedBox(height: 3),
                Text('${v.style}  •  ${v.gender}  •  ${v.language}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: kMuted)),
                if (isPreviewing) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          size: 12, color: Color(0xFF4A3FE0)),
                      SizedBox(width: 4),
                      Text('Playing preview...',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A3FE0))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _preview(v),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: alpha(kIndigo, 0.08),
              ),
              child: Icon(
                  isPreviewing
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  size: 22,
                  color: kInk),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? const Color(0xFF5A4FCF) : kMuted,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kInk),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child:
          Text(label, style: const TextStyle(fontSize: 12, color: kInk)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: const Color(0xFF4A3FE0),
              inactiveTrackColor: alpha(kIndigo, 0.15),
              thumbColor: const Color(0xFF4A3FE0),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 15,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text('${value.toStringAsFixed(1)}x',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A3FE0))),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 8: My Library
// ---------------------------------------------------------------------------
class LibraryItem {
  final String title;
  final double progress;
  const LibraryItem(this.title, [this.progress = 1.0]);
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 1;

  static const _inProgress = [
    LibraryItem('Operating_Systems.PDF', 0.45),
    LibraryItem('Network_Security.PDF', 0.20),
    LibraryItem('Algorithms_Notes.PDF', 0.70),
  ];

  static const _completed = [
    LibraryItem('History.PDF'),
    LibraryItem('Lecture_Notes.PDF'),
    LibraryItem('AI Over Review.Pdf'),
    LibraryItem('Research_Papers.PDF'),
    LibraryItem('Design_Brief.PDF'),
    LibraryItem('Web_Technologies.PDF'),
    LibraryItem('Assembly_Basics.PDF'),
    LibraryItem('Computer_Networks.PDF'),
    LibraryItem('Mobile_App_Dev.PDF'),
    LibraryItem('Info_Security.PDF'),
    LibraryItem('Python_Cheatsheet.PDF'),
    LibraryItem('Project_Report.PDF'),
  ];

  List<LibraryItem> get _items => _tab == 0 ? _inProgress : _completed;

  void _open(LibraryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AudioPlayerScreen(title: item.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      body: GlassBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back, size: 20, color: kInk),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('My Library',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kInk)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                          0,
                          'In Progress (${_inProgress.length})',
                          Alignment.centerLeft),
                    ),
                    Expanded(
                      child: _tabButton(1, 'Completed (${_completed.length})',
                          Alignment.centerRight),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                      child: Text('Nothing here yet',
                          style: TextStyle(fontSize: 12, color: kMuted)))
                      : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (_, i) => _libraryCard(items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label, Alignment align) {
    final on = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: align,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                      color: on ? const Color(0xFF3A4A9F) : kMuted)),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: on ? const Color(0xFF4A3FE0) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _libraryCard(LibraryItem item) {
    final inProgress = _tab == 0;
    return GlassCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => _open(item),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: alpha(Colors.white, 0.8),
              border: Border.all(color: alpha(kMuted, 0.35)),
            ),
            child:
            const Icon(Icons.description_outlined, size: 20, color: kInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: kInk)),
                if (inProgress) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: alpha(kIndigo, 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF4A3FE0)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('${(item.progress * 100).round()}% completed',
                      style: const TextStyle(fontSize: 9, color: kMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _open(item),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: alpha(kIndigo, 0.08),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 20, color: kInk),
            ),
          ),
        ],
      ),
    );
  }
}