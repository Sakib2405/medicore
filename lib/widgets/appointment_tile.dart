import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment_model.dart';
import '../providers/appointment_provider.dart';

class AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  const AppointmentTile({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AppointmentProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          'Doctor ID: ${appointment.doctorId}', // Changed to Doctor ID
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed: Use appointmentTime
            Text(
                'Time: ${DateFormat.yMMMd().add_jm().format(appointment.appointmentTime)}'),
            const SizedBox(height: 4),
            // Fixed: Use patientId
            Text('Patient ID: ${appointment.patientId}'),
            const SizedBox(height: 2),
            // Fixed: Use reason
            Text('Reason: ${appointment.reason}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            // Removed 'edit' logic
            if (value == 'cancel') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  // Changed from Delete to Cancel
                  title: const Text('Cancel Appointment?'),
                  content: const Text(
                      'Are you sure you want to cancel this appointment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes, Cancel'), // Changed button text
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Fixed: Call cancelAppointment
                await prov.cancelAppointment(
                    appointment.id, appointment.patientId);
              }
            }
          },
          itemBuilder: (_) => const [
            // Fixed: Changed to 'cancel'
            PopupMenuItem(value: 'cancel', child: Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
