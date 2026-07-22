import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campusscore/services/auth/auth_exceptions.dart';
import 'package:campusscore/services/auth/auth_service.dart';

class Register_Login_View extends StatefulWidget {
  const Register_Login_View({super.key});

  @override
  State<Register_Login_View> createState() => _campusscoreState();
}

class _campusscoreState extends State<Register_Login_View> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _loading = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.firebase().signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home/', (_) => false);
      }
    } on GoogleSignInCancelledException {
    } on GenericAuthException {
      _showSnack("Google Sign-In failed. Try again.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Please enter email and password", Colors.red);
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.firebase().createUser(email: email, password: password);
      _showSnack("Registered successfully!", Colors.green);
      await AuthService.firebase().sendEmailVerification();
      _showSnack("Verification email sent!", Colors.green);
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VerifyEmailView()));
      }
    } on EmailAlreadyInUseException {
      try {
        await AuthService.firebase().logIn(email: email, password: password);
        await AuthService.firebase().getupdateduser();
        final user = AuthService.firebase().currentUser;
        if (user?.isEmailVeified ?? false) {
          _showSnack("Welcome back!", Colors.green);
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home/', (_) => false);
          }
        } else {
          await AuthService.firebase().Logout();
          _showSnack("Please verify your email first.", Colors.orange);
        }
      } on WrongPassAuthException {
        _showSnack("Incorrect password. Try again.", Colors.redAccent);
      } on GenericAuthException {
        _showSnack("Invalid credentials. Please try again.", Colors.redAccent);
      }
    } on WeakPassowrdExcetion {
      _showSnack("Password must be at least 6 characters.", Colors.redAccent);
    } on InvalidEmailException {
      _showSnack("Please enter a valid email.", Colors.redAccent);
    } catch (_) {
      _showSnack("Something went wrong. Try again.", Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 72),

            // campusscore Logo Container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                image: const DecorationImage(
                  image: AssetImage('assets/images/campusscore_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'CampusScore',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF6B00),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Safe rides for the people you love.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.black12,
                    thickness: 1,
                    indent: 24,
                    endIndent: 10,
                  ),
                ),
                Text(
                  'Login or Sign Up',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.black12,
                    thickness: 1,
                    indent: 10,
                    endIndent: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Email Input Box
            SizedBox(
              width: 350,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFFFF6B00),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Password Input Box
            SizedBox(
              width: 350,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _password,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFFF6B00),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Continuous Submit Button
            GestureDetector(
              onTap: _loading ? null : _handleSubmit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                width: _loading ? 56 : 350,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _loading
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  secondChild: const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.black12,
                    thickness: 1,
                    indent: 24,
                    endIndent: 10,
                  ),
                ),
                Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.black12,
                    thickness: 1,
                    indent: 10,
                    endIndent: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Google Button Setup
            GestureDetector(
              onTap: _loading ? null : _signInWithGoogle,
              child: Container(
                width: 350,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/image2.png',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────
// VERIFY EMAIL VIEW WITH campusscore DESIGN
// ─────────────────────────────────────────────────────────────────
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    await AuthService.firebase().getupdateduser();
    final user = AuthService.firebase().currentUser;
    if (user?.isEmailVeified ?? false) {
      _timer?.cancel();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home/', (_) => false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0EB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B00), width: 2),
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: Color(0xFFFF6B00),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check your inbox',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'We sent a verification link to your email. Click it to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFF6B00),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for verification...',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
