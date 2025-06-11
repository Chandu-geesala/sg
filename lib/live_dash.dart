// live_dashboard.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveDashboardPage extends StatefulWidget {
  @override
  _LiveDashboardPageState createState() => _LiveDashboardPageState();
}

class _LiveDashboardPageState extends State<LiveDashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('https://chandugeesala0-random.hf.space/api/disaster-dashboard'));
    if (response.statusCode == 200) {
      setState(() {
        dashboardData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Live Disaster Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchDashboard,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : dashboardData == null
          ? Center(child: Text("Failed to load data"))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            ...dashboardData!['overview'].entries.map((entry) => Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                trailing: Text(entry.value.toString()),
              ),
            )),
            SizedBox(height: 20),
            Text("Current Disasters", style: Theme.of(context).textTheme.titleLarge),
            ...dashboardData!['current_disasters'].map<Widget>((disaster) => Card(
              color: Colors.red.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text("${disaster['type'].toString().toUpperCase()} in ${disaster['location']}"),
                subtitle: Text("Severity: ${disaster['severity']}, Status: ${disaster['status']}"),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
