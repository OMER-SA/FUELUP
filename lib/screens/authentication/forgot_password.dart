import 'package:diet_app/components/auth/email_send_for_reset_password.dart';
import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final Authentication _authentication = Authentication();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DefaultColors defaultColors = DefaultColors();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/Authentication/undraw_safe_re_kiil.svg',
              fit: BoxFit.cover,
              height: 250,
              width: double.infinity,
            ),
            const SizedBox(
              height: 50,
            ),
            Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is required";
                        }
                        String pattern =
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                        RegExp regex = RegExp(pattern);
                        if (!regex.hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "Enter Your Email",
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: loading
                          ? const LoadingSpinner()
                          : ElevatedButton(
                              style: ButtonStyle(
                                  overlayColor:
                                      WidgetStateProperty.resolveWith((state) {
                                    return state.contains(WidgetState.pressed)
                                        ? Colors.grey
                                        : null;
                                  }),
                                  backgroundColor: WidgetStatePropertyAll(
                                      defaultColors.primaryColor)),
                              onPressed: _forgotPassword,
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              )),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }

  void _forgotPassword() async {
    setState(() {
      loading = true;
    });
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      FlutterToast.showToast("Please enter your email first", Colors.red);
      setState(() => loading = false);
      return;
    }
    try {
      final value = await _authentication.sendPasswordResetEmail(email);
      if (mounted) {
        emailSentForResetPasswordDialog(context, value);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} — ${e.message}');
      FlutterToast.showToast(_friendlyAuthError(e.code), defaultColors.redColor);
    } catch (e) {
      debugPrint('Auth error (non-Firebase): $e');
      FlutterToast.showToast(e.toString(), defaultColors.redColor);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled. Contact support.';
      default:
        return 'Sign in failed ($code). Please try again.';
    }
  }
}
