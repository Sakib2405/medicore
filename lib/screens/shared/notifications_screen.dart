// ignore_for_file: unused_import, deprecated_member_use, depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/models/appointment_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final snapshot = await _firestore
            .collection('notifications')
            .doc(user.id)
            .collection('user_notifications')
            .where('isRead', isEqualTo: false)
            .get();

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Marked ${snapshot.docs.length} notifications as read'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          if (user != null)
            _isLoading
                ? Container(
                    padding: const EdgeInsets.all(8),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    onPressed: _markAllAsRead,
                  ),
        ],
      ),
      body: user == null
          ? _buildNotLoggedInState()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .doc(user.id)
                  .collection('user_notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final notifications = snapshot.data!.docs;

                return Column(
                  children: [
                    _buildNotificationStats(notifications),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final data =
                                notification.data() as Map<String, dynamic>;
                            return _buildNotificationItem(
                                notification.id, data);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: Colors.grey,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please log in to view notifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.blue.shade300,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats(List<QueryDocumentSnapshot> notifications) {
    final unreadCount = notifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isRead'] == false;
    }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount unread • ${notifications.length} total',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0 && !_isLoading)
            ElevatedButton(
              onPressed: _markAllAsRead,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Mark all read'),
            ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
      child: ListTile(
        leading: _getNotificationIcon(type),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimeAgo(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(id, data),
        onLongPress: () => _showNotificationOptions(id),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    final iconData = switch (type) {
      'appointment' => Icons.calendar_today_rounded,
      'order' => Icons.shopping_bag_rounded,
      'medical' => Icons.medical_information_rounded,
      'prescription' => Icons.description_rounded,
      'reminder' => Icons.alarm_rounded,
      _ => Icons.notifications_rounded,
    };

    final color = switch (type) {
      'appointment' => Colors.blue,
      'order' => Colors.green,
      'medical' => Colors.red,
      'prescription' => Colors.orange,
      'reminder' => Colors.purple,
      _ => Colors.grey,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _handleNotificationTap(
      String id, Map<String, dynamic> data) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && !data['isRead']) {
      await _firestore
          .collection('notifications')
          .doc(user.id)
          .collection('user_notifications')
          .doc(id)
          .update({'isRead': true});
    }

    final type = data['type'] ?? 'general';
    final payload = data['payload'] ?? {};

    // PROPERLY USE ALL VARIABLES FOR NAVIGATION
    switch (type) {
      case 'appointment':
        final appointmentId = payload['appointmentId'];
        if (appointmentId != null && appointmentId is String) {
          // Navigate to appointment details using the appointmentId
          await _navigateToAppointmentDetails(appointmentId);
        } else {
          _showNotificationDetailDialog(
            title: data['title'] ?? 'Appointment Notification',
            body: data['body'] ?? '',
            type: type,
          );
        }
        break;

      case 'order':
        final orderId = payload['orderId'];
        if (orderId != null && orderId is String) {
          // Navigate to order details using the orderId
          _navigateToOrderDetails(orderId);
        } else {
          _showNotificationDetailDialog(
            title: data['title'] ?? 'Order Notification',
            body: data['body'] ?? '',
            type: type,
          );
        }
        break;

      case 'medical':
        final recordId = payload['recordId'];
        if (recordId != null && recordId is String) {
          // Navigate to medical records using the recordId
          _navigateToMedicalRecords(recordId);
        } else {
          _showNotificationDetailDialog(
            title: data['title'] ?? 'Medical Notification',
            body: data['body'] ?? '',
            type: type,
          );
        }
        break;

      case 'prescription':
        final prescriptionId = payload['prescriptionId'];
        if (prescriptionId != null && prescriptionId is String) {
          // Navigate to prescription details
          _navigateToPrescriptionDetails(prescriptionId);
        } else {
          _showNotificationDetailDialog(
            title: data['title'] ?? 'Prescription Notification',
            body: data['body'] ?? '',
            type: type,
          );
        }
        break;

      default:
        _showNotificationDetailDialog(
          title: data['title'] ?? 'Notification',
          body: data['body'] ?? '',
          type: type,
        );
    }
  }

  // NAVIGATION METHODS THAT PROPERLY USE THE VARIABLES
  Future<void> _navigateToAppointmentDetails(String appointmentId) async {
    try {
      // Fetch appointment details from Firestore using the appointmentId
      final appointmentDoc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (appointmentDoc.exists) {
        final appointment = Appointment.fromFirestore(appointmentDoc);

        // Navigate to appointment details screen with the appointment object
        Navigator.pushNamed(
          context,
          Routes.appointmentDetail,
          arguments: appointment,
        );
      } else {
        _showNotificationDetailDialog(
          title: 'Appointment Not Found',
          body: 'The appointment details are no longer available.',
          type: 'error',
        );
      }
    } catch (error) {
      _showNotificationDetailDialog(
        title: 'Error',
        body: 'Could not load appointment details: $error',
        type: 'error',
      );
    }
  }

  void _navigateToOrderDetails(String orderId) {
    // Navigate to order details screen with orderId
    Navigator.pushNamed(
      context,
      Routes.myOrders,
      arguments: orderId,
    );
  }

  void _navigateToMedicalRecords(String recordId) {
    // Navigate to medical records screen with recordId
    Navigator.pushNamed(
      context,
      Routes.medicalRecords,
      arguments: recordId,
    );
  }

  void _navigateToPrescriptionDetails(String prescriptionId) {
    // For now, show a dialog since we don't have a prescription details route
    _showNotificationDetailDialog(
      title: 'Prescription Details',
      body: 'Prescription ID: $prescriptionId\n\nThis feature is coming soon!',
      type: 'prescription',
    );
  }

  void _showNotificationDetailDialog({
    required String title,
    required String body,
    required String type,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getNotificationIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(String id) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read_rounded),
              title: const Text('Mark as read'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: const Text('Delete notification'),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification(id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      await _firestore
          .collection('notifications')
          .doc(user.id)
          .collection('user_notifications')
          .doc(id)
          .update({'isRead': true});
    }
  }

  Future<void> _deleteNotification(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      await _firestore
          .collection('notifications')
          .doc(user.id)
          .collection('user_notifications')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
