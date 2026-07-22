import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:campusscore/services/auth/auth_provider.dart';
import 'package:campusscore/services/auth/auth_exceptions.dart';
import 'package:campusscore/services/auth/auth_user.dart';
import 'package:campusscore/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, GoogleAuthProvider;

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> getupdateduser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final freshuser = FirebaseAuth.instance.currentUser;
      return AuthUser.fromFirebase(freshuser!);
    } else {
      throw UserNotLoggedinException();
    }
  }

  @override
  Future<void> Logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
    } else {
      throw UserNotLoggedinException();
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedinException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPassowrdExcetion();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException();
      } else {
        throw GenericAuthException();
      }
    } catch (_) {
      throw GenericAuthException();
    }
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedinException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else if (e.code == 'wrong-password') {
        throw WrongPassAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      throw GenericAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedinException();
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth native web popup
        final googleProvider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          return AuthUser.fromFirebase(userCredential.user!);
        } else {
          throw GoogleSignInCancelledException();
        }
      } else {
        // Mobile implementation using google_sign_in
        final GoogleSignInAccount? googleUser = await GoogleSignIn(
          scopes: ['email'],
          serverClientId:
              '904527835909-fmh8bg5b911fo8vqtoe7uiugue7gqgkj.apps.googleusercontent.com',
        ).signIn();
        if (googleUser == null) throw GoogleSignInCancelledException();

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        return currentUser!;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw GenericAuthException();

      return AuthUser.fromFirebase(user);
    } catch (e) {
      if (e is GoogleSignInCancelledException) rethrow;
      throw GenericAuthException();
    }
  }
}
