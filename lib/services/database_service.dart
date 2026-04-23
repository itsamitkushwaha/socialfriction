import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/block_rule.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create a new user document when they sign up
  Future<void> createUserProfile(User user, String name) async {
    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'dailyGoalMinutes': 120, // Default 2 hours
      'streak': 0,
      'block_rules': [], // Empty initially
      'keywords': [],
      'hasPin': false,
      'photoUrl': null, // Added for profile picture
    });
  }

  // 2. Fetch all user data when they log in
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // 2.5 Update user profile (name, photo)
  Future<void> updateUserProfile(String uid, {String? name, String? photoUrl}) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      if (updates.isNotEmpty) {
        await _db.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // 3. Update their Daily Goal
  Future<void> updateDailyGoal(String uid, int minutes) async {
    try {
      await _db.collection('users').doc(uid).update({
        'dailyGoalMinutes': minutes,
      });
    } catch (_) {}
  }

  // 4. Save their Block Rules
  Future<void> syncBlockRules(String uid, List<BlockRule> rules) async {
    try {
      final rulesMap = rules.map((r) => r.toJson()).toList();
      await _db.collection('users').doc(uid).update({
        'block_rules': rulesMap,
      });
    } catch (_) {}
  }

  // 5. Save Keywords
  Future<void> syncKeywords(String uid, List<String> keywords) async {
    try {
      await _db.collection('users').doc(uid).update({
        'keywords': keywords,
      });
    } catch (_) {}
  }

  // 6. Sync PIN status
  Future<void> syncPinStatus(String uid, bool hasPin) async {
    try {
      await _db.collection('users').doc(uid).update({
        'hasPin': hasPin,
      });
    } catch (_) {}
  }
}
