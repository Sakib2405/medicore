// lib/widgets/appointment_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicore/models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final bool showStatus;
  final bool showActions;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    this.showStatus = true,
    this.showActions = false,
    this.onCancel,
    this.onReschedule,
  });

  bool get isPast => appointment.appointmentDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return appointment.appointmentDate.year == now.year &&
        appointment.appointmentDate.month == now.month &&
        appointment.appointmentDate.day == now.day;
  }

  bool get isUpcoming => !isPast && appointment.status == 'confirmed';
  bool get isPending => appointment.status == 'pending';
  bool get isCompleted => appointment.status == 'completed';
  bool get isCancelled => appointment.status == 'cancelled';

  Color _getStatusColor(String status) {
    return switch (status) {
      'confirmed' => const Color(0xFF10B981), // Green
      'pending' => const Color(0xFFF59E0B), // Amber
      'completed' => const Color(0xFF3B82F6), // Blue
      'cancelled' => const Color(0xFFEF4444), // Red
      _ => const Color(0xFF6B7280), // Gray
    };
  }

  Color _getStatusBackgroundColor(String status) {
    return switch (status) {
      'confirmed' => const Color(0xFFD1FAE5), // Light Green
      'pending' => const Color(0xFFFEF3C7), // Light Amber
      'completed' => const Color(0xFFDBEAFE), // Light Blue
      'cancelled' => const Color(0xFFFEE2E2), // Light Red
      _ => const Color(0xFFF3F4F6), // Light Gray
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'confirmed' => Icons.check_circle,
      'pending' => Icons.pending_actions,
      'completed' => Icons.verified,
      'cancelled' => Icons.cancel,
      _ => Icons.help,
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'confirmed' => 'Confirmed',
      'pending' => 'Pending',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Unknown',
    };
  }

  String _formatDate(DateTime date) {
    if (isToday) {
      return 'Today';
    }
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day));

    if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _formatDay(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  Widget _buildDateSection() {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: isUpcoming
            ? _getStatusBackgroundColor(appointment.status)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming
              ? _getStatusColor(appointment.status).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDay(appointment.appointmentDate),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUpcoming
                  ? _getStatusColor(appointment.status)
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(appointment.appointmentDate),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUpcoming
                  ? _getStatusColor(appointment.status)
                  : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(appointment.appointmentDate),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isUpcoming
                  ? _getStatusColor(appointment.status)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusColor = _getStatusColor(appointment.status);
    final backgroundColor = _getStatusBackgroundColor(appointment.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(appointment.status),
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(appointment.status),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!showActions || isPast || isCompleted || isCancelled) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (onReschedule != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onReschedule,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reschedule',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (onReschedule != null && onCancel != null) const SizedBox(width: 8),
        if (onCancel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color:
              isUpcoming ? statusColor.withOpacity(0.2) : Colors.grey.shade200,
          width: isUpcoming ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Time Section
                    _buildDateSection(),
                    const SizedBox(width: 16),

                    // Doctor & Appointment Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment.doctorName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      appointment.doctorSpecialty,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Reason for Visit
                          if (appointment.reason.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reason:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appointment.reason,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),

                          // Notes
                          if (appointment.notes != null &&
                              appointment.notes!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),

                          // Status and Time Slot
                          Row(
                            children: [
                              if (showStatus) _buildStatusChip(),
                              if (showStatus) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Slot: ${appointment.timeSlot}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                if (showActions) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
