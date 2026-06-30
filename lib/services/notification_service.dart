class NotificationService {
  Future<List<String>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      "Your appointment with Dr. Smith is confirmed.",
      "Your order #12345 has been shipped.",
    ];
  }
}
