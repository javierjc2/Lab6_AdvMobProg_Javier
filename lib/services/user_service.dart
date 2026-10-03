import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
// `User` is also the name of our own model, so Firebase's classes are
// imported with a prefix (fb.User, fb.UserCredential, ...).
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/login_type.dart';
import '../models/user.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

/// Handles authentication for BOTH backends used by the app:
///
///  * DummyJSON  -> REST call to `$host/auth/login`; the response (tokens +
///                  profile) is cached in SharedPreferences.
///  * Firebase   -> FirebaseAuth SDK (email/password). The SDK stores the
///                  session and refreshes ID tokens itself; extra profile
///                  fields (fName, lName, age, contactNo, username) live in
///                  Cloud Firestore under `users/{uid}`.
///
/// Which backend the current session uses is remembered as a [LoginType] in
/// SharedPreferences, so [getUserData], [isLoggedIn] and [logout] always do
/// the right thing after an app restart.
class UserService {
  Map<String, dynamic> data = {};

  // Getters (not fields) so Firebase is only touched after initializeApp().
  fb.FirebaseAuth get firebaseAuth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  fb.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb.User?> get authStateChanges => firebaseAuth.authStateChanges();

  // ===========================================================================
  // DummyJSON
  // ===========================================================================

  /// Calls the DummyJSON auth API and, on success, persists the response.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = LoginType.dummyJson.name;
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// Save a DummyJSON API response to SharedPreferences.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setString('loginType', LoginType.dummyJson.name);
    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// DummyJSON does not really persist writes -- these endpoints answer with
  /// a *simulated* result -- so we mirror the change in SharedPreferences.
  Future<void> updateDummyUsername({
    required int id,
    required String username,
  }) async {
    final response = await http.put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> changeDummyPassword({
    required int id,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
  }

  Future<void> deleteDummyAccount({required int id}) async {
    final response = await http.delete(Uri.parse('$host/users/$id'));
    if (response.statusCode != 200) throw Exception(response.body);
    await logout();
  }

  // ===========================================================================
  // Firebase Authentication
  // ===========================================================================

  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  /// Updates the Firebase display name and the Firestore profile copy.
  Future<void> updateUsername({required String username}) async {
    final user = currentUser!;
    await user.updateDisplayName(username);
    await _db.collection('users').doc(user.uid).set({
      'username': username,
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  /// Deletes the Firestore profile + the Firebase account. Firebase requires
  /// a recent login for this, so the user is re-authenticated first.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final user = currentUser!;
    await user.reauthenticateWithCredential(credential);

    // Delete the profile first, while we are still authenticated (the
    // security rules only allow the owner to touch their document).
    try {
      await _db.collection('users').doc(user.uid).delete();
    } catch (e) {
      debugPrint('Could not delete Firestore profile: $e');
    }

    await user.delete();
    await logout();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    final user = currentUser!;
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Firebase refreshes ID tokens automatically (they last 1 hour). Pass
  /// [forceRefresh] to force a new token from the refresh token right now.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await currentUser?.getIdToken(forceRefresh);
  }

  /// Sign in with Firebase and cache the session. Returns the user map that
  /// HomeScreen expects.
  Future<Map<String, dynamic>> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    await signIn(email: email, password: password);
    return await _firebaseUserData(cache: true);
  }

  /// Sign-up flow: create the Auth account, set the display name, save the
  /// profile document in Firestore, then cache the session.
  Future<Map<String, dynamic>> registerWithProfile({
    required String fName,
    required String lName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await createAccount(email: email, password: password);
    final user = credential.user!;

    try {
      await user.updateDisplayName(username);
      await _db.collection('users').doc(user.uid).set({
        'fName': fName,
        'lName': lName,
        'age': age,
        'contactNo': contactNo,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Roll back so the user can retry with the same email.
      try {
        await user.delete();
      } catch (rollbackError) {
        debugPrint('Could not roll back Firebase account: $rollbackError');
      }
      rethrow;
    }

    return await _firebaseUserData(cache: true);
  }

  // ===========================================================================
  // Shared (both login types)
  // ===========================================================================

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return LoginType.fromString(prefs.getString('loginType'));
  }

  /// Returns the current user's data as a map, source depends on LoginType:
  /// DummyJSON -> SharedPreferences, Firebase -> FirebaseAuth + Firestore.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final type = LoginType.fromString(prefs.getString('loginType'));

    if (type == LoginType.firebase) {
      return await _firebaseUserData(cache: false);
    }

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': LoginType.dummyJson.name,
    };
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// Persistent-login check used by SplashScreen.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final type = LoginType.fromString(prefs.getString('loginType'));

    if (type == LoginType.firebase) {
      // The first event of authStateChanges is the restored session (or null).
      final user = await firebaseAuth.authStateChanges().first;
      return user != null;
    }

    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Clears the session (Firebase sign-out if needed + local cache).
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = LoginType.fromString(prefs.getString('loginType'));
      if (type == LoginType.firebase || currentUser != null) {
        await signOut();
      }
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  /// Turns Firebase/HTTP exceptions into short, readable messages.
  static String friendlyError(Object e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'That password is too weak.';
        case 'requires-recent-login':
          return 'Please log in again and retry.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return '${e.code}: ${e.message ?? 'No additional details'}';
      }
    }
    if (e is FirebaseException) {
      return '${e.plugin}/${e.code}: ${e.message ?? 'No additional details'}';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _firebaseUserData({required bool cache}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = currentUser;

    // No live session: fall back to whatever was cached at login time.
    if (user == null) {
      return {
        'id': 0,
        'uid': prefs.getString('uid') ?? '',
        'username': prefs.getString('username') ?? '',
        'email': prefs.getString('email') ?? '',
        'firstName': prefs.getString('firstName') ?? '',
        'lastName': prefs.getString('lastName') ?? '',
        'age': prefs.getInt('age') ?? 0,
        'contactNo': prefs.getString('contactNo') ?? '',
        'loginType': LoginType.firebase.name,
      };
    }

    Map<String, dynamic> profile = {};
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      profile = doc.data() ?? {};
    } catch (e) {
      debugPrint('Could not read Firestore profile: $e');
    }

    final email = user.email ?? profile['email']?.toString() ?? '';
    final result = <String, dynamic>{
      'id': 0, // DummyJSON-only numeric id; Firebase users are keyed by uid.
      'uid': user.uid,
      'username':
          profile['username']?.toString() ??
          user.displayName ??
          (email.contains('@') ? email.split('@').first : email),
      'email': email,
      'firstName': profile['fName']?.toString() ?? '',
      'lastName': profile['lName']?.toString() ?? '',
      'gender': '',
      'image': user.photoURL ?? '',
      'accessToken': await user.getIdToken() ?? '',
      'refreshToken': user.refreshToken ?? '',
      'age': profile['age'] is int
          ? profile['age']
          : int.tryParse('${profile['age']}') ?? 0,
      'contactNo': profile['contactNo']?.toString() ?? '',
      'loginType': LoginType.firebase.name,
    };

    if (cache) {
      await prefs.setString('loginType', LoginType.firebase.name);
      await prefs.setString('uid', result['uid']);
      await prefs.setString('username', result['username']);
      await prefs.setString('email', result['email']);
      await prefs.setString('firstName', result['firstName']);
      await prefs.setString('lastName', result['lastName']);
      await prefs.setInt('age', result['age']);
      await prefs.setString('contactNo', result['contactNo']);
    }
    return result;
  }
}
