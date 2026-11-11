// lib/main.dart
// Voice Reader App - 5 Screens (Sign Up, Login, Home, Paste Text, Upload Document)
// Only Flutter SDK is used, no extra packages required.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const VoiceReaderApp());

// ---------------------------------------------------------------------------
// Colors & helpers
// ---------------------------------------------------------------------------
const kIndigo = Color(0xFF1E1E8F);
const kPurple = Color(0xFF8B87E8);
const kNavy = Color(0xFF0A0A4A);
const kInk = Color(0xFF14143C);
const kMuted = Color(0xFF6B6F8D);

Color alpha(Color c, double o) => c.withAlpha((o * 255).round());

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
          Positioned(top: 260, right: -90, child: _blob(260, const Color(0xFF6C8CFF), 0.30)),
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
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
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
    // Add your backend / Firebase sign up logic here.
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
                    const Icon(Icons.graphic_eq_rounded, size: 44, color: kIndigo),
                    const SizedBox(height: 8),
                    const Text(
                      'Create account',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: kIndigo),
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
                    GlassButton(label: 'Sign Up', onPressed: _signUp, filled: true),
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
    // Add your backend / Firebase login logic here.
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
                                    content: Text('Password reset is coming soon')),
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
                  // Header
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

                  // Paste Text + Upload File
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
                                    style:
                                    TextStyle(fontSize: 10, color: kMuted)),
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
                            onTap: () => _soon('Playback'),
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
                      const Expanded(
                        child: Text('Chapter 1: The Beginning',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
    // If more than 500 words are pasted, keep only the first 500 words
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
  String _voice = 'Nova (Natural, English)';

  static const _voices = [
    'Nova (Natural, English)',
    'Echo (Calm, English)',
    'Onyx (Deep, English)',
    'Alloy (Neutral, English)',
  ];

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    final formatted = WordLimitFormatter(maxWords).formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    setState(() => _controller.value = formatted);
    final total = RegExp(r'\S+').allMatches(text).length;
    if (total > maxWords && mounted) {
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
    // Add your Text-to-Speech logic (flutter_tts / API) here.
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reading $_words words in $_voice')));
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
              // Top bar
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

              // Text area
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
                            hintStyle:
                            TextStyle(fontSize: 12, color: kMuted),
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
                                  color: atLimit
                                      ? Colors.redAccent
                                      : kMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voice selector
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
                            for (final v in _voices)
                              DropdownMenuItem(value: v, child: Text(v)),
                          ],
                          onChanged: (v) => setState(() => _voice = v!),
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
  bool selected;
  UploadedFile(this.name, this.bytes, {this.selected = false});

  String get ext => name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  static const int maxBytes = 25 * 1024 * 1024; // 25MB
  static const _types = ['PDF', 'DOCX', 'TXT'];

  // Empty set means: all three types are allowed
  final Set<String> _filter = {};

  final List<UploadedFile> _recent = [
    UploadedFile('Document_01.pdf', 1200000, selected: true),
  ];

  Future<void> _browse() async {
    final allowed = (_filter.isEmpty ? _types : _filter.toList())
        .map((e) => e.toLowerCase())
        .toList();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowed,
      );
      if (files.isEmpty) return;
      final f = files.first;
      final fileSize = f.lengthSync() ?? 0;
      if (fileSize > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is larger than 25MB')));
        return;
      }
      setState(() {
        for (final r in _recent) {
          r.selected = false;
        }
        _recent.insert(0, UploadedFile(f.name, fileSize, selected: true));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not select file')));
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

  void _continue() {
    final sel = _recent.where((e) => e.selected).toList();
    if (sel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file first')));
      return;
    }
    // Extract file text here and send it to Text-to-Speech.
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${sel.first.name} is ready')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            // Top bar
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

            // Browse box
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
                  border: Border.all(color: const Color(0xFF6C6CF0), width: 1.4),
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

            // Type chips
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
              child: GlassButton(
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