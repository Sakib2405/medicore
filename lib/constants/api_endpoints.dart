import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // FIX: Access the base URL directly from the loaded .env variables
  static final String _base =
      dotenv.env['API_BASE_URL'] ?? 'https://api.default.com/v1';

  // Auth
  static final String login = '$_base/auth/login';
  static final String adminLogin = '$_base/auth/admin-login';
  static final String signup = '$_base/auth/signup';

  // Patients
  static final String patients = '$_base/patients';
  static String patientById(String id) => '$_base/patients/$id';

  // Doctors (for admin management)
  static final String doctors = '$_base/doctors';

  // Appointments
  static final String appointments = '$_base/appointments';

  // Store & Orders
  static final String medicines = '$_base/store/medicines';
  static final String orders = '$_base/store/orders';
}
