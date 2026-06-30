// Modern Admin Home Screen - Complete Redesign
// ignore_for_file: use_build_context_synchronously, avoid_print, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medicore/config/routes.dart';

class AdminHomeModern extends StatefulWidget {
  const AdminHomeModern({super.key});

  @override
  State<AdminHomeModern> createState() => _AdminHomeModernState();
}

class _AdminHomeModernState extends State<AdminHomeModern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildModernAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildRealTimeStats(),
            const SizedBox(height: 20),
            _buildManagementCards(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
            const SizedBox(height: 20),
            _buildSystemHealth(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'System Overview & Management',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.notifications),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.settings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LiveStatCard(
                title: 'Total Users',
                icon: Icons.people_rounded,
                color: Colors.blue,
                query: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots()
                    .map((snap) => snap.docs.length),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiveStatCard(
                title: 'Doctors',
                icon: Icons.medical_services_rounded,
                color: Colors.purple,
                query: FirebaseFirestore.instance
                    .collection('doctors')
                    .where('isVerified', isEqualTo: true)
                    .snapshots()
                    .map((snap) => snap.docs.length),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiveStatCard(
                title: 'Appointments',
                icon: Icons.calendar_today_rounded,
                color: Colors.orange,
                query: FirebaseFirestore.instance
                    .collection('appointments')
                    .snapshots()
                    .map((snap) => snap.docs.length),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCards() {
    final cards = [
      _ManagementCard(
        icon: Icons.people_outline_rounded,
        label: 'Manage Users',
        subtitle: 'View & manage patients',
        color: Colors.blue,
        gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
        route: Routes.adminManageUsers,
        streamCount: FirebaseFirestore.instance
            .collection('users')
            .snapshots()
            .map((snap) => snap.docs.length),
      ),
      _ManagementCard(
        icon: Icons.medical_services_rounded,
        label: 'Manage Doctors',
        subtitle: 'Approve & manage doctors',
        color: Colors.purple,
        gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
        route: Routes.adminManageDoctors,
        streamCount: FirebaseFirestore.instance
            .collection('doctors')
            .snapshots()
            .map((snap) => snap.docs.length),
      ),
      _ManagementCard(
        icon: Icons.calendar_month_rounded,
        label: 'Appointments',
        subtitle: 'Monitor all bookings',
        color: Colors.cyan,
        gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
        route: Routes.adminManageAppointments,
        streamCount: FirebaseFirestore.instance
            .collection('appointments')
            .snapshots()
            .map((snap) => snap.docs.length),
      ),
      _ManagementCard(
        icon: Icons.store_rounded,
        label: 'Manage Store',
        subtitle: 'Medicine inventory',
        color: Colors.green,
        gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
        route: Routes.adminManageStore,
        streamCount: FirebaseFirestore.instance
            .collection('medicines')
            .snapshots()
            .map((snap) => snap.docs.length),
      ),
      _ManagementCard(
        icon: Icons.shopping_bag_rounded,
        label: 'Orders',
        subtitle: 'Track all orders',
        color: Colors.amber,
        gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
        route: Routes.adminManageOrders,
        streamCount: FirebaseFirestore.instance
            .collection('orders')
            .snapshots()
            .map((snap) => snap.docs.length),
      ),
      _ManagementCard(
        icon: Icons.analytics_rounded,
        label: 'Analytics',
        subtitle: 'AI insights & reports',
        color: Colors.teal,
        gradient: const [Color(0xFF30cfd0), Color(0xFF330867)],
        route: Routes.adminAnalytics,
        streamCount: const Stream.empty(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .orderBy('appointmentDate', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final appointments = snapshot.data!.docs;
            if (appointments.isEmpty) {
              return _EmptyState(
                icon: Icons.history_rounded,
                message: 'No recent activity',
              );
            }

            return Column(
              children: appointments.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date =
                    (data['appointmentDate'] as Timestamp?)?.toDate();
                return _ActivityTile(
                  title: data['patientName'] ?? 'Unknown',
                  subtitle:
                      data['doctorName'] ?? 'Unassigned Doctor',
                  status: data['status'] ?? 'pending',
                  date: date,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSystemHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Health',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HealthMetric(
                label: 'Database',
                status: 'Healthy',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthMetric(
                label: 'Auth Service',
                status: 'Healthy',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthMetric(
                label: 'Storage',
                status: 'Healthy',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════ Components ════════════════════

class _LiveStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<int> query;

  const _LiveStatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: StreamBuilder<int>(
        stream: query,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final List<Color> gradient;
  final String route;
  final Stream<int> streamCount;

  const _ManagementCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.route,
    required this.streamCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      StreamBuilder<int>(
                        stream: streamCount,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime? date;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_rounded,
                color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    DateFormat('MMM d').format(date!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _HealthMetric({
    required this.label,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
