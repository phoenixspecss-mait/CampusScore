import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Save user profile data
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.ref('users/$uid/profile').set(data);
    } catch (e) {
      throw Exception('Error saving user profile: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid/profile').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  // Save credit score and model results
  Future<void> saveUserScore(String uid, Map<String, dynamic> scoreData) async {
    try {
      await _db.ref('users/$uid/score').set(scoreData);
    } catch (e) {
      throw Exception('Error saving score: $e');
    }
  }

  // Get user score data
  Future<Map<String, dynamic>?> getUserScore(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid/score').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user score: $e');
    }
  }

  // Stream for real-time score updates
  Stream<DatabaseEvent> getUserScoreStream(String uid) {
    return _db.ref('users/$uid/score').onValue;
  }

  // Add a peer vouch to the user's trust circle
  Future<void> addVouch(String uid, Map<String, dynamic> vouchData) async {
    try {
      final newVouchRef = _db.ref('users/$uid/vouches').push();
      await newVouchRef.set(vouchData);
    } catch (e) {
      throw Exception('Error adding vouch: $e');
    }
  }

  // Get all active vouches for a user
  Future<List<Map<String, dynamic>>> getVouches(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid/vouches').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error getting vouches: $e');
    }
  }

  // Find a user by their Campus ID (first 8 chars of UID)
  Future<Map<String, dynamic>?> findUserByCampusId(String campusId) async {
    try {
      final snapshot = await _db.ref('users')
          .orderByKey()
          .startAt(campusId.toUpperCase())
          .endAt('${campusId.toUpperCase()}\uf8ff')
          .limitToFirst(1)
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final uid = data.keys.first;
        final userData = data[uid] as Map<dynamic, dynamic>;
        
        String name = "Peer (${campusId.toUpperCase()})";
        if (userData['profile'] != null) {
          name = userData['profile']['name'] ?? name;
        }
        
        int score = 400; // default score if none found
        if (userData['score'] != null) {
          score = userData['score']['score'] ?? userData['score']['final_score'] ?? score;
        }
        
        return {
          'uid': uid,
          'name': name,
          'score': score,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Error finding user: $e');
    }
  }
}
