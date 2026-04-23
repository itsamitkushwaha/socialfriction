import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MaterialApp(home: TestUploadScreen()));
}

class TestUploadScreen extends StatelessWidget {
  const TestUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Upload')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Create a dummy file
              final file = File('/data/user/0/com.example.socialFriction/cache/test.txt');
              await file.writeAsString('hello world');
              
              print('Starting upload test');
              final ref = FirebaseStorage.instance.ref().child('test/test.txt');
              
              final task = await ref.putFile(file);
              print('Upload state: ${task.state}');
              
              final url = await ref.getDownloadURL();
              print('URL: $url');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: Text('Run Test'),
        ),
      ),
    );
  }
}
