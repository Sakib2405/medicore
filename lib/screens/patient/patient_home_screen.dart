// lib/screens/patient/patient_home_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:medicore/screens/patient/doctor_list_screen.dart';
import 'package:medicore/screens/patient/my_appointments_screen.dart';
import 'package:medicore/screens/patient/profile_screen.dart';
import 'package:medicore/screens/patient/store/medicine_store_screen.dart';
import 'package:medicore/screens/patient/ai_chatbot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicore/screens/patient/hospital_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/doctor_provider.dart';
import 'package:medicore/providers/hospital_provider.dart';
import 'package:medicore/providers/appointment_provider.dart';
import 'package:medicore/models/hospital_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicore/providers/notification_provider.dart';
import 'package:medicore/models/prescription.dart';
import 'package:medicore/services/prescription_service.dart';
import 'package:medicore/screens/prescriptions/prescription_remote_viewer.dart';
import 'package:medicore/config/routes.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double _bgTintOpacity = 0.25;

  bool get _premiumViewEnabled {
    final v = (dotenv.env['PREMIUM_VIEW'] ?? dotenv.env['PREMIUM'] ?? 'false')
        .toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  static const List<Map<String, dynamic>> _sections = <Map<String, dynamic>>[
    {
      'title': 'Find Doctors',
      'icon': Icons.medical_services_rounded,
      'subtitle': 'Book appointments easily',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)]
    },
    {
      'title': 'My Appointments',
      'icon': Icons.calendar_month_rounded,
      'subtitle': 'Manage your bookings',
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)]
    },
    {
      'title': 'Medicine Store',
      'icon': Icons.medication_rounded,
      'subtitle': 'Order medicines online',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)]
    },
    {
      'title': 'My Profile',
      'icon': Icons.person_rounded,
      'subtitle': 'Personal information',
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)]
    },
  ];

  // The initial list is now final as it doesn't need to change in `initState`.
  // The dynamically updated list will be created in the build method.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Precache homepage images for faster display (header + background)
      precacheImage(const AssetImage('assets/images/homepage.webp'), context);
      precacheImage(
          const AssetImage('assets/images/homepage_backround.jpg'), context);
      _loadTintOpacity();
      _loadRealData();
    });
  }

  Future<void> _loadTintOpacity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble('bg_tint_opacity');
      if (val != null) {
        setState(() {
          _bgTintOpacity = val.clamp(0.0, 0.8);
        });
      } else {
        // Fallback to .env configured default if provided
        final envVal = dotenv.env['PREMIUM_TINT'] ?? dotenv.env['BG_TINT'];
        if (envVal != null) {
          final parsed = double.tryParse(envVal);
          if (parsed != null) {
            setState(() {
              _bgTintOpacity = parsed.clamp(0.0, 0.8);
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveTintOpacity(double opacity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bg_tint_opacity', opacity);
    } catch (_) {}
  }

  void _showTintPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        double tmp = _bgTintOpacity;
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Background tint opacity',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Slider(
                  value: tmp,
                  min: 0.0,
                  max: 0.8,
                  divisions: 80,
                  label: tmp.toStringAsFixed(2),
                  onChanged: (v) => setModalState(() => tmp = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setModalState(() => tmp = 0.12);
                      },
                      child: const Text('Light'),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() => tmp = 0.25);
                      },
                      child: const Text('Default'),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() => tmp = 0.45);
                      },
                      child: const Text('Darker'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _bgTintOpacity = tmp);
                          _saveTintOpacity(tmp);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadRealData() {
    try {
      final doctorProvider =
          Provider.of<DoctorProvider>(context, listen: false);
      final hospitalProvider =
          Provider.of<HospitalProvider>(context, listen: false);
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load real data
      doctorProvider.fetchDoctors();
      hospitalProvider.fetchNearbyHospitals();

      // Load user appointments if user is logged in
      final user = authProvider.currentUser;
      if (user != null) {
        appointmentProvider.loadUserAppointments(user.id);
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAppBar() {
    final gradientColors = _sections[_selectedIndex]['gradient'] as List<Color>;
    // Header with background image + color overlay
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 140,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background layer: image (header shows a focused banner image when premium enabled, else gradient)
            if (_premiumViewEnabled)
              Image.asset(
                'assets/images/homepage.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                color: Colors.black.withOpacity(_bgTintOpacity + 0.05),
                colorBlendMode: BlendMode.darken,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // Soft overlay tinted towards the current section colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors.first.withOpacity(0.40),
                    gradientColors.last.withOpacity(0.25),
                  ],
                ),
              ),
            ),
            // Shadow
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            // Foreground content
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title and Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sections[_selectedIndex]['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sections[_selectedIndex]['subtitle'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Notification and Profile
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                                icon: Icon(Icons.menu_rounded,
                                    color: Colors.white.withOpacity(0.9)),
                                tooltip: 'Menu',
                              ),
                            ),
                            IconButton(
                              onPressed: _showTintPicker,
                              icon: Icon(
                                Icons.opacity,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              tooltip: 'Adjust background tint',
                            ),
                            Consumer<NotificationProvider>(
                              builder: (context, notifProv, _) =>
                                  _buildIconButton(
                                Icons.notifications_outlined,
                                _showNotificationPanel,
                                badgeCount: notifProv.unreadCount,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                final user = authProvider.currentUser;
                                final profilePhoto =
                                    user?.photoUrl ?? user?.profileImage;
                                return GestureDetector(
                                  onTap: () => _onItemTapped(3),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: profilePhoto != null &&
                                            profilePhoto.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              profilePhoto,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person_rounded,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  size: 24,
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            size: 24,
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Removed _buildQuickStats() from AppBar for fixed height stability.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed,
      {int? badgeCount}) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onPressed,
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFf5576c), // Red color for badge
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final upcomingCount = appointmentProvider.upcomingAppointments.length;
        final pendingCount = appointmentProvider.pendingAppointments.length;

        return Padding(
          padding: const EdgeInsets.only(
              top: 16.0, bottom: 8.0, left: 20.0, right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                  'Upcoming', upcomingCount, const Color(0xFF667eea)),
              _buildStatItem('Pending', pendingCount, const Color(0xFFf093fb)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: const Color(0xFF667eea), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${upcomingCount + pendingCount} Total',
                      style: TextStyle(
                        color: const Color(0xFF667eea),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showNotificationPanel() {
    // Mark notifications as read when opening panel
    try {
      Provider.of<NotificationProvider>(context, listen: false).markAllRead();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf093fb).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '3 New',
                        style: TextStyle(
                          color: const Color(0xFFf093fb),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<AppointmentProvider>(
                  builder: (context, appointmentProvider, child) {
                    final upcomingAppointments = appointmentProvider
                        .upcomingAppointments
                        .take(3)
                        .toList();
                    final notifications = [
                      ...upcomingAppointments
                          .map((appointment) => _NotificationItem(
                                title: 'Appointment Reminder',
                                message:
                                    'Your appointment with ${appointment.doctorName} is on ${appointment.formattedDate} at ${appointment.formattedTime}',
                                icon: Icons.calendar_today_rounded,
                                color: const Color(0xFFf093fb),
                                time: 'Upcoming',
                                type: NotificationType.appointment,
                              )),
                      _NotificationItem(
                        title: 'Health Tip',
                        message:
                            'Remember to drink 8 glasses of water daily for better health',
                        icon: Icons.health_and_safety_rounded,
                        color: const Color(0xFF43e97b),
                        time: 'Today',
                        type: NotificationType.health,
                      ),
                      _NotificationItem(
                        title: 'Medicine Reminder',
                        message: 'Time to take your prescribed medication',
                        icon: Icons.medication_rounded,
                        color: const Color(0xFF4facfe),
                        time: 'Daily',
                        type: NotificationType.medicine,
                      ),
                    ];

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(_NotificationItem notification) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  notification.color,
                  notification.color.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuad,
      padding:
          EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Profile' && isSelected)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                final profilePhoto = user?.photoUrl ?? user?.profileImage;

                return profilePhoto != null && profilePhoto.isNotEmpty
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            profilePhoto,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: isSelected ? 24 : 22,
                              );
                            },
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: isSelected ? 24 : 22,
                      );
              },
            )
          else
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: isSelected ? 24 : 22,
            ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          final photo = user?.photoUrl ?? user?.profileImage;
          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: photo != null && photo.isNotEmpty
                          ? ClipOval(
                              child: Image.network(photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 36)),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Patient',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Nav items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerItem(Icons.home_rounded, 'Home', () {
                      Navigator.pop(context);
                      _onItemTapped(0);
                    }),
                    _drawerItem(Icons.medical_services_rounded, 'Find Doctors',
                        () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DoctorListScreen()));
                    }),
                    _drawerItem(Icons.calendar_month_rounded, 'My Appointments',
                        () {
                      Navigator.pop(context);
                      _onItemTapped(1);
                    }),
                    _drawerItem(Icons.medication_rounded, 'Medicine Store', () {
                      Navigator.pop(context);
                      _onItemTapped(2);
                    }),
                    _drawerItem(Icons.description_rounded, 'My Prescriptions',
                        () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.myPrescriptions);
                    }),
                    _drawerItem(Icons.folder_special_rounded, 'Medical Records',
                        () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.medicalRecords);
                    }),
                    _drawerItem(Icons.assistant_rounded, 'AI Assistant', () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AIChatbotScreen()));
                    }),
                    _drawerItem(Icons.local_hospital_rounded, 'Nearby Hospitals',
                        () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HospitalMapScreen()));
                    }),
                    const Divider(indent: 16, endIndent: 16),
                    _drawerItem(Icons.person_rounded, 'My Profile', () {
                      Navigator.pop(context);
                      _onItemTapped(3);
                    }),
                    _drawerItem(Icons.settings_rounded, 'Settings', () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.settings);
                    }),
                    _drawerItem(Icons.notifications_rounded, 'Notifications',
                        () {
                      Navigator.pop(context);
                      _showNotificationPanel();
                    }),
                    const Divider(indent: 16, endIndent: 16),
                    _drawerItem(Icons.logout_rounded, 'Sign Out', () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().signOut();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                          context, Routes.login, (route) => false);
                    }, color: Colors.red.shade600),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final itemColor = color ?? const Color(0xFF667eea);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: itemColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: itemColor, size: 22),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
              fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Removed the unused local variable 'homeContent'.

    // This is the new HomeContentScreen instance that passes the required
    // state-dependent methods to the stateless HomeContentScreen.
    final updatedHomeContent = HomeContentScreen(
      key: const ValueKey('HomeContent'),
      onNavigate: (index) => _onItemTapped(index),
      buildQuickStats: _buildQuickStats,
      scrollController: _scrollController,
    );

    // Helper to wrap any content with background image and overlay
    Widget wrapWithBackground(Widget child, {bool parallax = false}) {
      return Stack(
        children: [
          Positioned.fill(
            child: parallax
                ? AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, bgChild) {
                      final offset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;
                      final parallaxOffset = offset * 0.2;
                      return Transform.translate(
                        offset: Offset(0, -parallaxOffset),
                        child: bgChild,
                      );
                    },
                    child: Image.asset(
                      'assets/images/homepage_backround.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(_bgTintOpacity),
                      colorBlendMode: BlendMode.darken,
                    ),
                  )
                : Image.asset(
                    'assets/images/homepage_backround.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(_bgTintOpacity),
                    colorBlendMode: BlendMode.darken,
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      );
    }

    // Wrap home with background (always), others only if premium enabled
    final homeWithBackground =
        wrapWithBackground(updatedHomeContent, parallax: true);

    // Create the list of widgets for the body, using the newly created HomeContentScreen.
    final updatedWidgetOptions = <Widget>[
      homeWithBackground,
      _premiumViewEnabled
          ? wrapWithBackground(const MyAppointmentsScreen())
          : const MyAppointmentsScreen(),
      _premiumViewEnabled
          ? wrapWithBackground(const MedicineStoreScreen())
          : const MedicineStoreScreen(),
      _premiumViewEnabled
          ? wrapWithBackground(const ProfileScreen())
          : const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: _buildDrawer(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: _buildAppBar(),
      ),
      body: updatedWidgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => _onItemTapped(0),
              child: _buildBottomNavItem(
                Icons.medical_services_rounded,
                'Home',
                _selectedIndex == 0,
                const Color(0xFF667eea),
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(1),
              child: _buildBottomNavItem(
                Icons.calendar_month_rounded,
                'Appointments',
                _selectedIndex == 1,
                const Color(0xFFf093fb),
              ),
            ),
            // Placeholder for FAB space
            const SizedBox(width: 48),
            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: _buildBottomNavItem(
                Icons.medication_rounded,
                'Store',
                _selectedIndex == 2,
                const Color(0xFF4facfe),
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(3),
              child: _buildBottomNavItem(
                Icons.person_rounded,
                'Profile',
                _selectedIndex == 3,
                const Color(0xFF43e97b),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showQuickActions,
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 460,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 20),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 3,
                  childAspectRatio: 0.95,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  children: [
                    _buildQuickActionItem(
                      Icons.medical_services_rounded,
                      'Find Doctor',
                      const Color(0xFF667eea),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      Icons.medication_rounded,
                      'Buy Medicine',
                      const Color(0xFF4facfe),
                      () {
                        Navigator.pop(context);
                        _onItemTapped(2);
                      },
                    ),
                    _buildQuickActionItem(
                      Icons.assistant_rounded,
                      'AI Assistant',
                      const Color(0xFFf093fb),
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIChatbotScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      Icons.emergency_rounded,
                      'Emergency',
                      const Color(0xFFf5576c),
                      () => _showEmergencyDialog(),
                    ),
                    _buildQuickActionItem(
                      Icons.local_hospital_rounded,
                      'Hospitals',
                      const Color(0xFF43e97b),
                      () => _showHospitalsMap(),
                    ),
                    _buildQuickActionItem(
                      Icons.health_and_safety_rounded,
                      'Health Tips',
                      const Color(0xFFff9a9e),
                      () => _showHealthTipsDialog(),
                    ),
                    _buildQuickActionItem(
                      Icons.description_rounded,
                      'Prescriptions',
                      const Color(0xFF667eea),
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.myPrescriptions);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    Navigator.pop(context); // Close Quick Actions bottom sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade500, Colors.red.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade700.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emergency_rounded,
                    color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildEmergencyContactItem(
                    'Ambulance', '102', Icons.medical_services_rounded),
                _buildEmergencyContactItem(
                    'Police', '100', Icons.security_rounded),
                _buildEmergencyContactItem(
                    'Fire', '101', Icons.fire_extinguisher_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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

  void _showHospitalsMap() {
    Navigator.pop(context); // Close Quick Actions bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HospitalMapScreen(),
      ),
    );
  }

  Widget _buildEmergencyContactItem(String name, String number, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 28),
            onPressed: () => _makePhoneCall(number),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHealthTipsDialog() {
    Navigator.pop(context); // Close Quick Actions bottom sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text(
              'Daily Health Tips',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHealthTip(
                    '💧 Drink 8 glasses of water daily for hydration'),
                _buildHealthTip('🏃 Exercise 30 minutes daily for fitness'),
                _buildHealthTip(
                    '🥗 Eat balanced meals with fruits & vegetables'),
                _buildHealthTip('😴 Get 7-8 hours of quality sleep nightly'),
                _buildHealthTip('🧘 Practice stress management techniques'),
                _buildHealthTip(
                    '🚭 Avoid smoking and limit alcohol consumption'),
                _buildHealthTip(
                    '🧼 Wash hands regularly to prevent infections'),
                _buildHealthTip('☀️ Get sunlight for Vitamin D synthesis'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got It',
              style: TextStyle(
                  color: Color(0xFF667eea), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF43e97b), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                  fontSize: 15, height: 1.4, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  final Widget Function() buildQuickStats;
  final Function(int) onNavigate;
  final ScrollController scrollController;

  const HomeContentScreen(
      {super.key,
      required this.buildQuickStats,
      required this.onNavigate,
      required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Quick Stats moved here from AppBar
          buildQuickStats(),
          const SizedBox(height: 16),
          _buildWelcomeCard(context),
          const SizedBox(height: 32),
          _buildServicesGrid(context, onNavigate),
          const SizedBox(height: 32),
          _buildDoctorRecommendations(context),
          const SizedBox(height: 32),
          _buildHealthTips(),
          const SizedBox(height: 32),
          _buildPrescriptionsSection(context),
          const SizedBox(height: 32),
          _buildNearestHospitalCard(context),
          const SizedBox(height: 32),
          _buildNearbyHospitals(context),
          const SizedBox(height: 24),
          _buildDoctorBottomCTA(context),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      final userName =
                          user != null ? user.name.split(' ').first : 'there';
                      return Text(
                        'Hello, $userName! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your health journey starts here. Book appointments, order medicines.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DoctorListScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667eea),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.assistant_rounded,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIChatbotScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Profile image/placeholder
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                final profilePhoto = user?.photoUrl ?? user?.profileImage;

                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: profilePhoto != null && profilePhoto.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            profilePhoto,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context, Function(int) onNavigate) {
    final services = [
      {
        'icon': Icons.medical_services_rounded,
        'title': 'Find Doctor',
        'color': const Color(0xFF667eea),
        'subtitle': 'Specialist Doctors',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DoctorListScreen(),
            ),
          );
        }
      },
      {
        'icon': Icons.medication_rounded,
        'title': 'Medicines',
        'color': const Color(0xFF4facfe),
        'subtitle': 'Pharmacy Store',
        'onTap': () => onNavigate(2) // Directly navigate using bottom nav
      },
      {
        'icon': Icons.assistant_rounded,
        'title': 'AI Assistant',
        'color': const Color(0xFFf093fb),
        'subtitle': 'Health Support',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIChatbotScreen(),
            ),
          );
        }
      },
      {
        'icon': Icons.local_hospital_rounded,
        'title': 'Hospitals',
        'color': const Color(0xFF43e97b),
        'subtitle': 'Nearby Locations',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HospitalMapScreen(),
            ),
          );
        }
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.05,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceItem(
                  service['icon'] as IconData,
                  service['title'] as String,
                  service['subtitle'] as String,
                  service['color'] as Color,
                  service['onTap'] as VoidCallback,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorRecommendations(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Doctors',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorListScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF667eea),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: const Color(0xFF667eea), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<DoctorProvider>(
              builder: (context, doctorProvider, child) {
                if (doctorProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doctors = doctorProvider.doctors.take(4).toList();
                if (doctors.isEmpty) {
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_rounded,
                            color: Colors.grey.shade400, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No doctors available',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                // Used SizedBox with height to prevent overflow and enable horizontal scrolling
                return SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return Container(
                        width: 170,
                        margin: EdgeInsets.only(
                            right: index == doctors.length - 1 ? 0 : 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: doctor.profileImage != null &&
                                      doctor.profileImage!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        doctor.profileImage!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dr. ${doctor.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialization,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber.shade600, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.rating.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: doctor.isAvailable
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    doctor.isAvailable ? 'Available' : 'Busy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: doctor.isAvailable
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43e97b).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Health Tip 💡',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay hydrated by drinking at least 8 glasses of water daily. Proper hydration improves energy levels and brain function.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyHospitals(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Hospitals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HospitalMapScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43e97b).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Map',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF43e97b),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.map_rounded,
                          color: const Color(0xFF43e97b), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer<HospitalProvider>(
            builder: (context, hospitalProvider, child) {
              if (hospitalProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final hospitals = hospitalProvider.hospitals.take(3).toList();
              if (hospitals.isEmpty) {
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital_rounded,
                          color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No hospitals found nearby',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: hospitals
                    .map((hospital) => _buildHospitalItem(context, hospital))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final patientId = authProvider.currentUser?.id ?? '';
        if (patientId.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Prescriptions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.myPrescriptions),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Color(0xFF667eea), size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Prescription>>(
                stream:
                    PrescriptionService.streamPatientPrescriptions(patientId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final prescriptions =
                      (snapshot.data ?? []).take(3).toList();
                  if (prescriptions.isEmpty) {
                    return _buildEmptyPrescriptions();
                  }
                  return Column(
                    children: prescriptions
                        .map((p) => _buildPrescriptionCard(context, p))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, Prescription p) {
    final date = p.createdAt.toDate();
    final formatted =
        '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.medicines.length} Medicine${p.medicines.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  p.doctorName != null && p.doctorName!.isNotEmpty
                      ? 'Dr. ${p.doctorName}'
                      : 'Doctor',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (p.notes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    p.notes,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PrescriptionRemoteViewer(prescription: p),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrescriptions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined,
                size: 36, color: Color(0xFF667eea)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No prescriptions yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Prescriptions from your doctors will appear here',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNearestHospitalCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Consumer<HospitalProvider>(
        builder: (context, hospitalProvider, _) {
          if (hospitalProvider.isLoading) return const SizedBox.shrink();

          // Prefer nearest within 10km; fallback to first available hospital
          final nearestList = hospitalProvider.nearestHospitals;
          Hospital? nearest;
          if (nearestList.isNotEmpty) {
            nearest = nearestList.first;
          } else if (hospitalProvider.hospitals.isNotEmpty) {
            nearest = hospitalProvider.hospitals.first;
          }

          if (nearest == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF43e97b).withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearest Hospital',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nearest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${nearest.distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _openGoogleMapsByName(context, nearest!.name),
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text(
                      'Directions',
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorBottomCTA(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Color(0xFF667eea)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need a doctor now?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Browse specialists and book instantly',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Find Doctor'),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalItem(BuildContext context, Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_hospital_rounded,
                color: Colors.red.shade600, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hospital.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      hospital.rating.toString(),
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_rounded,
                        color: const Color(0xFF667eea), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${hospital.distance} km',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.directions_rounded,
                color: const Color(0xFF667eea), size: 28),
            onPressed: () => _openGoogleMapsByName(context, hospital.name),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMapsByName(
      BuildContext context, String destinationName) async {
    final dest = Uri.encodeComponent(destinationName);
    final Uri url =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest');
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum NotificationType {
  appointment,
  health,
  medicine,
  emergency,
}

class _NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final NotificationType type;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.type,
  });
}
