import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campusscore/services/db/database_provider.dart';
import 'package:campusscore/services/auth/auth_service.dart';
import 'package:campusscore/services/api/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campusscore/views/profile_setup_view.dart';
import 'package:campusscore/views/responsive_layout.dart';

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
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    // Mobile specific layout pieces
    Widget mobileLeftSide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScoreHeader(currentScore, scoreStatus),
        if (currentScore > 0) ...[
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
        ]
      ],
    );

    Widget mobileRightSide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentScore == 0) ...[
          _buildColdStartButton(context, dbProvider),
        ] else ...[
          const Text(
            'What\'s building your score?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildHabitsList(isDesktop: false),
        ]
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveLayout(
        maxWidth: 1300, // True SaaS desktop maximum width constraint
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: isDesktop 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Overview',
                      style: TextStyle(
                        fontSize: 36, // Scaled up typography for desktop
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDesktopMetricsRow(currentScore, scoreStatus, dbProvider.vouches.length),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Habits & History',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              currentScore == 0 
                                ? _buildColdStartButton(context, dbProvider)
                                : _buildHabitsList(isDesktop: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Action Plan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (currentScore > 0) _buildActionableFeedback(dbProvider.userScore),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mobileLeftSide,
                    const SizedBox(height: 32),
                    mobileRightSide,
                    const SizedBox(height: 40),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMetricsRow(int currentScore, String scoreStatus, int vouchCount) {
    return Row(
      children: [
        // Card 1: Score
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 64, // Shrunk from 80 to 64
                  width: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: currentScore / 900,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade100,
                        color: const Color(0xFFFF6B00),
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        currentScore.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Credit Score', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      scoreStatus,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Card 2: Trust Circle
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Trust Circle', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$vouchCount Active',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Card 3: Tracked Habits
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fact_check_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Data Points', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '3 Habits',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        withData: true, // Crucial for getting bytes on Web/Mobile
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

        // 3. Feed the actual file bytes to the real ML API
        final fileBytes = result.files.single.bytes;
        final fileName = result.files.single.name;
        
        if (fileBytes == null) {
          if (context.mounted) Navigator.of(context).pop();
          throw Exception("Could not read file bytes. Make sure the file isn't corrupted.");
        }
        
        try {
          final scoreData = await ApiService().uploadStatement(
            fileBytes: fileBytes,
            fileName: fileName,
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

  Widget _buildHabitsList({required bool isDesktop}) {
    final List<Widget> children = [
      _buildFactorCard(
        emoji: '🏠',
        emojiBgColor: Colors.green.shade50,
        title: 'Rent & Hostel Fees',
        description: 'Paid on time for 4 months',
        status: 'Excellent',
        statusColor: Colors.green,
        isDesktop: isDesktop,
      ),
      if (!isDesktop) const SizedBox(height: 12),
      _buildFactorCard(
        emoji: '🧾',
        emojiBgColor: Colors.blue.shade50,
        title: 'Recurring UPI Payments',
        description: 'Consistent weekly transactions',
        status: 'Good',
        statusColor: Colors.blue,
        isDesktop: isDesktop,
      ),
      if (!isDesktop) const SizedBox(height: 12),
      _buildFactorCard(
        emoji: '🐷',
        emojiBgColor: Colors.orange.shade50,
        title: 'Small Savings',
        description: 'Irregular saving patterns detected',
        status: 'Needs Work',
        statusColor: Colors.orange,
        isDesktop: isDesktop,
      ),
    ];

    if (isDesktop) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children.map((w) {
          // If it's a SizedBox, return empty for Wrap
          if (w is SizedBox) return const SizedBox.shrink();
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: w,
          );
        }).toList(),
      );
    }

    return Column(children: children);
  }

  Widget _buildFactorCard({
    required String emoji,
    required Color emojiBgColor,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emojiBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableFeedback(Map<String, dynamic>? scoreData) {
    if (scoreData == null) return const SizedBox();

    List<Map<String, String>> suggestions = [];
    int finalScore = scoreData['final_score'] ?? 0;

    if (finalScore < 500) {
      suggestions.add({'title': 'Start Building History', 'subtitle': 'Pay rent via app to establish history', 'emoji': '📈'});
      suggestions.add({'title': 'Verify Identity', 'subtitle': 'Complete profile for +50 points', 'emoji': '🛡️'});
    } else if (finalScore < 700) {
      suggestions.add({'title': 'Boost your fee punctuality', 'subtitle': 'Pay your college fees and rent on time for the next 2 months. Late payments heavily impact your score.', 'emoji': '📅'});
      suggestions.add({'title': 'Expand Trust Circle', 'subtitle': 'Get 2 more vouches for a boost', 'emoji': '🤝'});
    } else {
      suggestions.add({'title': 'Maintain Streak', 'subtitle': 'Keep up the on-time payments', 'emoji': '🔥'});
    }

    return Column(
      children: suggestions.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED), // Light orange background matching Action Plan mockup
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s['emoji']!, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              Text(
                s['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                s['subtitle']!,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
