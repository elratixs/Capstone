import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/session.dart';
import 'exams_screen.dart';
import 'overview_screen.dart';
import 'patients_screen.dart';
import 'audit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.api,
    required this.session,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final Session session;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF174EA6);
    const bgLight = Color(0xFFEEF3F9);

    final pages = [
      OverviewScreen(
        session: widget.session,
        onNavigate: (i) => setState(() => _index = i),
      ),
      PatientsScreen(api: widget.api, session: widget.session),
      ExamsScreen(api: widget.api, session: widget.session),
      AuditScreen(api: widget.api, session: widget.session),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Menú Lateral Azul
            if (wide)
              Container(
                width: 230,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'WellQ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'ACCESOS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    _buildNavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Inicio',
                      isSelected: _index == 0,
                      onTap: () => setState(() => _index = 0),
                    ),
                    _buildNavItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Pacientes',
                      isSelected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                    _buildNavItem(
                      icon: Icons.description_rounded,
                      label: 'Exámenes',
                      isSelected: _index == 2,
                      onTap: () => setState(() => _index = 2),
                    ),
                    _buildNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Auditoría',
                      isSelected: _index == 3,
                      onTap: () => setState(() => _index = 3),
                    ),
                    const Spacer(),
                    _buildNavItem(
                      icon: Icons.logout_rounded,
                      label: 'Cerrar sesión',
                      isSelected: false,
                      onTap: widget.onLogout,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // 2. Contenido de la Pantalla Activa
            Expanded(
              child: Container(
                color: bgLight,
                child: IndexedStack(
                  index: _index,
                  children: pages,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_rounded),
                  label: 'Pacientes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_rounded),
                  label: 'Exámenes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  label: 'Auditoría',
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? const Color(0xFF174EA6) : Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF102A43) : Colors.white,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
