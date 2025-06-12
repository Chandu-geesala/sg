import 'package:flutter/material.dart';
import 'package:sg/global/global_instances.dart';
import 'package:sg/Frontend/auth_screens/signUp.dart';
import 'package:sg/Frontend/forgot_password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool isExistingUser = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isPasswordVisible = false;
  String countryCode = '+91';
  bool isPhoneValidAndVerified = false; // New variable


  @override
  void initState() {
    super.initState();
    phoneController.addListener(_validatePhone); // Listen to phone field
  }

  @override
  void dispose() {
    phoneController.removeListener(_validatePhone);
    phoneController.dispose();
    super.dispose();
  }


  void _validatePhone() {
    // Simulate validation and verification check
    setState(() {
      isPhoneValidAndVerified =
          phoneController.text.length == 10; // Example check
    });
  }


  void _loginUser() async {
    if (_formkey.currentState!.validate()) {
      if (isExistingUser) {
        authViewModel.validateSignInForm(
          emailController.text.trim(),
          passwordController.text.trim(),
          context,
        );
      }
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width,
          height: MediaQuery
              .of(context)
              .size
              .height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.white,
                Colors.green.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
              Image.asset(
                'assets/logo.png',
                width: 150,
                height: 150,
              ),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 28,
                  fontFamily: "Noto",
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "sign in to access your account",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: "Noto",
                ),
              ),
              const SizedBox(height: 30),

              // Toggle button


              _buildLoginFields(),
              // Display login fields based on selection



              // Login button


              isExistingUser
                  ? GestureDetector(
                onTap: _loginUser,
                child: _buildLoginButton("LOGIN", isEnabled: true),
              )
                  : GestureDetector(
                onTap: () {

                },
                child: _buildLoginButton(
                  "GET OTP",
                  isEnabled: true,
                ),
              ),



              const SizedBox(height: 10),
              const Text(
                "Or",
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
              const SizedBox(height: 10),

              // Sign-Up Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[


                    Text(
                      'New Member?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                        fontFamily: 'Sathoshi',  // Note: Font family name should be in quotes
                      ),
                    ),



                    SizedBox(width: 5),
                    Text(
                      'Register Now',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontFamily: "Noto",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      width: 230,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orange, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isExistingUser ? Alignment.centerLeft : Alignment
                .centerRight,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isExistingUser = true),
                  child: Center(
                    child: Text(
                      "Email",
                      style: TextStyle(
                        color: isExistingUser ? Colors.black : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isExistingUser = false),
                  child: Center(
                    child: Text(
                      "Phone",
                      style: TextStyle(
                        color: !isExistingUser ? Colors.black : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFields() {
    return Container(
      key: const ValueKey("login"),
      width: 300,
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formkey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextFieldContainer(
              controller: emailController,
              hintText: 'Enter your  Email',
              icon: Icons.email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _buildTextFieldContainer(
              controller: passwordController,
              hintText: 'Password',
              icon: Icons.lock,
              obscureText: !isPasswordVisible,
              isPassword: true,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      fontFamily: "Noto",

                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldContainer({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: 290,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontWeight: FontWeight.w300,
            fontFamily: "Noto",
            color: Colors.black,
          ),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          )
              : null,
        ),
      ),
    );
  }






  Widget _buildLoginButton(String buttonText, {required bool isEnabled}) {
    return Container(
      width: 160,
      height: 50,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.orange : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          buttonText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: "Noto",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}








