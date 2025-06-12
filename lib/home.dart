
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'Backend/auth_view_model.dart';
import 'Frontend/splashScreen/splash_screen.dart';
import 'global/global_instances.dart';
import 'global/global_vars.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? initialDisasterData;
  final bool isFromNotification;

  const HomePage({
    Key? key,
    this.initialDisasterData,
    this.isFromNotification = false,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? disasterData;
  bool isLoading = false;
  String? errorMessage;
  bool _isFromNotification = false;
  final AuthViewModel _authService = AuthViewModel();
  // Your API endpoint
  final String apiUrl = "https://chandugeesala0-random.hf.space/anything";

  @override
  void initState() {
    super.initState();
    _isFromNotification = widget.isFromNotification;

    // If app opened from notification with data
    if (widget.initialDisasterData != null && widget.initialDisasterData!.isNotEmpty) {
      print('Loading disaster data from notification: ${widget.initialDisasterData}');

      // Show notification indicator
      if (_isFromNotification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNotificationIndicator();
        });
      }

      // Process notification data
      _processNotificationData(widget.initialDisasterData!);
    } else {
      fetchDisasterData();
    }
  }

  void _processNotificationData(Map<String, dynamic> notificationData) {
    setState(() {
      isLoading = true;
    });

    try {
      // Improved data processing with better error handling
      Map<String, dynamic> parsedData = _parseNotificationData(notificationData);

      print('Successfully processed notification data: $parsedData');

      // Handle different notification data scenarios
      if (_isValidDisasterData(parsedData)) {
        setState(() {
          disasterData = parsedData;
          isLoading = false;
          errorMessage = null;
        });
      } else if (parsedData.containsKey('disaster_id')) {
        fetchDisasterDataById(parsedData['disaster_id'].toString());
      } else if (parsedData.containsKey('api_url')) {
        fetchDisasterDataFromUrl(parsedData['api_url'].toString());
      } else {
        // Even if data doesn't match expected format, try to display it
        setState(() {
          disasterData = parsedData;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      print('Error processing notification data: $e');
      setState(() {
        errorMessage = 'Failed to process notification data: ${e.toString()}';
        isLoading = false;
      });
      // Fallback to regular API call
      fetchDisasterData();
    }
  }

  // Improved data parsing method
  Map<String, dynamic> _parseNotificationData(Map<String, dynamic> rawData) {
    Map<String, dynamic> parsedData = {};

    for (String key in rawData.keys) {
      dynamic value = rawData[key];

      try {
        if (value == null) {
          parsedData[key] = null;
          continue;
        }

        // If already proper type, keep as is
        if (value is! String) {
          parsedData[key] = value;
          continue;
        }

        String stringValue = value.toString().trim();

        // Handle empty strings
        if (stringValue.isEmpty) {
          parsedData[key] = '';
          continue;
        }

        // Parse different data types
        parsedData[key] = _parseStringValue(stringValue);

      } catch (e) {
        print('Error parsing key "$key" with value "$value": $e');
        // If parsing fails, keep the original string value
        parsedData[key] = value.toString();
      }
    }

    return parsedData;
  }

  // Helper method to parse string values into appropriate types
  dynamic _parseStringValue(String value) {
    // Handle boolean strings
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Handle null string
    if (value.toLowerCase() == 'null') return null;

    // Try to parse JSON strings (arrays/objects)
    if ((value.startsWith('[') && value.endsWith(']')) ||
        (value.startsWith('{') && value.endsWith('}'))) {
      try {
        return jsonDecode(value);
      } catch (e) {
        print('Failed to parse JSON string: $value');
        return value; // Return as string if JSON parsing fails
      }
    }

    // Try to parse numbers
    // Integer check
    if (RegExp(r'^-?\d+$').hasMatch(value)) {
      try {
        int intValue = int.parse(value);
        // Check if it's within safe range
        if (intValue >= -2147483648 && intValue <= 2147483647) {
          return intValue;
        }
      } catch (e) {
        print('Failed to parse int: $value');
      }
    }

    // Double/Float check
    if (RegExp(r'^-?\d*\.?\d+([eE][+-]?\d+)?$').hasMatch(value)) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Failed to parse double: $value');
      }
    }

    // If nothing else works, return as string
    return value;
  }

  // Check if the parsed data contains valid disaster information
  bool _isValidDisasterData(Map<String, dynamic> data) {
    // Basic validation - check for key disaster data fields
    return data.containsKey('disaster_type') ||
        data.containsKey('location') ||
        data.containsKey('severity') ||
        data.containsKey('alert_id');
  }

  void _showNotificationIndicator() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 8),
            Text('Opened from disaster alert notification'),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> fetchDisasterDataById(String disasterId) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
          Uri.parse('$apiUrl?disaster_id=$disasterId')
      );

      if (response.statusCode == 200) {
        setState(() {
          disasterData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        // Fallback to regular API call
        fetchDisasterData();
      }
    } catch (e) {
      print('Error fetching disaster by ID: $e');
      fetchDisasterData(); // Fallback
    }
  }

  Future<void> fetchDisasterDataFromUrl(String url) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          disasterData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        fetchDisasterData(); // Fallback
      }
    } catch (e) {
      print('Error fetching disaster from URL: $e');
      fetchDisasterData(); // Fallback
    }
  }

  Future<void> fetchDisasterData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          disasterData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('🚨 Disaster Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 28),

            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate to the SplashScreen after sign-out
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MysplashScreen()),
                      (route) => false,
                );
              } catch (e) {
                print('Error signing out: $e');
                // Optionally, show an error message
              }
            },

            tooltip: 'Log Out',
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : errorMessage != null
          ? _buildErrorWidget()
          : disasterData != null
          ? _buildDisasterContent()
          : _buildNoDataWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Fetching disaster data...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: fetchDisasterData,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber, size: 80, color: Colors.orange),
          SizedBox(height: 20),
          Text(
            'No disaster data available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: fetchDisasterData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterContent() {
    return RefreshIndicator(
      onRefresh: fetchDisasterData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertHeader(),
            SizedBox(height: 20),
            _buildSOSEmergencySection(),
            SizedBox(height:20),
            _buildBasicInfo(),
            SizedBox(height: 20),
            _buildEmergencyContacts(),
            SizedBox(height: 20),
            _buildSafetyInstructions(),
            SizedBox(height: 20),
            _buildDisasterSpecificInfo(),
            SizedBox(height: 20),
            _buildAdditionalInfo(),
            SizedBox(height: 20),
            _buildMetaInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHeader() {
    String disasterType = _getStringValue(disasterData?['disaster_type']) ?? 'Unknown';
    String severity = _getStringValue(disasterData?['severity']) ?? 'Unknown';
    String alertColor = _getStringValue(disasterData?['alert_color']) ?? 'Red';

    Color headerColor = _getAlertColor(alertColor);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: headerColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🚨 ${_getStringValue(disasterData?['disaster_name']) ?? 'DISASTER ALERT'}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '$severity Severity',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getStringValue(disasterData?['location']) ?? 'Unknown Location',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSOSEmergencySection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pulsing effect
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'EMERGENCY ACTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Emergency buttons grid
          Row(
            children: [

              Expanded(
                child: _buildSOSButton(
                  icon: Icons.my_location,
                  label: 'Share\nLocation',
                  onPressed: () => _shareLocation(),
                  backgroundColor: Colors.green.withOpacity(0.9),
                ),
              ),

              SizedBox(width: 12),
              Expanded(
                child: _buildSOSButton(
                  icon: Icons.help,
                  label: 'Need Help',
                  onPressed: () => _requestHelp(),
                  backgroundColor: Colors.orange.withOpacity(0.3),
                ),
              ),


            ],
          ),
          SizedBox(height: 12),

          // Quick access emergency number
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'National Emergency: 112',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Emergency action methods
  void _callEmergencyServices() {
    // Get primary helpline or default emergency number
    String emergencyNumber = _getStringValue(disasterData?['primary_helpline']) ?? '112';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: Colors.red[600]),
              SizedBox(width: 8),
              Text('Emergency Call'),
            ],
          ),
          content: Text('Do you want to call $emergencyNumber?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Launch phone dialer
                _makePhoneCall(emergencyNumber);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: Text('Call Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }






// Emergency location sharing method
  Future<void> _shareLocation() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Getting your location...'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          duration: Duration(seconds: 3),
        ),
      );

      // Get current location
      String locationAddress = await commonViewModel.getCurrentLocation();
      Position? currentPosition = position; // From global_vars

      // Get user details from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('uid');
      String? userName = prefs.getString('name');
      String? userEmail = prefs.getString('email');
      String? userPhone = prefs.getString('phone');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Prepare location request data
      Map<String, dynamic> locationRequestData = {
        'user_id': userId,
        'user_name': userName ?? 'Unknown',
        'user_email': userEmail ?? 'Unknown',
        'user_phone': userPhone ?? 'Unknown',
        'latitude': currentPosition?.latitude ?? 0.0,
        'longitude': currentPosition?.longitude ?? 0.0,
        'address': locationAddress,
        'request_type': 'location_share',
        'disaster_alert_id': disasterData?['alert_id'] ?? 'unknown',
        'disaster_type': disasterData?['disaster_type'] ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'urgency': 'high',
        'notes': 'Emergency location shared from disaster alert app',
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('location_requests')
          .add(locationRequestData);

      // Also store in user's emergency_requests subcollection for easy tracking
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_requests')
          .add({
        ...locationRequestData,
        'request_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Location shared successfully'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error sharing location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share location: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// Request help method with backend functionality
  Future<void> _requestHelp() async {
    try {
      // Get user details
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('uid');
      String? userName = prefs.getString('name');
      String? userEmail = prefs.getString('email');
      String? userPhone = prefs.getString('phone');
      String? userLocation = prefs.getString('location');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What kind of help do you need?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildHelpOption(Icons.medical_services, 'Medical Emergency', Colors.red, 'medical', userId!, userName!, userEmail!, userPhone!, userLocation!),
              _buildHelpOption(Icons.restaurant, 'Food & Water', Colors.orange, 'food_water', userId, userName, userEmail, userPhone, userLocation),
              _buildHelpOption(Icons.home, 'Shelter', Colors.blue, 'shelter', userId, userName, userEmail, userPhone, userLocation),
              _buildHelpOption(Icons.directions_car, 'Transportation', Colors.green, 'transportation', userId, userName, userEmail, userPhone, userLocation),
              _buildHelpOption(Icons.help, 'General Help', Colors.purple, 'general', userId, userName, userEmail, userPhone, userLocation),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error requesting help: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open help request: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

// Updated help option builder with backend functionality
  Widget _buildHelpOption(IconData icon, String label, Color color, String helpType,
      String userId, String userName, String userEmail, String userPhone, String userLocation) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () async {
            Navigator.pop(context);
            await _submitHelpRequest(helpType, label, userId, userName, userEmail, userPhone, userLocation, color);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Submit help request to Firestore
  Future<void> _submitHelpRequest(String helpType, String helpLabel, String userId,
      String userName, String userEmail, String userPhone, String userLocation, Color color) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Submitting help request...'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          duration: Duration(seconds: 2),
        ),
      );

      // Get current location if possible
      String currentLocationAddress = userLocation;
      double? latitude;
      double? longitude;

      try {
        String freshLocation = await commonViewModel.getCurrentLocation();
        Position? currentPosition = position;
        currentLocationAddress = freshLocation;
        latitude = currentPosition?.latitude;
        longitude = currentPosition?.longitude;
      } catch (e) {
        print('Could not get fresh location, using stored location: $e');
      }

      Map<String, dynamic> helpRequestData = {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'user_stored_location': userLocation,
        'current_location': currentLocationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'help_type': helpType,
        'help_label': helpLabel,
        'disaster_alert_id': disasterData?['alert_id'] ?? 'unknown',
        'disaster_type': disasterData?['disaster_type'] ?? 'unknown',
        'disaster_severity': disasterData?['severity'] ?? 'unknown',
        'request_type': 'help_request',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'urgency': _getHelpUrgency(helpType),
        'notes': 'Help requested from disaster alert app',
      };

      // Store in main help_requests collection
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('help_requests')
          .add(helpRequestData);

      // Store in user's emergency_requests subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_requests')
          .add({
        ...helpRequestData,
        'request_id': docRef.id,
      });

      // Update user's emergency status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'emergency_status': 'help_requested',
        'last_help_request': FieldValue.serverTimestamp(),
        'help_type': helpType,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Help request Sent')),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error submitting help request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit help request: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// Get urgency level based on help type
  String _getHelpUrgency(String helpType) {
    switch (helpType) {
      case 'medical':
        return 'critical';
      case 'shelter':
        return 'high';
      case 'food_water':
        return 'medium';
      case 'transportation':
        return 'medium';
      case 'general':
        return 'low';
      default:
        return 'medium';
    }
  }

// Mark as safe functionality
  Future<void> _markAsSafe() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('uid');
      String? userName = prefs.getString('name');
      String? userEmail = prefs.getString('email');
      String? userPhone = prefs.getString('phone');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current location
      String locationAddress = await commonViewModel.getCurrentLocation();
      Position? currentPosition = position;

      Map<String, dynamic> safetyCheckData = {
        'user_id': userId,
        'user_name': userName ?? 'Unknown',
        'user_email': userEmail ?? 'Unknown',
        'user_phone': userPhone ?? 'Unknown',
        'latitude': currentPosition?.latitude ?? 0.0,
        'longitude': currentPosition?.longitude ?? 0.0,
        'address': locationAddress,
        'status': 'safe',
        'disaster_alert_id': disasterData?['alert_id'] ?? 'unknown',
        'disaster_type': disasterData?['disaster_type'] ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': 'Marked as safe from disaster alert app',
      };

      // Store safety check
      await FirebaseFirestore.instance
          .collection('safety_checks')
          .add(safetyCheckData);

      // Update user status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'safety_status': 'safe',
        'last_safety_check': FieldValue.serverTimestamp(),
        'current_disaster_status': 'safe',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('You\'ve been marked as safe! Your contacts have been notified.'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error marking as safe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as safe: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

// Enhanced phone call method
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        // Log the emergency call
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('uid');

        if (userId != null) {
          await FirebaseFirestore.instance.collection('emergency_calls').add({
            'user_id': userId,
            'phone_number': phoneNumber,
            'disaster_alert_id': disasterData?['alert_id'] ?? 'unknown',
            'timestamp': FieldValue.serverTimestamp(),
            'call_type': 'emergency',
          });
        }
      } else {
        throw Exception('Could not launch phone app');
      }
    } catch (e) {
      print('Error making phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make call: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

// Get user emergency history
  Future<List<Map<String, dynamic>>> getUserEmergencyHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('uid');

      if (userId == null) return [];

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_requests')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();

    } catch (e) {
      print('Error getting emergency history: $e');
      return [];
    }
  }


  Widget _buildBasicInfo() {
    return _buildCard(
      title: 'Alert Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Alert ID', disasterData?['alert_id']),
        _buildInfoRow('Status', disasterData?['status']),
        _buildInfoRow('Issued At', _formatDateTime(_getStringValue(disasterData?['issued_at']))),
        if (disasterData?['expires_at'] != null)
          _buildInfoRow('Expires At', _formatDateTime(_getStringValue(disasterData?['expires_at']))),
        if (disasterData?['urgency'] != null)
          _buildInfoRow('Urgency', disasterData?['urgency']),
        _buildInfoRow('Affected People', '${disasterData?['affected_people'] ?? 'Unknown'}'),
        if (disasterData?['evacuation_status'] != null)
          _buildInfoRow('Evacuation', disasterData?['evacuation_status']),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    List<dynamic> emergencyContacts = _getListValue(disasterData?['emergency_contacts']);
    String? primaryHelpline = _getStringValue(disasterData?['primary_helpline']);

    return _buildCard(
      title: 'Emergency Contacts',
      icon: Icons.phone,
      children: [
        if (primaryHelpline != null && primaryHelpline.isNotEmpty)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.phone, color: Colors.red[600]),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Primary Helpline: $primaryHelpline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (primaryHelpline != null && primaryHelpline.isNotEmpty) SizedBox(height: 10),
        ...emergencyContacts.map((contact) =>
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.local_phone, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Emergency: ${_getStringValue(contact)}',
                        style: TextStyle(fontSize: 16)
                    ),
                  ),
                ],
              ),
            ),
        ).toList(),
        if (disasterData?['additional_helplines'] != null)
          ..._buildAdditionalHelplines(),
      ],
    );
  }

  List<Widget> _buildAdditionalHelplines() {
    var additionalHelplines = disasterData?['additional_helplines'];

    if (additionalHelplines is Map<String, dynamic>) {
      return additionalHelplines.entries.map((entry) =>
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.support_agent, size: 20, color: Colors.blue[600]),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '${entry.key.toUpperCase()}: ${_getStringValue(entry.value)}',
                      style: TextStyle(fontSize: 16)
                  ),
                ),
              ],
            ),
          ),
      ).toList();
    }

    return [];
  }

  Widget _buildSafetyInstructions() {
    List<dynamic> instructions = _getListValue(disasterData?['safety_instructions']);

    return _buildCard(
      title: 'Safety Instructions',
      icon: Icons.shield,
      children: [
        ...instructions.asMap().entries.map((entry) =>
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStringValue(entry.value) ?? '',
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ).toList(),
      ],
    );
  }

  // Improved safe getters with better type handling
  bool _getBoolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) return value != 0;
    return false;
  }

  String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  int _getIntValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _getDoubleValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  List<dynamic> _getListValue(dynamic value) {
    if (value is List) return value;
    if (value is String && value.isNotEmpty) {
      try {
        var decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (e) {
        // If it's a comma-separated string, split it
        if (value.contains(',')) {
          return value.split(',').map((s) => s.trim()).toList();
        }
        return [value]; // Return as single item list
      }
    }
    return [];
  }

  Widget _buildDisasterSpecificInfo() {
    String disasterType = _getStringValue(disasterData?['disaster_type']) ?? '';

    List<Widget> specificInfo = [];

    switch (disasterType.toLowerCase()) {
      case 'earthquake':
        if (disasterData?['magnitude'] != null)
          specificInfo.add(_buildInfoRow('Magnitude', '${_getDoubleValue(disasterData?['magnitude'])}'));
        if (disasterData?['depth_km'] != null)
          specificInfo.add(_buildInfoRow('Depth', '${_getDoubleValue(disasterData?['depth_km'])} km'));
        if (disasterData?['tsunami_risk'] != null)
          specificInfo.add(_buildInfoRow('Tsunami Risk', _getStringValue(disasterData?['tsunami_risk'])));
        if (disasterData?['aftershock_warning'] != null)
          specificInfo.add(_buildInfoRow('Aftershock Warning',
              _getBoolValue(disasterData?['aftershock_warning']) ? 'Yes' : 'No'));
        if (disasterData?['epicenter_distance'] != null)
          specificInfo.add(_buildInfoRow('Epicenter Distance', _getStringValue(disasterData?['epicenter_distance'])));
        break;

      case 'flood':
        if (disasterData?['water_level'] != null)
          specificInfo.add(_buildInfoRow('Water Level', _getStringValue(disasterData?['water_level'])));
        if (disasterData?['dam_status'] != null)
          specificInfo.add(_buildInfoRow('Dam Status', _getStringValue(disasterData?['dam_status'])));
        if (disasterData?['boat_rescue_available'] != null)
          specificInfo.add(_buildInfoRow('Boat Rescue',
              _getBoolValue(disasterData?['boat_rescue_available']) ? 'Available' : 'Not Available'));
        break;

      case 'cyclone':
        if (disasterData?['wind_speed_kmh'] != null)
          specificInfo.add(_buildInfoRow('Wind Speed', '${_getIntValue(disasterData?['wind_speed_kmh'])} km/h'));
        if (disasterData?['storm_surge_height'] != null)
          specificInfo.add(_buildInfoRow('Storm Surge', _getStringValue(disasterData?['storm_surge_height'])));
        if (disasterData?['expected_landfall'] != null)
          specificInfo.add(_buildInfoRow('Expected Landfall', _formatDateTime(_getStringValue(disasterData?['expected_landfall']))));
        break;

      case 'wildfire':
        if (disasterData?['fire_spread_rate'] != null)
          specificInfo.add(_buildInfoRow('Spread Rate', _getStringValue(disasterData?['fire_spread_rate'])));
        if (disasterData?['smoke_direction'] != null)
          specificInfo.add(_buildInfoRow('Smoke Direction', _getStringValue(disasterData?['smoke_direction'])));
        if (disasterData?['containment_percentage'] != null)
          specificInfo.add(_buildInfoRow('Containment', '${_getIntValue(disasterData?['containment_percentage'])}%'));
        break;

      case 'heatwave':
        if (disasterData?['heat_index'] != null)
          specificInfo.add(_buildInfoRow('Heat Index', '${_getIntValue(disasterData?['heat_index'])}°C'));
        if (disasterData?['uv_index'] != null)
          specificInfo.add(_buildInfoRow('UV Index', '${_getIntValue(disasterData?['uv_index'])}'));
        if (disasterData?['cooling_centers_open'] != null)
          specificInfo.add(_buildInfoRow('Cooling Centers', '${_getIntValue(disasterData?['cooling_centers_open'])} open'));
        break;

      case 'tsunami':
        if (disasterData?['estimated_wave_height'] != null)
          specificInfo.add(_buildInfoRow('Wave Height', _getStringValue(disasterData?['estimated_wave_height'])));
        if (disasterData?['estimated_arrival_time'] != null)
          specificInfo.add(_buildInfoRow('Arrival Time', _formatDateTime(_getStringValue(disasterData?['estimated_arrival_time']))));
        break;
    }

    if (specificInfo.isEmpty) return SizedBox.shrink();

    return _buildCard(
      title: '${_getStringValue(disasterData?['disaster_name']) ?? 'Disaster'} Details',
      icon: _getDisasterIcon(disasterType),
      children: specificInfo,
    );
  }





  Widget _buildAdditionalInfo() {
    List<Widget> additionalWidgets = [];

    if (disasterData?['relief_centers'] != null) {
      additionalWidgets.add(_buildInfoRow('Relief Centers', '${_getIntValue(disasterData?['relief_centers'])}'));
    }

    if (disasterData?['rescue_teams_deployed'] != null) {
      additionalWidgets.add(_buildInfoRow('Rescue Teams', '${_getIntValue(disasterData?['rescue_teams_deployed'])}'));
    }

    if (disasterData?['weather_conditions'] != null) {
      var weather = disasterData?['weather_conditions'];
      if (weather is Map<String, dynamic>) {
        additionalWidgets.add(
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weather Conditions:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (weather['temperature'] != null)
                  Text('Temperature: ${_getIntValue(weather['temperature'])}°C'),
                if (weather['humidity'] != null)
                  Text('Humidity: ${_getIntValue(weather['humidity'])}%'),
                if (weather['wind_speed'] != null)
                  Text('Wind Speed: ${_getIntValue(weather['wind_speed'])} km/h'),
              ],
            ),
          ),
        );
      }
    }

    if (additionalWidgets.isEmpty) return SizedBox.shrink();

    return _buildCard(
      title: 'Additional Information',
      icon: Icons.info,
      children: additionalWidgets,
    );
  }

  Widget _buildMetaInfo() {
    return _buildCard(
      title: 'Alert Details',
      icon: Icons.admin_panel_settings,
      children: [
        _buildInfoRow('Source', _getStringValue(disasterData?['source'])),
        _buildInfoRow('Last Updated', _formatDateTime(_getStringValue(disasterData?['last_updated']))),
        if (disasterData?['description'] != null && _getStringValue(disasterData?['description'])?.isNotEmpty == true)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStringValue(disasterData?['description']) ?? '',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    // Filter out empty children
    List<Widget> validChildren = children.where((child) => child != SizedBox.shrink()).toList();

    if (validChildren.isEmpty) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...validChildren,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String? stringValue = _getStringValue(value);
    if (stringValue == null || stringValue.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              stringValue,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String alertColor) {
    switch (alertColor.toLowerCase()) {
      case 'green':
        return Colors.green[600]!;
      case 'yellow':
        return Colors.orange[600]!;
      case 'orange':
        return Colors.orange[700]!;
      case 'red':
      default:
        return Colors.red[600]!;
    }
  }


  IconData _getDisasterIcon(String disasterType) {
    switch (disasterType) {
      case 'earthquake':
        return Icons.terrain;
      case 'flood':
        return Icons.water;
      case 'cyclone':
        return Icons.cyclone;
      case 'wildfire':
        return Icons.local_fire_department;
      case 'landslide':
        return Icons.landscape;
      case 'heatwave':
        return Icons.wb_sunny;
      case 'tsunami':
        return Icons.waves;
      case 'drought':
        return Icons.water_drop_outlined;
      default:
        return Icons.warning;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}