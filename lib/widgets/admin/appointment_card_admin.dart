// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppointmentCardAdmin extends StatelessWidget {
  final String patientName;
  final String doctorName;
  final String date;
  final String status;
  final String? time;
  final String? reason;
  final double? consultationFee;
  final String? specialty;
  final bool? isPaid;
  final VoidCallback? onApprove;
  final VoidCallback onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onViewDetails;

  const AppointmentCardAdmin({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.status,
    this.time,
    this.reason,
    this.consultationFee,
    this.specialty,
    this.isPaid,
    this.onApprove,
    required this.onCancel,
    this.onComplete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'With $doctorName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (specialty != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          specialty!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date and Time Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(date),
                if (time != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(time!),
                ],
              ],
            ),

            // Consultation Fee Row
            if (consultationFee != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('৳${consultationFee!.toStringAsFixed(2)}'),
                  if (isPaid != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      isPaid! ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: isPaid! ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaid! ? 'Paid' : 'Pending Payment',
                      style: TextStyle(
                        color: isPaid! ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Reason
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View Details Button
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
                  ),

                // Cancel Button
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                // Complete Button (for confirmed appointments)
                if (onComplete != null)
                  ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Complete'),
                  ),

                // Approve Button (for pending appointments)
                if (onApprove != null)
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method to determine which buttons to show based on status
  static bool shouldShowApproveButton(String status) {
    return status.toLowerCase() == 'pending';
  }

  static bool shouldShowCompleteButton(String status) {
    return status.toLowerCase() == 'confirmed';
  }

  static bool shouldShowCancelButton(String status) {
    return status.toLowerCase() != 'cancelled' &&
        status.toLowerCase() != 'completed';
  }
}
