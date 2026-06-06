import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:maintenance_genie/core/utils/input_validator.dart';
import 'package:maintenance_genie/shared/app_toast.dart';
import 'package:maintenance_genie/shared/common_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../shared/custom_text_field.dart';
import '../../../view_models/login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs(String email, String password) {
    if (email.isEmpty) {
      AppToast.showToast('Please enter your email', gravity: ToastGravity.TOP);
      return false;
    }

    if (InputValidators.emailValidator(email) == false) {
      AppToast.showToast(
        'Please enter a valid email',
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    if (password.isEmpty) {
      AppToast.showToast(
        'Please enter your password',
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    if (password.length < 6) {
      AppToast.showToast(
        'Password must be at least 6 characters',
        gravity: ToastGravity.TOP,
      );
      return false;
    }

    return true;
  }

  void _handleLogin(LoginProvider provider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_validateInputs(email, password)) {
      return;
    }

    final result = await provider.login(email: email, password: password);

    if (!mounted) return;

    if (result) {
      Navigator.pushReplacementNamed(context, RouteName.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 60.h,
                      width: 60.w,
                      child: Image.asset("assets/icons/app_logo.png"),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Maintenance\nGenie",
                      style: TextStyle(
                        color: Color(0xff023455),
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const Text(
                  "Log in to Your Account",
                  style: TextStyle(
                    color: Color(0xff1D1F2C),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your email and password to log in\nto your account",
                  style: TextStyle(
                    color: Color(0xff4A4C56),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Email",
                  style: TextStyle(
                    color: Color(0xff1D1F2C),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _emailController,
                  hintText: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                const Text(
                  "Password",
                  style: TextStyle(
                    color: Color(0xff1D1F2C),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  obscureText: loginProvider.isPasswordVisible,
                  suffixIcon: IconButton(
                    onPressed: () => context
                        .read<LoginProvider>()
                        .togglePasswordVisibility(),
                    icon: Icon(
                      loginProvider.isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, RouteName.forgetPassword);
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Consumer<LoginProvider>(
                  builder: (_, provider, _) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                              text: "Log In",
                              onPressed: () => _handleLogin(provider),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xff1D1F2C),
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, RouteName.signup);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
