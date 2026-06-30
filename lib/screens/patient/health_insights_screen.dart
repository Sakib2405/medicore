import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/models/health_insight_model.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/health_ai_provider.dart';
import 'package:medicore/widgets/patient/health_insight_card.dart';

class HealthInsightsScreen extends StatelessWidget {
  const HealthInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.watch<AuthProvider>().currentUser?.id ?? '';
    final provider = context.read<HealthAIProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: userId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<HealthInsightModel>>(
              stream: provider.insightsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                final insights = snapshot.data ?? [];

                if (insights.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.insights_outlined,
                              size: 52, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        const Text('No Health Insights Yet',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Your health insights will appear here\nas you track your vitals and activities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final insight = insights[index];
                    return HealthInsightCard(
                      insight: insight,
                      onViewDetail: () {},
                      onTakeAction: insight.actionableLink != null
                          ? () => Navigator.pushNamed(
                              context, insight.actionableLink!)
                          : null,
                    );
                  },
                );
              },
            ),
    );
  }
}
