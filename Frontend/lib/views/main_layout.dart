import 'package:flutter/material.dart';
import 'package:campusscore/views/notes_view.dart';
import 'package:campusscore/views/simulator_view.dart';
import 'package:campusscore/views/trust_circle_view.dart';
import 'package:campusscore/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:campusscore/services/db/database_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const NotesView(),
    const SimulatorView(),
    const TrustCircleView(),
  ];

  @override
  void initState() {
    super.initState();
    // Silent check on app startup to see if account was deleted from Firebase Console
    FirebaseAuth.instance.currentUser?.reload().catchError((e) {
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        AuthService.firebase().Logout();
      }
    });
  }

  void _showProfileBottomSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "Unknown User";
    final dbProvider = context.read<DatabaseProvider>();
    final profile = dbProvider.userProfile;
    
    final name = profile?['name'] ?? "My Profile";
    final university = profile?['university'] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFF6B00).withOpacity(0.15),
                  child: const Icon(Icons.person, size: 35, color: Color(0xFFFF6B00)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (university.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          university,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop(); // close bottom sheet
                  await AuthService.firebase().Logout(); // trigger sign out
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            const SizedBox(height: 16), // Padding at bottom
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isDesktop 
        ? null 
        : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'CampusScore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => _showProfileBottomSheet(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFF6B00).withOpacity(0.15),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFFFF6B00),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  extended: MediaQuery.of(context).size.width >= 1000,
                  minExtendedWidth: 200,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (MediaQuery.of(context).size.width >= 1000) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'CampusScore',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) => setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
                  selectedLabelTextStyle: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tune_rounded),
                      label: Text('Simulator'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_rounded),
                      label: Text('Trust Circle'),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: GestureDetector(
                          onTap: () => _showProfileBottomSheet(context),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFFF6B00).withOpacity(0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFFFF6B00),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(thickness: 1, width: 1, color: Colors.grey.shade200),
                Expanded(child: _screens[_currentIndex]),
              ],
            )
          : _screens[_currentIndex],
      bottomNavigationBar: isDesktop 
          ? null 
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: const Color(0xFFFF6B00),
              unselectedItemColor: Colors.grey.shade400,
              backgroundColor: Colors.white,
              elevation: 20,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Simulator',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_rounded),
                  label: 'Trust Circle',
                ),
              ],
            ),
    );
  }
}
