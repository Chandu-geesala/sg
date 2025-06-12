import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sg/global/global_instances.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg/home.dart';
import 'common_view_model.dart';
import 'package:sg/global/global_vars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AuthViewModel {
  Future<void> validateSignUpForm(
      String password,
      String name,
      String email,
      String phone,
      String location,
      BuildContext context) async {

    if (name.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        phone.isNotEmpty &&
        location.isNotEmpty) {

      commonViewModel.showSnackBar("Please Wait..", context);

      try {
        User? currentFirebaseUser =
        await createUserInFirebaseAuth(email, password, context);

        if (currentFirebaseUser != null) {
          await saveUserDataToFirestore(currentFirebaseUser, name, email,
              password, phone, location);

          // Verify data was saved
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(currentFirebaseUser.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            print("User data saved successfully:");
            print("Location: ${userData['location']}");

            Navigator.push(context, MaterialPageRoute(builder: (c) => HomePage()));
            commonViewModel.showSnackBar("Account Created Successfully", context);
          } else {
            throw Exception("Failed to save user data");
          }
        }
      } catch (e) {
        print("Sign up error: $e");
        commonViewModel.showSnackBar("Sign up failed: ${e.toString()}", context);
        FirebaseAuth.instance.signOut();
      }
    } else {
      commonViewModel.showSnackBar("Please fill all fields", context);
      return;
    }
  }



  Future<User?> createUserInFirebaseAuth(
      String email, String password, BuildContext context) async {
    User? currentFirebaseUser;

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      currentFirebaseUser = userCredential.user;
    } catch (e) {
      commonViewModel.showSnackBar(e.toString(), context);
    }

    return currentFirebaseUser;
  }

  Future<void> saveUserDataToFirestore(
      User currentFirebaseUser,
      String name,
      String email,
      String password,
      String phone,
      String location
      )

  async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentFirebaseUser.uid)
        .set({
      "uid": currentFirebaseUser.uid,
      "email": email,
      "name": name,
      "phone": phone,
      "location": location,
    });

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString("uid", currentFirebaseUser.uid);
    await sharedPreferences.setString("email", email);
    await sharedPreferences.setString("name", name);
    await sharedPreferences.setString("phone", phone);
    await sharedPreferences.setString("location", location);
  }


  validateSignInForm(String email, String password, BuildContext context) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      commonViewModel.showSnackBar("Checking credentials...", context);
      User? currentFirebaseUser = await loginUser(email, password, context);

      if (currentFirebaseUser != null) {
        String? userRole = await getUserRole(currentFirebaseUser);

        if (userRole == "user") {
          await readDataFromFirestoreAndSetDataLocally(currentFirebaseUser, context);
          Navigator.push(context, MaterialPageRoute(builder: (c) => HomePage()));
        } else {
          commonViewModel.showSnackBar("Invalid credentials for user.", context);
          FirebaseAuth.instance.signOut();
        }
      }
    } else {
      commonViewModel.showSnackBar("Password and Email are required", context);
      return;
    }
  }

  Future<User?> loginUser(String email, String password, BuildContext context) async {
    User? currentFirebaseUser;

    try {
      UserCredential valueAuth = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentFirebaseUser = valueAuth.user;
    } catch (error) {
      commonViewModel.showSnackBar(error.toString(), context);
      return null;
    }

    if (currentFirebaseUser == null) {
      await FirebaseAuth.instance.signOut();
      return null;
    }

    return currentFirebaseUser;
  }

  Future<String?> getUserRole(User currentFirebaseUser) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentFirebaseUser.uid)
        .get();

    if (userSnapshot.exists) {
      return "user";
    }



    return null;
  }

  readDataFromFirestoreAndSetDataLocally(User? currentFirebaseUser, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentFirebaseUser!.uid)
        .get()
        .then((dataSnapshot) async {
      if (dataSnapshot.exists) {

          await sharedPreferences!.setString("uid", currentFirebaseUser.uid);
          await sharedPreferences!.setString("email", dataSnapshot.data()!["email"]);
          await sharedPreferences!.setString("name", dataSnapshot.data()!["name"]);
          await sharedPreferences!.setString("phone", dataSnapshot.data()!["phone"]);
          await sharedPreferences!.setString("location", dataSnapshot.data()!["location"]);

      } else {
        commonViewModel.showSnackBar("This user record does not exist", context);
        FirebaseAuth.instance.signOut();
        return;
      }
    });
  }
}

