import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campusscore/services/db/database_provider.dart';
import 'package:campusscore/services/auth/auth_service.dart';
import 'package:campusscore/services/api/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campusscore/views/profile_setup_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  Future<void> _loadData() async {
    final user = AuthService.firebase().currentUser;
    if (user != null) {
      final db = context.read<DatabaseProvider>();
      await Future.wait([
        db.fetchUserProfile(user.uid),
        db.fetchUserScore(user.uid),
        db.fetchVouches(user.uid),
      ]);
      
      // If profile is missing, push onboarding setup
      if (db.userProfile == null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileSetupView()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseProvider>();
    final int currentScore = dbProvider.userScore?['final_score'] ?? 0;
    final String scoreStatus = currentScore > 700 ? "Excellent" : (currentScore > 500 ? "Growing" : "Needs Work");
    final bool isLoading = dbProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light background
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreHeader(currentScore, scoreStatus),
              if (currentScore == 0) ...[
                const SizedBox(height: 16),
                _buildColdStartButton(context, dbProvider),
                const SizedBox(height: 32),
              ] else ...[
                const SizedBox(height: 32),
                const Text(
                  'What\'s building your score?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHabitsList(),
                const SizedBox(height: 32),
                const Text(
                  'How to Improve',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionableFeedback(dbProvider.userScore),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeader(int currentScore, String scoreStatus) {
    // Determine percentile (Mock logic for peer benchmarking based on score)
    String percentileText;
    if (currentScore > 750) {
      percentileText = "Top 10% of students in your college";
    } else if (currentScore > 650) {
      percentileText = "Top 30% of students in your college";
    } else if (currentScore > 500) {
      percentileText = "Top 60% of students in your college";
    } else {
      percentileText = "Building history";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Your Student Credit Score',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: CircularProgressIndicator(
                  value: currentScore / 900,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  color: const Color(0xFFFF6B00),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentScore.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    scoreStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, color: Color(0xFFFF6B00), size: 18),
                const SizedBox(width: 8),
                Text(
                  percentileText,
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Built from your everyday habits, not bank records.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildColdStartButton(BuildContext context, DatabaseProvider dbProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B00), size: 32),
          const SizedBox(height: 12),
          const Text(
            "No formal history? No problem.",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "We can generate your initial credit score based entirely on how many active vouches you have in your Trust Circle.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Option 1: Bank Statement Upload (Simulated)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: dbProvider.isLoading ? null : () => _pickAndUploadStatement(context, dbProvider),
              icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text("Upload Bank Statement (PDF/CSV)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          const Text("OR", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Option 2: Trust Circle
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: dbProvider.isLoading ? null : () async {
                final user = AuthService.firebase().currentUser;
                if (user == null) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calculating Initial Score based on Trust Circle...'))
                );
                
                try {
                  // Cold start: Income 0, Days 0, Cadence 0, Fee 0, BUT vouches > 0
                  final int vouchCount = dbProvider.vouches.length;
                  final scoreData = await ApiService().calculateScore(
                    amtIncomeTotal: 0,
                    daysEmployed: 0,
                    savingsCadence: 0.0,
                    trustCircleVouch: vouchCount.toDouble(),
                    feePunctuality: 0.0,
                  );
                  await dbProvider.saveUserScore(user.uid, scoreData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Initial Score Generated Successfully!'))
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'))
                    );
                  }
                }
              },
              icon: const Icon(Icons.group_rounded, color: Color(0xFFFF6B00)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text("Use Trust Circle Instead", style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadStatement(BuildContext context, DatabaseProvider dbProvider) async {
    final user = AuthService.firebase().currentUser;
    if (user == null) return;

    try {
      // 1. Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
      );

      if (result != null) {
        if (!context.mounted) return;
        
        bool isDialogShowing = true;
        // 2. Show loading dialog (Simulation of parsing)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  SizedBox(height: 24),
                  Text("Securely analyzing UPI transactions via Account Aggregator...", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text("Calculating income variance and savings cadence.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ),
        );

        // 3. Feed the actual file to the real ML API
        if (result.files.single.path == null) {
          if (context.mounted) Navigator.of(context).pop();
          throw Exception("Could not read file path.");
        }
        
        try {
          final scoreData = await ApiService().uploadStatement(
            filePath: result.files.single.path!,
            trustCircleVouch: dbProvider.vouches.length.toDouble(),
          );

          if (isDialogShowing && context.mounted) {
            Navigator.of(context).pop(); // Close dialog
            isDialogShowing = false;
          }

          await dbProvider.saveUserScore(user.uid, scoreData);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statement parsed and score generated successfully!')),
            );
          }
        } catch (e) {
          if (isDialogShowing && context.mounted) {
            Navigator.of(context).pop();
          }
          rethrow; // pass to outer catch
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing statement: $e')),
        );
      }
    }
  }

  Widget _buildHabitsList() {
    return Column(
      children: [
        _buildFactorCard(
          icon: Icons.home_work_rounded,
          title: 'Rent & Hostel Fees',
          description: 'Paid on time for 4 months',
          status: 'Excellent',
          statusColor: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildFactorCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Recurring UPI Payments',
          description: 'Consistent weekly transactions',
          status: 'Good',
          statusColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildFactorCard(
          icon: Icons.savings_rounded,
          title: 'Small Savings',
          description: 'Irregular saving patterns detected',
          status: 'Needs Work',
          statusColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildFactorCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableFeedback(Map<String, dynamic>? userScore) {
    if (userScore == null || userScore['shap_impacts'] == null) {
      return const Text("Generate your score to see personalized advice.");
    }

    final impacts = Map<String, dynamic>.from(userScore['shap_impacts']);
    
    // Find the feature with the highest positive SHAP value (highest positive = increases default risk = needs most work)
    String worstFeature = "";
    double worstImpact = -100.0;

    impacts.forEach((key, value) {
      if (value is double && value > worstImpact) {
        worstImpact = value;
        worstFeature = key;
      }
    });

    String adviceTitle = 'Keep building your history';
    String adviceDesc = 'Maintain your current habits to steadily improve your score over time.';
    IconData adviceIcon = Icons.trending_up_rounded;

    if (worstImpact > 0.01) { // Only show advice if it's actually hurting the score significantly
      if (worstFeature == 'fee_punctuality') {
        adviceTitle = 'Boost your fee punctuality';
        adviceDesc = 'Pay your college fees and rent on time for the next 2 months. Late payments heavily impact your score.';
        adviceIcon = Icons.event_busy_rounded;
      } else if (worstFeature == 'savings_cadence') {
        adviceTitle = 'Save small, save regularly';
        adviceDesc = 'Your savings pattern is irregular. Try saving just ₹500 every single month consistently.';
        adviceIcon = Icons.savings_rounded;
      } else if (worstFeature == 'trust_circle_vouch') {
        adviceTitle = 'Grow your Trust Circle';
        adviceDesc = 'Add more trusted peers or family to your Trust Circle to act as a community guarantee.';
        adviceIcon = Icons.group_add_rounded;
      } else if (worstFeature == 'DAYS_EMPLOYED') {
        adviceTitle = 'Gig/Income consistency';
        adviceDesc = 'Consistent part-time or gig work will stabilize your profile. Keep it up!';
        adviceIcon = Icons.work_history_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B00).withOpacity(0.1),
            const Color(0xFFFF6B00).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              adviceIcon,
              color: const Color(0xFFFF6B00),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adviceTitle,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adviceDesc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
