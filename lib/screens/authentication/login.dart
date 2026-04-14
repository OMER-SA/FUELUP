import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:diet_app/firebase/quota_guard.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/quota_limit_notifier.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  DefaultColors defaultColors = DefaultColors();
  final Authentication _authentication = Authentication();

  bool loading = false;
  bool obsecureText = true;

  toggleShowPassword() {
    setState(() {
      obsecureText = !obsecureText;
    });
  }

  loadingFalse() {
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                    height: 300,
                    'assets/Authentication/undraw_cooking_p7m1.svg'),
                const SizedBox(
                  height: 70,
                ),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
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
                TextFormField(
                  obscureText: obsecureText,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 8) {
                      return "Password should atleast 8 character long";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      hintText: "Enter Your Password",
                      labelText: 'Password',
                      suffixIcon: InkWell(
                        onTap: () {
                          setState(() {
                            obsecureText = !obsecureText;
                          });
                        },
                        child: obsecureText
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off),
                      )),
                ),
                const SizedBox(
                  height: 10,
                ),

                // Forgot Password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.push('/auth/forgotPassword');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: defaultColors.primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
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
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                              });
                              await _authentication
                                  .login(_emailController.text.trim(),
                                      _passwordController.text.trim())
                                  .then((value) async {
                                if (context.mounted) {
                                  await context.read<UserIdProvider>().setUser(
                                      context: context,
                                      id: value.toString(),
                                      loadingFalse: () {
                                        setState(() => loading = false);
                                      });
                                }
                              }).catchError((error) {
                                QuotaGuard.instance.markIfQuotaExceeded(
                                  error,
                                  operation: 'login.screen',
                                );
                                if (context.mounted) {
                                  QuotaLimitNotifier.showIfNeeded(context);
                                }
                                FlutterToast.showToast(
                                    error.toString(), defaultColors.redColor);
                                setState(() {
                                  loading = false;
                                });
                              }).whenComplete(() {});
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Login to Account',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          )),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text.rich(TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(text: "Didn't have an account? "),
                    WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SizedBox(
                          width: 120,
                          height: 50,
                          child: MaterialButton(
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            child: Text(
                              'Register',
                              style:
                                  TextStyle(color: defaultColors.primaryColor),
                            ),
                            onPressed: () {
                              context.go('/auth/signUp');
                            },
                          ),
                        )),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
