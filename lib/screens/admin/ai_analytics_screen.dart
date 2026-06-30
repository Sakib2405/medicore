import 'package:flutter/material.dart';
import 'package:medicore/widgets/admin/analytics_card.dart'; // Assuming this widget exists
// import 'package:charts_flutter/flutter.dart' as charts; // If you use charts

class AiAnalyticsScreen extends StatelessWidget {
  const AiAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You would fetch real analytics from your AiProvider
    // final provider = Provider.of<AiProvider>(context);

    // Mock data for analytics
    final Map<String, dynamic> analytics = {
      'totalUsers': 120,
      'totalAppointments': 350,
      'commonSymptom': 'Fever',
      'peakHours': '10:00 AM',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid of key metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                AnalyticsCard(
                  title: 'Total Users',
                  value: analytics['totalUsers'].toString(),
                  icon: Icons.people,
                ),
                AnalyticsCard(
                  title: 'Total Appointments',
                  value: analytics['totalAppointments'].toString(),
                  icon: Icons.calendar_today,
                ),
                AnalyticsCard(
                  title: 'Top Symptom',
                  value: analytics['commonSymptom'],
                  icon: Icons.local_fire_department,
                ),
                AnalyticsCard(
                  title: 'Peak Booking Hour',
                  value: analytics['peakHours'],
                  icon: Icons.access_time,
                ),
              ],
            ),
            const Divider(height: 40),

            // Example Chart Section
            const Text(
              'User Registration Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text('A chart would go here'),
                // Example:
                // charts.LineChart(
                //   _createSampleData(), // Your chart data
                //   animate: true,
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
