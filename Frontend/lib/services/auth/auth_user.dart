import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final bool isEmailVeified;
  final String uid;
  const AuthUser({required this.isEmailVeified,required this.uid});

  factory AuthUser.fromFirebase(User user) => 
  AuthUser(isEmailVeified: user.emailVerified, uid: user.uid);

}