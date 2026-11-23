import 'package:flutter/material.dart';

class AppointmentBookingScreen extends StatelessWidget {
  const AppointmentBookingScreen({super.key});

  static const Color primaryBlue = Color(0xFF08399F);
  static const Color darkText = Color(0xFF102A43);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final headerHeight = isMobile ? 265.0 : 295.0;
          final cardTop = isMobile ? 185.0 : 203.0;

          return SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  color: primaryBlue,
                  child: Column(
                    children: [
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Volver a WellQ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 135),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'WellQ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reserva de Horas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 32 : 43,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: cardTop,
                    left: isMobile ? 16 : 24,
                    right: isMobile ? 16 : 24,
                    bottom: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 50,
                          vertical: isMobile ? 30 : 46,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.09),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.apartment_rounded,
                                  color: Color(0xFF2463FF),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '¿Qué tipo de atención necesitas?',
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            _expressCard(context),

                            const SizedBox(height: 30),

                            LayoutBuilder(
                              builder: (context, box) {
                                final width = box.maxWidth;
                                final columns = width >= 820
                                    ? 4
                                    : width >= 480
                                    ? 2
                                    : 1;
                                final spacing = width < 480 ? 12.0 : 20.0;
                                final itemWidth =
                                    (width - spacing * (columns - 1)) / columns;

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: 20,
                                  children: [
                                    _serviceCard(
                                      context,
                                      width: itemWidth,
                                      title: 'Consulta\nPresencial',
                                      icon: Icons.person_outline,
                                      color: const Color(0xFF2F80FF),
                                      background: const Color(0xFFEDF5FF),
                                    ),
                                    _serviceCard(
                                      context,
                                      width: itemWidth,
                                      title: 'Consulta\nTelemedicina',
                                      icon: Icons.videocam_outlined,
                                      color: const Color(0xFF00A7E8),
                                      background: const Color(0xFFEDF9FF),
                                    ),
                                    _serviceCard(
                                      context,
                                      width: itemWidth,
                                      title: 'Exámenes y\nProcedimientos',
                                      icon: Icons.assignment_outlined,
                                      color: const Color(0xFF00C853),
                                      background: const Color(0xFFEEFCF3),
                                    ),
                                    _serviceCard(
                                      context,
                                      width: itemWidth,
                                      title: 'Vacunatorio',
                                      icon: Icons.science_outlined,
                                      color: const Color(0xFFA744FF),
                                      background: const Color(0xFFFAF1FF),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 38),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => _comingSoon(context),
                                  child: const Text(
                                    'Modificar Hora',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '|',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _comingSoon(context),
                                  child: const Text(
                                    'Anular Hora',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _expressCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _comingSoon(context),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2463FF), Color(0xFF5131DD)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2534AD).withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 42,
                    color: Color(0xFFFFE600),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserva Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tu salud no espera, nosotros tampoco.',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context, {
    required double width,
    required String title,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return SizedBox(
      width: width,
      height: width >= 300 ? 220 : 240,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.20), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _comingSoon(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 35),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: background,
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estamos preparando esta funcionalidad de reservas.'),
      ),
    );
  }
}
