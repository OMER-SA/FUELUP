import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:diet_app/modals/user.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final Authentication _authentication = Authentication();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _restaurantNameController =
      TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final DefaultColors defaultColors = DefaultColors();
  bool loading = false;
  bool obsecureText = true;

  //Drop Down Menu
  String _selectedRole = 'No Role Selected';
  List<DropdownMenuItem> roles = const <DropdownMenuItem>[
    DropdownMenuItem(
      value: "No Role Selected",
      child: Text("No Role Selected"),
    ),
    DropdownMenuItem(
      value: "cheff",
      child: Text("Chef"),
    ),
    DropdownMenuItem(
      value: "customer",
      child: Text("Customer"),
    ),
  ];

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
                    height: 200,
                    'assets/Authentication/undraw_breakfast_psiw (2).svg'),
                const SizedBox(
                  height: 50,
                ),
                if (_selectedRole == "customer")
                  Row(
                    children: [
                      Flexible(
                        child: TextFormField(
                          controller: _firstNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "First Name is required";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: "Enter First Name",
                            labelText: 'First Name',
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(
                        child: TextFormField(
                          controller: _lastNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Last Name is required";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: "Enter Last Name",
                            labelText: 'Last Name',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_selectedRole == "cheff")
                  TextFormField(
                    controller: _restaurantNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Kitchen Name is required";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: "Enter name of your kitchen or restaurant",
                      labelText: 'Kitchen/Restaurant name',
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (value.length != 11) {
                      return 'Phone number should be 11 digits';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 20,
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
                  height: 20,
                ),
                DropdownButtonFormField(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    iconSize: 28,
                    iconEnabledColor: defaultColors.primaryColor,
                    decoration: const InputDecoration(labelText: "Role"),
                    validator: (value) {
                      if (value == null || value == 'No Role Selected') {
                        return "Select your role";
                      }
                      return null;
                    },
                    hint: const Text("Plz Select A Desired Role"),
                    borderRadius: BorderRadius.circular(4),
                    value: _selectedRole,
                    items: roles,
                    onChanged: (value) {
                      if (value is String) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    }),
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
                                    ? Colors.red
                                    : null;
                              }),
                              backgroundColor: WidgetStatePropertyAll(
                                  defaultColors.primaryColor)),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              await _authentication
                                  .register(
                                      SingUpDto(
                                          kitchenName: _restaurantNameController
                                              .text
                                              .trim(),
                                          firstName:
                                              _firstNameController.text.trim(),
                                          lastName:
                                              _lastNameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          password:
                                              _passwordController.text.trim(),
                                          phone: _phoneNumberController.text
                                              .trim(),
                                          role: _selectedRole),
                                      context)
                                  .then((value) {
                                print("Sign IN Valuee: $value");
                                if (context.mounted) {
                                  context.read<UserIdProvider>().setUser(
                                      context: context,
                                      id: value.toString(),
                                      loadingFalse: () {
                                        setState(() => loading = false);
                                      });
                                }
                              }).catchError((error) {
                                FlutterToast.showToast(
                                    error, defaultColors.redColor);
                                setState(() => loading = false);
                              }).whenComplete(() {
                                setState(() {
                                  loading = false;
                                });
                              });
                              // signUpBottomSheet(context);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Register Account',
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
                    const TextSpan(text: "Already have an account? "),
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
                              'Login',
                              style:
                                  TextStyle(color: defaultColors.primaryColor),
                            ),
                            onPressed: () {
                              context.go('/auth/login');
                            },
                          ),
                        )),
                  ],
                ))
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
    _restaurantNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
