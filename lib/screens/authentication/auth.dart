import 'package:flutter/material.dart';

class AuthenticationScreen extends StatefulWidget {
  final Widget child;
  const AuthenticationScreen({super.key, required this.child});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(
      body: SafeArea(child: widget.child),
    );
  }
}
