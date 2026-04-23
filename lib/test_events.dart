import 'dart:io';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: TestScreen()));
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String output = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool? granted = await UsageStats.checkUsagePermission();
    if (granted != true) {
      UsageStats.grantUsagePermission();
      return;
    }
    
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day);
    
    List<EventUsageInfo> events = await UsageStats.queryEvents(start, now);
    
    Map<String, int> types = {};
    for (var e in events) {
      if (e.eventType != null) {
        types[e.eventType!] = (types[e.eventType!] ?? 0) + 1;
      }
    }
    setState(() {
      output = "Event types count: $types\n${events.take(50).map((e) => "${e.packageName}: ${e.eventType}").join('\n')}";
    });
    print("SUCCESS_TEST");
    print(types);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Events')),
      body: SingleChildScrollView(child: Text(output)),
    );
  }
}
