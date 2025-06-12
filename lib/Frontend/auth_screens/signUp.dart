import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';

import '../../global/global_instances.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextEditingController = TextEditingController();
  bool isLoadingLocation = false;

  bool isLoadingSignUp = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(); // Initialize Firebase
  }






  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 50),
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                ),

                const SizedBox(height:10),
                _buildTextFieldContainer(
                  controller: nameController,
                  hintText: 'Name',
                  icon: Icons.account_circle,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                _buildTextFieldContainer(
                  controller: emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                  validator: (value) =>
                  value != null && value.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 20),
                _buildTextFieldContainer(
                  controller: phoneController,
                  hintText: 'Phone',
                  icon: Icons.phone,
                  validator: (value) =>
                  value != null && value.length >= 10 ? null : 'Enter a valid phone number',
                ),
                const SizedBox(height: 20),
                _buildTextFieldContainer(
                  controller: passwordController,
                  hintText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) =>
                  value != null && value.length >= 6 ? null : 'Password must be at least 6 characters',
                ),


                const SizedBox(height: 20),





                // Replace the existing location input container with this:
                _buildTextFieldContainer(
                  controller: locationTextEditingController,
                  hintText: 'Address',
                  icon: Icons.my_location,
                  validator: (value) => null, // Add validation if needed
                ),
                const SizedBox(height: 8),

// Replace the existing ElevatedButton with this styled container:
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isLoadingLocation = true;
                    });
                    try {
                      String address = await commonViewModel.getCurrentLocation();
                      setState(() {
                        locationTextEditingController.text = address;
                        isLoadingLocation = false;
                      });
                      _showMessage("Location fetched successfully");
                    } catch (e) {
                      setState(() {
                        isLoadingLocation = false;
                      });
                      String errorMessage = "Failed to get location";
                      if (e.toString().contains('denied')) {
                        errorMessage = "Location permission denied. Please enable location permission in settings.";
                      } else if (e.toString().contains('disabled')) {
                        errorMessage = "Location services are disabled. Please enable location services.";
                      } else if (e.toString().contains('permanently denied')) {
                        errorMessage = "Location permission permanently denied. Please enable it from app settings.";
                      }
                      _showMessage(errorMessage);
                      // Optional: Show dialog to guide user to settings
                      if (e.toString().contains('permanently denied')) {
                        _showLocationSettingsDialog();
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 70),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isLoadingLocation
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(255, 63, 111, 1),
                        ),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.red,
                        ),
                        SizedBox(width: 1),
                        Text(
                          'Get My Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),







                SizedBox(height: 23),





                // _buildTextFieldContainer(
                //   controller: confirmPasswordController,
                //   hintText: 'Confirm Password',
                //   icon: Icons.lock,
                //   obscureText: true,
                //   validator: (value) =>
                //   value == passwordController.text ? null : 'Passwords do not match',
                // ),
                // const SizedBox(height: 20),


                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isLoadingSignUp = true;
                    });
                    await authViewModel.validateSignUpForm(
                      passwordController.text.trim(),
                      //  confirmPasswordController.text.trim(),
                      nameController.text.trim(),
                      emailController.text.trim(),
                      phoneController.text.trim(),
                      locationTextEditingController.text.trim(),
                      context,
                    );
                    setState(() {
                      isLoadingSignUp = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: isLoadingSignUp
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(255, 63, 111, 1),
                      ),
                    )
                        : Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromRGBO(255, 63, 111, 1),
                      ),
                    ),
                  ),
                ),



                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Already a registered user?',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log In here',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
            'This app needs location permission to get your current address. '
                'Please go to Settings > Apps > Your App Name > Permissions and enable Location permission.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add Geolocator.openAppSettings(); here if you want to open settings directly
                // but you'll need to add that import: import 'package:geolocator/geolocator.dart';
                Geolocator.openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }



  Widget _buildTextFieldContainer({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),


      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: const Color.fromRGBO(251, 126, 24, 1.0),
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          icon: Icon(icon),
        ),
        validator: validator,
      ),
    );
  }
}