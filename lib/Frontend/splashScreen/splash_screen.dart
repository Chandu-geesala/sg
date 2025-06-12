import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg/Frontend/auth_screens/auth_screen.dart';

import 'package:sg/home.dart';


class MysplashScreen extends StatefulWidget {
  const MysplashScreen({super.key});

  @override
  State<MysplashScreen> createState() => _MysplashScreenState();
}

class _MysplashScreenState extends State<MysplashScreen> {
  @override
  void initState() {
    super.initState();
    initTimer();
  }

  void initTimer() async {
    Timer(const Duration(seconds: 2), () async {
      // Check if the intro has been completed
      SharedPreferences prefs = await SharedPreferences.getInstance();



      // Check if the user is logged in
      User? user = FirebaseAuth.instance.currentUser;


        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LandingPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/logo.png'), // Display the image instead of Lottie
      ),
    );
  }
}
