// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;


  // Top stats (real-time)
  int? _totalUsers;
  int? _totalAppointments;
  int? _totalOrders;
  double? _totalRevenue;

  // Real pending counts for badge badges
  int _pendingDoctors = 0;
  int _pendingAppointments = 0;
  int _pendingOrders = 0;

  bool _loadingStats = true;
  bool _loadingUsage = true; // ignore: prefer_final_fields

  // Stream subscriptions for real-time stats
  StreamSubscription<QuerySnapshot>? _usersSub;
  StreamSubscription<QuerySnapshot>? _appointmentsSub;
  StreamSubscription<QuerySnapshot>? _ordersSub;

  // Usage history (last 7 days)
  late final List<DateTime> _days;
  List<int> _newUsersPerDay = List.filled(7, 0);
  List<int> _appointmentsPerDay = List.filled(7, 0);
  List<int> _ordersPerDay = List.filled(7, 0);

  List<_DashboardCardData> get _cards => [
    _DashboardCardData(
      icon: Icons.people_outline,
      label: 'Manage Users',
      colors: const [Color(0xFF667eea), Color(0xFF764ba2)],
      route: Routes.adminManageUsers,
      notificationCount: _pendingDoctors > 0 ? _pendingDoctors : null,
    ),
    const _DashboardCardData(
      icon: Icons.medical_services_outlined,
      label: 'Manage Doctors',
      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      route: Routes.adminManageDoctors,
    ),
    _DashboardCardData(
      icon: Icons.calendar_today_outlined,
      label: 'Appointments',
      colors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
      route: Routes.adminManageAppointments,
      notificationCount: _pendingAppointments > 0 ? _pendingAppointments : null,
    ),
    const _DashboardCardData(
      icon: Icons.store_outlined,
      label: 'Manage Store',
      colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
      route: Routes.adminManageStore,
    ),
    _DashboardCardData(
      icon: Icons.shopping_bag_outlined,
      label: 'Orders',
      colors: const [Color(0xFFfa709a), Color(0xFFfee140)],
      route: Routes.adminManageOrders,
      notificationCount: _pendingOrders > 0 ? _pendingOrders : null,
    ),
    const _DashboardCardData(
      icon: Icons.analytics_outlined,
      label: 'AI Analytics',
      colors: [Color(0xFF30cfd0), Color(0xFF330867)],
      route: Routes.adminAnalytics,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<double>(begin: 16, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Init days for usage graph (last 7 days)
    final now = DateTime.now();
    _days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    _subscribeToStats();
    _loadUsageHistory();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _appointmentsSub?.cancel();
    _ordersSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _subscribeToStats() {
    final fs = FirebaseFirestore.instance;

    _usersSub = fs.collection('users').snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _totalUsers = snap.docs.length;
        _pendingDoctors = snap.docs
            .where((d) =>
                d.data()['role'] == 'doctor' &&
                (d.data()['isUserVerified'] == false ||
                    d.data()['isUserVerified'] == null))
            .length;
        _loadingStats = false;
      });
    });

    _appointmentsSub =
        fs.collection('appointments').snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _totalAppointments = snap.docs.length;
        _pendingAppointments = snap.docs
            .where((d) => d.data()['status'] == 'pending')
            .length;
      });
    });

    _ordersSub = fs.collection('orders').snapshots().listen((snap) {
      if (!mounted) return;
      double revenue = 0;
      for (final d in snap.docs) {
        final amt = d.data()['totalAmount'] ?? d.data()['totalPrice'];
        if (amt != null) revenue += (amt as num).toDouble();
      }
      setState(() {
        _totalOrders = snap.docs.length;
        _totalRevenue = revenue;
        _pendingOrders = snap.docs
            .where((d) => d.data()['status'] == 'pending')
            .length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final crossAxisCount = isNarrow ? 1 : 2;
                    return ListView(
                      children: [
                        _StatsRow(
                          users: _totalUsers,
                          appointments: _totalAppointments,
                          revenue: _totalRevenue,
                          orders: _totalOrders,
                          loading: _loadingStats,
                          onViewDetails: () => Navigator.pushNamed(
                              context, Routes.adminAnalytics),
                        ),
                        const SizedBox(height: 16),
                        _UsageChart(
                          days: _days,
                          newUsers: _newUsersPerDay,
                          appointments: _appointmentsPerDay,
                          orders: _ordersPerDay,
                          loading: _loadingUsage,
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isNarrow ? 2.8 : 2.2,
                          ),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) => _DashboardCard(
                            data: _cards[index],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ===== Usage history chart =====
  Future<void> _loadUsageHistory() async {
    try {
      final start = _days.first;
      final fs = FirebaseFirestore.instance;

      // Users by createdAt
      final usersSnap = await fs
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      final usersEach = List<int>.filled(7, 0);
      for (final d in usersSnap.docs) {
        final ts = d['createdAt'];
        final date = ts is Timestamp ? ts.toDate() : null;
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        final idx = _days.indexOf(day);
        if (idx != -1) usersEach[idx]++;
      }

      // Appointments by createdAt (fallback appointmentDate)
      final apptSnap = await fs
          .collection('appointments')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      final apptEach = List<int>.filled(7, 0);
      for (final d in apptSnap.docs) {
        DateTime? date;
        final created = d['createdAt'];
        if (created is Timestamp) {
          date = created.toDate();
        } else {
          final appt = d['appointmentDate'];
          if (appt is Timestamp) date = appt.toDate();
        }
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        final idx = _days.indexOf(day);
        if (idx != -1) apptEach[idx]++;
      }

      // Orders by orderDate
      final orderSnap = await fs
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      final orderEach = List<int>.filled(7, 0);
      for (final d in orderSnap.docs) {
        final ts = d['orderDate'];
        final date = ts is Timestamp ? ts.toDate() : null;
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        final idx = _days.indexOf(day);
        if (idx != -1) orderEach[idx]++;
      }

      setState(() {
        _newUsersPerDay = usersEach;
        _appointmentsPerDay = apptEach;
        _ordersPerDay = orderEach;
      });
    } catch (_) {
      // keep defaults (zeros)
      setState(() {});
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _QuickActionItem(
                        icon: Icons.add_chart, label: 'Add Report'),
                    _QuickActionItem(
                        icon: Icons.download, label: 'Export Data'),
                    _QuickActionItem(icon: Icons.qr_code, label: 'Scan QR'),
                    _QuickActionItem(icon: Icons.chat, label: 'Support Chat'),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCardData {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final String route;
  final int? notificationCount;

  const _DashboardCardData({
    required this.icon,
    required this.label,
    required this.colors,
    required this.route,
    this.notificationCount,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardCardData data;
  const _DashboardCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pushNamed(context, data.route),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: data.colors),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: Colors.black87, size: 22),
              ),
            ),
            if (data.notificationCount != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.notificationCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.maybePop(context),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ===== Stats Row =====
class _StatsRow extends StatelessWidget {
  final int? users;
  final int? appointments;
  final double? revenue;
  final int? orders;
  final bool loading;
  final VoidCallback? onViewDetails;

  const _StatsRow({
    required this.users,
    required this.appointments,
    required this.revenue,
    required this.orders,
    this.loading = false,
    this.onViewDetails,
  });

  String _k(int? v) {
    if (v == null) return '—';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  String _taka(double? amount) {
    if (amount == null) return '—';
    final format = NumberFormat.compactCurrency(symbol: '৳', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
          title: 'Total Users', value: _k(users), color: Colors.deepPurple),
      _StatTile(
          title: 'Appointments', value: _k(appointments), color: Colors.teal),
      _StatTile(title: 'Revenue', value: _taka(revenue), color: Colors.indigo),
      _StatTile(title: 'Orders', value: _k(orders), color: Colors.orange),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Overview',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (onViewDetails != null)
                  TextButton(
                      onPressed: onViewDetails,
                      child: const Text('View Details')),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              if (loading) {
                // show shimmer placeholders
                if (isNarrow) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                                width: 200,
                                height: 80,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    ),
                  ).toList(),
                );
              }

              if (isNarrow) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: tiles
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(width: 200, child: t),
                            ))
                        .toList(),
                  ),
                );
              }

              return Row(
                children: tiles
                    .map((t) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: t,
                          ),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatTile(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ===== Usage Chart =====
class _UsageChart extends StatelessWidget {
  final List<DateTime> days;
  final List<int> newUsers;
  final List<int> appointments;
  final List<int> orders;
  final bool loading;
  const _UsageChart({
    required this.days,
    required this.newUsers,
    required this.appointments,
    required this.orders,
    this.loading = false,
  });

  List<FlSpot> _spots(List<int> xs) => [
        for (int i = 0; i < xs.length; i++)
          FlSpot(i.toDouble(), xs[i].toDouble())
      ];

  @override
  Widget build(BuildContext context) {
    String label(int i) => '${days[i].day}/${days[i].month}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Usage (last 7 days)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.adminAnalytics),
                    child: const Text('View Details')),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              SizedBox(
                height: 220,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8))),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData:
                        const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 28)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(label(i),
                                    style: const TextStyle(fontSize: 10)));
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                          spots: _spots(newUsers),
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 3,
                          dotData: const FlDotData(show: false)),
                      LineChartBarData(
                          spots: _spots(appointments),
                          isCurved: true,
                          color: Colors.teal,
                          barWidth: 3,
                          dotData: const FlDotData(show: false)),
                      LineChartBarData(
                          spots: _spots(orders),
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: const FlDotData(show: false)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: const [
                _Legend(color: Colors.deepPurple, label: 'New Users'),
                _Legend(color: Colors.teal, label: 'Appointments'),
                _Legend(color: Colors.orange, label: 'Orders'),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
