import 'package:flutter/material.dart';
import 'package:medicore/models/doctor_model.dart';

class DoctorCardAdmin extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const DoctorCardAdmin({
    super.key,
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          title: Text(
            doctor.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          // Premium badge line in trailing of title area could be added in subtitle
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.specialty,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: doctor.verificationStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: doctor.verificationStatusColor),
                ),
                child: Text(
                  doctor.verificationStatusDisplay,
                  style: TextStyle(
                    color: doctor.verificationStatusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (doctor.consultationFee != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_rounded,
                              size: 14, color: Colors.blue.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Fee: ${doctor.consultationFeeText}',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              if (doctor.isPremium)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 14, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor.email,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (doctor.phone != null && doctor.phone!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.phone!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: doctor.isAvailable
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      doctor.isAvailable ? 'Available' : 'Busy',
                      style: TextStyle(
                        color: doctor.isAvailable
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onApprove != null && doctor.verificationStatus != 'verified')
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.verified_rounded,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    onPressed: onApprove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              if (onReject != null && doctor.verificationStatus != 'rejected')
                const SizedBox(width: 8),
              if (onReject != null && doctor.verificationStatus != 'rejected')
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.shade200,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.block_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    onPressed: onReject,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              if (onApprove != null || onReject != null)
                const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
