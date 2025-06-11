// import 'package:flutter/material.dart';
// import 'Package:http/http.dart';
// import 'dart:convert';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//
//   Map<String, dynamic>? disasterData;
//   bool isLoading = false;
//   String? errorMessage;
//
//   final String apiUrl = 'https:google.com';
//
//   @override
//   void initState(){
//     super.initState();
//     fetchDisasterData();
//   }
//
//
//   Future<void> fetchDisasterData() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       final response = await get(Uri.parse(apiUrl));
//
//       if (response.statusCode == 200) {
//         setState(() {
//           disasterData = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load data');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
