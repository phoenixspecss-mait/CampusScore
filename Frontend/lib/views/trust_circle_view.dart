import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:campusscore/services/db/database_provider.dart';
import 'package:campusscore/services/auth/auth_service.dart';
import 'package:campusscore/services/api/api_service.dart';
import 'dart:math';
import 'package:campusscore/views/responsive_layout.dart';

class TrustCircleView extends StatefulWidget {
  const TrustCircleView({super.key});

  @override
  State<TrustCircleView> createState() => _TrustCircleViewState();
}

class _TrustCircleViewState extends State<TrustCircleView> {
  final TextEditingController _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = AuthService.firebase().currentUser;
      if (user != null) {
         context.read<DatabaseProvider>().fetchVouches(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Invite to Trust Circle", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "A strong Trust Circle helps you build your score faster. Invite a peer or family member who has good credit behavior to vouch for you.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                hintText: 'Enter a peer\'s Campus ID',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B00)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_inviteController.text.isEmpty) return;
              
              Navigator.of(ctx).pop(); // Close input dialog

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const AlertDialog(
                  backgroundColor: Colors.white,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFF6B00)),
                      SizedBox(height: 24),
                      Text("Looking up Campus ID...", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                )
              );

              // Simulate network delay
              await Future.delayed(const Duration(milliseconds: 1500));

              if (context.mounted) {
                Navigator.of(context).pop(); // Close loading dialog
              }

              final user = AuthService.firebase().currentUser;
              if (user != null) {
                final campusId = _inviteController.text.trim();
                final peerData = await context.read<DatabaseProvider>().findUserByCampusId(campusId);
                
                if (peerData != null) {
                  final newVouch = {
                    'name': peerData['name'],
                    'relation': 'Peer / Batchmate',
                    'score': peerData['score'],
                    'status': 'Active Vouch',
                  };
                  if (context.mounted) {
                    final dbProvider = context.read<DatabaseProvider>();
                    await dbProvider.addVouch(user.uid, newVouch);
                    
                    // Recalculate score with new vouch count
                    try {
                      final existingScore = dbProvider.userScore;
                      final extractedData = existingScore?['extracted_data'] as Map<String, dynamic>?;
                      
                      Map<String, dynamic> newScoreData;
                      if (extractedData != null) {
                         newScoreData = await ApiService().updateTrustScore(extractedData, dbProvider.vouches.length);
                         newScoreData['extracted_data'] = extractedData; // preserve it
                      } else {
                         newScoreData = await ApiService().calculateScore(
                           amtIncomeTotal: 0, daysEmployed: 0, savingsCadence: 0.0,
                           trustCircleVouch: dbProvider.vouches.length.toDouble(), feePunctuality: 0.0
                         );
                      }
                      await dbProvider.saveUserScore(user.uid, newScoreData);
                    } catch (e) {
                      debugPrint("Failed to recalculate score: $e");
                    }
                  }
                  
                  _inviteController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vouch successfully added to your Trust Circle!")),
                    );
                  }
                } else {
                  if (context.mounted) {
                    final dbError = context.read<DatabaseProvider>().error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(dbError != null ? "Error: $dbError" : "Campus ID not found. Please check the ID and try again."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Add Vouch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseProvider>();
    final activeVouches = dbProvider.vouches;
    final int trustPoints = activeVouches.length * 20;

    final user = AuthService.firebase().currentUser;
    final String fullUid = user?.uid ?? "00000000";
    final String campusId = fullUid.length > 8 ? fullUid.substring(0, 8).toUpperCase() : fullUid.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Trust Circle",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: Column(
          children: [
            Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: const Color(0xFFFF6B00).withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFFFF6B00)),
                    SizedBox(width: 8),
                    Text(
                      "Community Trust Boost",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "By having financially responsible peers and family vouch for you, you can unlock higher credit limits and better rates, even with zero formal history.",
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "+$trustPoints Points from Trust Circle",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: double.infinity,
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Colors.blue, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Shareable Campus ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          campusId,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: campusId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Campus ID copied to clipboard!")),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.blue),
                    tooltip: "Copy ID",
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                const Text(
                  "Active Vouches",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                dbProvider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                  : activeVouches.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text("No vouches yet. Invite someone below!", style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
                        )
                      : Column(
                          children: activeVouches.map((vouch) => _buildVouchCard(vouch)).toList(),
                        ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(Icons.person_add_rounded, color: Color(0xFFFF6B00)),
                    label: const Text(
                      "Invite to Trust Circle",
                      style: TextStyle(color: Color(0xFFFF6B00), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildVouchCard(Map<String, dynamic> vouch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFF6B00).withOpacity(0.1),
            child: Text(
              vouch['name'][0],
              style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vouch['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  vouch['relation'],
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Score: ${vouch['score']}",
                style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
