import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listen to changes (e.g., when user logs in or out)
    _authService.authStateChanges.listen((User? newUser) async {
      _isLoading = true;
      notifyListeners();
      
      _user = newUser;
      if (newUser != null) {
        _userProfile = await _dbService.getUserProfile(newUser.uid);
      } else {
        _userProfile = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  // Wrappers for Auth functions
  Future<void> signIn(String email, String password) => _authService.signIn(email, password);
  
  Future<void> signUp(String name, String email, String password) async {
    final user = await _authService.signUp(email, password);
    if (user != null) {
      await _dbService.createUserProfile(user, name);
      _userProfile = await _dbService.getUserProfile(user.uid);
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      // Check if profile exists, if not create one
      var profile = await _dbService.getUserProfile(user.uid);
      if (profile == null) {
        await _dbService.createUserProfile(user, user.displayName ?? 'Google User');
        // Update Firebase photoURL to Firestore initially if available
        if (user.photoURL != null) {
          await _dbService.updateUserProfile(user.uid, photoUrl: user.photoURL);
        }
      }
      _userProfile = await _dbService.getUserProfile(user.uid);
      notifyListeners();
    }
  }
  
  Future<void> updateUserProfile({String? newName, String? imagePath}) async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      String? photoUrl;
      
      // 1. Upload new image if provided
      if (imagePath != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${_user!.uid}.jpg');
            
        try {
          debugPrint('Starting upload for ${_user!.uid}.jpg');
          final uploadTask = await ref.putFile(File(imagePath));
          debugPrint('Upload task completed with state: ${uploadTask.state}');
          photoUrl = await ref.getDownloadURL();
          debugPrint('Got download URL successfully: $photoUrl');
        } on FirebaseException catch (e) {
          debugPrint('Firebase Storage Exception during upload: [${e.code}] ${e.message}');
          rethrow;
        } catch (e) {
          debugPrint('Unknown error during upload: $e');
          rethrow;
        }
      }

      // 2. Update Firebase Auth Profile
      if (newName != null || photoUrl != null) {
        await _user!.updateDisplayName(newName ?? _user!.displayName);
        if (photoUrl != null) {
          await _user!.updatePhotoURL(photoUrl);
        }
        await _user!.reload();
        // user object might need to be refreshed
      }

      // 3. Update Firestore Document
      await _dbService.updateUserProfile(
        _user!.uid,
        name: newName,
        photoUrl: photoUrl,
      );

      // 4. Update local state
      _userProfile = await _dbService.getUserProfile(_user!.uid);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() => _authService.signOut();
}
