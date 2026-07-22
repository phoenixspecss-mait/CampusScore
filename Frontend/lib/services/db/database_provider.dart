import 'package:flutter/foundation.dart';
import 'package:campusscore/services/db/database_service.dart';

class DatabaseProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userScore;
  List<Map<String, dynamic>> _vouches = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get userScore => _userScore;
  List<Map<String, dynamic>> get vouches => _vouches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user profile from Realtime Database
  Future<void> fetchUserProfile(String uid) async {
    _setLoading(true);
    try {
      _userProfile = await _dbService.getUserProfile(uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Save user profile data
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _dbService.saveUserProfile(uid, data);
      _userProfile = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user score from Realtime Database
  Future<void> fetchUserScore(String uid) async {
    _setLoading(true);
    try {
      _userScore = await _dbService.getUserScore(uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Save calculated score to Realtime Database
  Future<void> saveUserScore(String uid, Map<String, dynamic> scoreData) async {
    _setLoading(true);
    try {
      await _dbService.saveUserScore(uid, scoreData);
      _userScore = scoreData;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch vouches
  Future<void> fetchVouches(String uid) async {
    _setLoading(true);
    try {
      _vouches = await _dbService.getVouches(uid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add vouch
  Future<void> addVouch(String uid, Map<String, dynamic> vouchData) async {
    _setLoading(true);
    try {
      await _dbService.addVouch(uid, vouchData);
      _vouches.add(vouchData);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
