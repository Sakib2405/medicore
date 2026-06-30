// lib/config/routes.dart
import 'package:flutter/material.dart';

// Admin Screen Imports
import 'package:medicore/screens/admin/admin_home_screen.dart';
import 'package:medicore/screens/admin/admin_login_screen.dart';
import 'package:medicore/screens/admin/ai_analytics_screen.dart';
import 'package:medicore/screens/admin/manage_appointments_screen.dart';
import 'package:medicore/screens/admin/manage_doctors_screen.dart';
import 'package:medicore/screens/admin/manage_orders_screen.dart';
import 'package:medicore/screens/admin/manage_store_screen.dart';
import 'package:medicore/screens/admin/manage_users_screen.dart';
import 'package:medicore/screens/admin/sample_data_generator_screen.dart';
import 'package:medicore/screens/doctor/doctor_home_screen.dart';
import 'package:medicore/screens/doctor/auth/doctor_login_screen.dart';
import 'package:medicore/screens/doctor/auth/doctor_approval_pending_screen.dart';
import 'package:medicore/screens/doctor/auth/doctor_signup_screen.dart';

// Patient Screen Imports
import 'package:medicore/screens/patient/ai_chatbot_screen.dart';
import 'package:medicore/screens/patient/appointment_booking_screen.dart';
import 'package:medicore/screens/patient/appointment_detail_screen.dart';
import 'package:medicore/screens/patient/appointment_form_screen.dart';
import 'package:medicore/screens/patient/auth/login_screen.dart';
import 'package:medicore/screens/patient/auth/signup_screen.dart';
import 'package:medicore/screens/patient/auth/verification_screen.dart';
import 'package:medicore/screens/patient/doctor_list_screen.dart';
import 'package:medicore/screens/patient/my_appointments_screen.dart';
import 'package:medicore/screens/patient/order_screen.dart';
import 'package:medicore/screens/patient/patient_home_screen.dart';
import 'package:medicore/screens/patient/profile_screen.dart';
import 'package:medicore/screens/patient/store/cart_screen.dart';
import 'package:medicore/screens/patient/store/checkout_screen.dart';
import 'package:medicore/screens/patient/store/medicine_detail_screen.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/screens/patient/store/medicine_store_screen.dart';
import 'package:medicore/screens/patient/symptom_checker_screen.dart';
import 'package:medicore/screens/prescriptions/doctor_create_prescription.dart';
import 'package:medicore/screens/prescriptions/doctor_prescriptions_screen.dart';
import 'package:medicore/screens/prescriptions/patient_prescriptions_list.dart';

// Shared Screen Imports
import 'package:medicore/screens/shared/change_password_screen.dart';
import 'package:medicore/screens/shared/edit_profile_screen.dart';
import 'package:medicore/screens/shared/notifications_screen.dart';
import 'package:medicore/screens/shared/settings_screen.dart';
import 'package:medicore/screens/shared/splash_screen.dart';
import 'package:medicore/screens/shared/success_screen.dart';

// Medical Records Screen
import 'package:medicore/screens/patient/medical_records_screen.dart';

class Routes {
  // Splash & Initial
  static const String splash = '/';

  // Patient Auth
  static const String login = '/login';
  static const String doctorLogin = '/doctor-login';
  static const String doctorSignup = '/doctor-signup';
  static const String doctorApprovalPending = '/doctor-approval-pending';
  static const String signup = '/signup';
  static const String verify = '/verify';

  // Admin Auth
  static const String adminLogin = '/admin-login';

  // Doctor Core
  static const String doctorHome = '/doctor-home';

  // Patient Core
  static const String patientHome = '/patient-home';
  static const String profile = '/profile';
  static const String myAppointments = '/my-appointments';
  static const String appointmentDetail = '/appointment-detail';
  static const String appointmentBooking = '/appointment-booking';
  static const String appointmentForm = '/appointment-form';
  static const String doctorList = '/doctor-list';
  static const String symptomChecker = '/symptom-checker';
  static const String createPrescription = '/create-prescription';
  static const String myPrescriptions = '/my-prescriptions';
  static const String doctorPrescriptions = '/doctor-prescriptions';
  static const String aiChatbot = '/ai-chatbot';
  static const String medicalRecords = '/medical-records';

  // Patient Store
  static const String store = '/store';
  static const String medicineDetail = '/medicine-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String myOrders = '/my-orders';

  // Admin
  static const String adminHome = '/admin-home';
  static const String adminAnalytics = '/admin-analytics';
  static const String adminManageUsers = '/admin-manage-users';
  static const String adminManageDoctors = '/admin-manage-doctors';
  static const String adminManageAppointments = '/admin-manage-appointments';
  static const String adminManageOrders = '/admin-manage-orders';
  static const String adminManageStore = '/admin-manage-store';
  static const String sampleData = '/sample-data';

  // Shared
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String success = '/success';

  static Map<String, WidgetBuilder> get routes {
    return {
      // Splash & Initial
      splash: (context) => const SplashScreen(),

      // Patient Auth
      login: (context) => const LoginScreen(),
      doctorLogin: (context) => const DoctorLoginScreen(),
      doctorSignup: (context) => const DoctorSignupScreen(),
      doctorApprovalPending: (context) => const DoctorApprovalPendingScreen(),
      signup: (context) => const SignupScreen(),
      verify: (context) => const VerificationScreen(),

      // Admin Auth
      adminLogin: (context) => const AdminLoginScreen(),

      // Doctor Core
      doctorHome: (context) => const DoctorHomeScreen(),

      // Patient Core
      patientHome: (context) => const PatientHomeScreen(),
      profile: (context) => const ProfileScreen(),
      myAppointments: (context) => const MyAppointmentsScreen(),
      appointmentDetail: (context) => const AppointmentDetailScreen(),
      appointmentBooking: (context) => const AppointmentBookingScreen(),
      appointmentForm: (context) => const AppointmentFormScreen(),
      doctorList: (context) => const DoctorListScreen(),
      symptomChecker: (context) => const SymptomCheckerScreen(),
      createPrescription: (context) => const DoctorCreatePrescriptionScreen(),
      myPrescriptions: (context) => const PatientPrescriptionsList(),
      doctorPrescriptions: (context) => const DoctorPrescriptionsScreen(),
      aiChatbot: (context) => const AIChatbotScreen(),
      medicalRecords: (context) => const MedicalRecordsScreen(),

      // Patient Store
      store: (context) => const MedicineStoreScreen(),
      medicineDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Medicine) {
          return MedicineDetailScreen(medicine: args);
        }
        return const Scaffold(
          body: Center(child: Text('Medicine not provided')),
        );
      },
      cart: (context) => const CartScreen(),
      checkout: (context) => const CheckoutScreen(),
      myOrders: (context) => const OrderScreen(),

      // Admin
      adminHome: (context) => const AdminHomeScreen(),
      adminAnalytics: (context) => const AiAnalyticsScreen(),
      adminManageUsers: (context) => const ManageUsersScreen(),
      adminManageDoctors: (context) => const ManageDoctorsScreen(),
      adminManageAppointments: (context) => const ManageAppointmentsScreen(),
      adminManageOrders: (context) => const ManageOrdersScreen(),
      adminManageStore: (context) => const ManageStoreScreen(),
      sampleData: (context) => const SampleDataScreen(),

      // Shared
      settings: (context) => const SettingsScreen(),
      notifications: (context) => const NotificationsScreen(),
      editProfile: (context) => const EditProfileScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      success: (context) => const SuccessScreen(),
    };
  }

  // Add this missing method for onGenerateRoute
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Handle dynamic routes or parameterized routes here
    switch (settings.name) {
      // Example for appointment detail with ID:
      case '/appointment-detail/:id':
        final String id =
            settings.arguments as String? ?? settings.name!.split('/').last;
        return MaterialPageRoute(
          builder: (context) => const AppointmentDetailScreen(),
          settings: RouteSettings(
            name: settings.name,
            arguments: id,
          ),
        );

      // Example for doctor detail with ID:
      case '/doctor-detail/:id':
        final String id =
            settings.arguments as String? ?? settings.name!.split('/').last;
        return MaterialPageRoute(
          builder: (context) => const DoctorListScreen(),
          settings: RouteSettings(
            name: settings.name,
            arguments: {'selectedDoctorId': id},
          ),
        );

      default:
        // For routes that are not in the static routes map
        final routeName = settings.name ?? splash;

        if (routes.containsKey(routeName)) {
          return MaterialPageRoute(
            builder: routes[routeName]!,
            settings: settings,
          );
        }

        // If route is not found, return a generic error route
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Route Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route_rounded,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    'Route "$routeName" not configured',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      splash,
                      (route) => false,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  // Helper method for navigation with type safety
  static Future<T?> pushNamed<T extends Object?>(
      BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    bool Function(Route<dynamic>)? predicate,
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  // Route groups for easier management
  static List<String> get patientRoutes => [
        patientHome,
        profile,
        myAppointments,
        appointmentDetail,
        appointmentBooking,
        appointmentForm,
        doctorList,
        symptomChecker,
        aiChatbot,
        medicalRecords,
        store,
        medicineDetail,
        cart,
        checkout,
        myOrders,
      ];

  static List<String> get doctorRoutes => [
        doctorHome,
        createPrescription,
      ];

  static List<String> get adminRoutes => [
        adminHome,
        adminAnalytics,
        adminManageUsers,
        adminManageDoctors,
        adminManageAppointments,
        adminManageOrders,
        adminManageStore,
        sampleData,
      ];

  static List<String> get authRoutes => [
        login,
        signup,
        verify,
        adminLogin,
      ];

  static List<String> get sharedRoutes => [
        settings,
        notifications,
        editProfile,
        changePassword,
      ];

  // Validation methods
  static bool isValidRoute(String routeName) {
    return routes.containsKey(routeName);
  }

  static bool isPatientRoute(String routeName) {
    return patientRoutes.contains(routeName);
  }

  static bool isAdminRoute(String routeName) {
    return adminRoutes.contains(routeName);
  }

  static bool isDoctorRoute(String routeName) {
    return doctorRoutes.contains(routeName);
  }

  static bool isAuthRoute(String routeName) {
    return authRoutes.contains(routeName);
  }

  static bool isSharedRoute(String routeName) {
    return sharedRoutes.contains(routeName);
  }

  // Get route name from path (useful for web)
  static String getRouteName(String path) {
    if (path == '/' || path.isEmpty) return splash;

    // Remove query parameters and fragments
    final uri = Uri.parse(path);
    final routePath = uri.path;

    // Check if route exists
    if (routes.containsKey(routePath)) {
      return routePath;
    }

    // Fallback to splash screen for unknown routes
    return splash;
  }

  // Navigation shortcuts for common flows
  static void goToPatientHome(BuildContext context) {
    pushNamedAndRemoveUntil(context, patientHome);
  }

  static void goToAdminHome(BuildContext context) {
    pushNamedAndRemoveUntil(context, adminHome);
  }

  static void goToDoctorHome(BuildContext context) {
    pushNamedAndRemoveUntil(context, doctorHome);
  }

  static void goToLogin(BuildContext context) {
    pushNamedAndRemoveUntil(context, login);
  }

  static void goToAdminLogin(BuildContext context) {
    pushNamedAndRemoveUntil(context, adminLogin);
  }

  // Sample data screen navigation
  static void goToSampleData(BuildContext context) {
    pushNamed(context, sampleData);
  }

  // Check if user can access route based on role
  static bool canAccessRoute(String routeName, String userRole) {
    if (isSharedRoute(routeName)) return true;

    switch (userRole) {
      case 'patient':
        return isPatientRoute(routeName) || isAuthRoute(routeName);
      case 'doctor':
        return isDoctorRoute(routeName) || isSharedRoute(routeName);
      case 'admin':
        return isAdminRoute(routeName) || isAuthRoute(routeName);
      default:
        return isAuthRoute(routeName);
    }
  }

  // Navigation with parameters
  static void goToMedicineDetail(BuildContext context, String medicineId) {
    pushNamed(context, medicineDetail, arguments: medicineId);
  }

  static void goToAppointmentDetail(
      BuildContext context, String appointmentId) {
    pushNamed(context, appointmentDetail, arguments: appointmentId);
  }

  static void goToDoctorDetail(BuildContext context, String doctorId) {
    pushNamed(context, doctorList, arguments: {'selectedDoctorId': doctorId});
  }
}
