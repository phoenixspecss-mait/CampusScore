import 'package:flutter/material.dart';
import 'package:campusscore/services/api/api_service.dart';
import 'package:campusscore/views/responsive_layout.dart';

class SimulatorView extends StatefulWidget {
  const SimulatorView({super.key});

  @override
  State<SimulatorView> createState() => _SimulatorViewState();
}

class _SimulatorViewState extends State<SimulatorView> {
  double _income = 45000;
  double _daysEmployed = 300;
  double _savingsCadence = 0.5;
  double _trustCircle = 1.0;
  double _feePunctuality = 0.8;

  int _baseScore = 0;
  
  // Track values from the last successful API call
  double _lastApiIncome = 45000;
  double _lastApiDays = 300;
  double _lastApiCadence = 0.5;
  double _lastApiTrust = 1.0;
  double _lastApiFee = 0.8;

  Map<String, dynamic> _shapImpacts = {};
  bool _isLoading = false;

  int get _projectedScore {
    if (_baseScore == 0) return 0;
    
    // Calculate a small "smoothing" bonus based on the delta since the last API call
    double incomeDelta = (_income - _lastApiIncome) / 200000.0 * 5.0;
    double daysDelta = (_daysEmployed - _lastApiDays) / 1000.0 * 15.0;
    double savingsDelta = (_savingsCadence - _lastApiCadence) / 1.0 * 10.0;
    double trustDelta = (_trustCircle - _lastApiTrust) / 3.0 * 20.0;
    double feeDelta = (_feePunctuality - _lastApiFee) / 1.0 * 15.0;
    
    int smoothingBonus = (incomeDelta + daysDelta + savingsDelta + trustDelta + feeDelta).round();
    return _baseScore + smoothingBonus;
  }

  @override
  void initState() {
    super.initState();
    _calculateProjectedScore();
  }

  Future<void> _calculateProjectedScore() async {
    setState(() => _isLoading = true);
    try {
      final scoreData = await ApiService().calculateScore(
        amtIncomeTotal: _income,
        daysEmployed: _daysEmployed,
        savingsCadence: _savingsCadence,
        trustCircleVouch: _trustCircle,
        feePunctuality: _feePunctuality,
      );
      if (mounted) {
        setState(() {
          _baseScore = scoreData['score'] ?? 0;
          
          // Sync the tracking variables to the current state since the API has returned
          _lastApiIncome = _income;
          _lastApiDays = _daysEmployed;
          _lastApiCadence = _savingsCadence;
          _lastApiTrust = _trustCircle;
          _lastApiFee = _feePunctuality;
          
          final topFactorsList = scoreData['top_factors'] as List<dynamic>? ?? [];
          _shapImpacts = {
            for (var factor in topFactorsList) 
              factor['feature'] as String: factor['impact']
          };
        });
      }
    } catch (e) {
      debugPrint("Simulation Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "What-If Simulator",
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
            // Projected Score Display
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: const Color(0xFFFF6B00).withOpacity(0.05),
            child: Column(
              children: [
                const Text(
                  "Projected Credit Score",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const SizedBox(
                        height: 80,
                        width: 80,
                        child: CircularProgressIndicator(color: Color(0xFFFF6B00), strokeWidth: 8),
                      )
                    : Text(
                        _projectedScore.toString(),
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00)),
                      ),
              ],
            ),
          ),
          
          if (_shapImpacts.isNotEmpty) _buildShapImpacts(),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                const Text(
                  "Adjust your habits below to see how your score changes instantly.",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 24),

                _buildSlider(
                  title: "Annual Income (₹)",
                  value: _income,
                  min: 0,
                  max: 200000,
                  divisions: 20,
                  onChanged: (val) => setState(() => _income = val),
                  onChangeEnd: (_) => _calculateProjectedScore(),
                ),
                
                _buildSlider(
                  title: "Days in Gig/Part-time",
                  value: _daysEmployed,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  onChanged: (val) => setState(() => _daysEmployed = val),
                  onChangeEnd: (_) => _calculateProjectedScore(),
                ),

                _buildSlider(
                  title: "Savings Regularity (0 to 1)",
                  value: _savingsCadence,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (val) => setState(() => _savingsCadence = val),
                  onChangeEnd: (_) => _calculateProjectedScore(),
                ),

                _buildSlider(
                  title: "Fee Punctuality (0 to 1)",
                  value: _feePunctuality,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (val) => setState(() => _feePunctuality = val),
                  onChangeEnd: (_) => _calculateProjectedScore(),
                ),

                _buildSlider(
                  title: "Trust Circle Vouches",
                  value: _trustCircle,
                  min: 0.0,
                  max: 3.0,
                  divisions: 3,
                  onChanged: (val) => setState(() => _trustCircle = val),
                  onChangeEnd: (_) => _calculateProjectedScore(),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildShapImpacts() {
    // Map internal variable names to readable labels
    final Map<String, String> featureNames = {
      'AMT_INCOME_TOTAL': 'Annual Income',
      'gig_income_stability': 'Gig/Employment Stability',
      'savings_consistency': 'Savings Regularity',
      'trust_circle_vouch_score': 'Trust Circle',
      'fee_payment_punctuality': 'Fee Punctuality',
      'subscription_regularity': 'Subscription Punctuality',
      'AGE_YEARS': 'Age',
      'AMT_CREDIT': 'Prior Loan Amount',
      'on_time_repayment_rate': 'Repayment History',
      'is_returning_applicant': 'Returning Applicant',
      'NAME_EDUCATION_TYPE': 'Education Type'
    };

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Model Impact Breakdown (SHAP)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ..._shapImpacts.entries.map((entry) {
            double impact = (entry.value as num).toDouble();
            if (impact == 0) return const SizedBox();
            
            // Assuming higher SHAP = higher default risk = BAD for score
            bool isBad = impact > 0;
            Color color = isBad ? Colors.red : Colors.green;
            IconData icon = isBad ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
            String sign = impact > 0 ? "+" : "";

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      featureNames[entry.key] ?? entry.key,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Text(
                    "$sign${impact.toStringAsFixed(1)} pts",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF6B00),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFFFF6B00),
              overlayColor: const Color(0xFFFF6B00).withOpacity(0.2),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}
