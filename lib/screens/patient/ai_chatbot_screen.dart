// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medicore/config/env.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/doctor_provider.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/config/routes.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/services/gemini_proxy_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicore/screens/patient/doctor_profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:medicore/providers/cart_provider.dart';

class AppointmentTool {
  static const String functionName = 'book_appointment';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Books a doctor appointment for the patient. Use this tool when the user clearly expresses the intent to schedule an appointment.',
    Schema(
      SchemaType.object,
      properties: {
        'doctorName': Schema(
          SchemaType.string,
          description:
              'The name of the doctor from the available doctors list.',
        ),
        'dateTime': Schema(
          SchemaType.string,
          description:
              'The requested date and time for the appointment in YYYY-MM-DD HH:MM format.',
        ),
        'patientIssue': Schema(
          SchemaType.string,
          description: 'A brief description of the patient health issue.',
        ),
      },
      requiredProperties: ['doctorName', 'dateTime', 'patientIssue'],
    ),
  );

  static Map<String, dynamic> execute(Map<String, dynamic> args) {
    try {
      final doctorName = args['doctorName'] as String;
      final dateTimeStr = args['dateTime'] as String;
      final patientIssue = args['patientIssue'] as String;

      final appointmentDate = DateTime.parse(dateTimeStr);
      if (appointmentDate.isBefore(DateTime.now())) {
        return {
          'status': 'error',
          'message':
              'Cannot book appointment in the past. Please select a future date and time.',
        };
      }

      // Check if the selected time is within working hours (8 AM - 8 PM)
      final hour = appointmentDate.hour;
      if (hour < 8 || hour >= 20) {
        return {
          'status': 'error',
          'message':
              'Appointments can only be booked between 8:00 AM and 8:00 PM. Please select a different time.',
        };
      }

      final bookingId = const Uuid().v4();
      final formattedTime =
          DateFormat('EEE, MMM d, yyyy h:mm a').format(appointmentDate);

      return {
        'status': 'success',
        'message':
            'Your appointment with $doctorName for "$patientIssue" has been successfully booked.',
        'booking_id': bookingId,
        'scheduled_time': formattedTime,
        'doctor_name': doctorName,
        'patient_issue': patientIssue,
        'action': 'appointment_booked',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message':
            'Failed to book appointment. Please make sure to provide Doctor Name, Date, Time (e.g., 2025-12-30 14:00), and a brief description of the issue. Error: ${e.toString()}',
      };
    }
  }
}

class DoctorListTool {
  static const String functionName = 'show_doctors';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Shows the list of available doctors with their specialties and availability. Use this when user asks to see doctors list or available doctors.',
    Schema(
      SchemaType.object,
      properties: {},
      requiredProperties: [],
    ),
  );

  static Map<String, dynamic> execute(List<Doctor> doctors) {
    return {
      'status': 'success',
      'message': 'Here are our available doctors:',
      'doctors': doctors.map((doctor) => _convertDoctorToMap(doctor)).toList(),
      'action': 'doctors_list_shown',
    };
  }

  static Map<String, dynamic> _convertDoctorToMap(Doctor doctor) {
    return {
      'name': doctor.name,
      'specialty': doctor.specialty,
      'availability': doctor.isAvailable ? 'Available' : 'Not Available',
      'experience': doctor.experienceYears != null
          ? '${doctor.experienceYears} years'
          : 'Experience not specified',
      'rating': '${doctor.rating.toStringAsFixed(1)}/5',
      'education': doctor.education.isNotEmpty
          ? doctor.education.join(', ')
          : 'Education not specified',
      'languages': doctor.languages,
      'fees': doctor.consultationFee != null
          ? '৳${doctor.consultationFee}'
          : 'Fee not specified',
      'hospital': doctor.clinicName ?? 'Clinic not specified',
      'contact': doctor.phone ?? 'Contact not specified',
      'services': [doctor.specialty], // Using specialty as main service
      'isAvailable': doctor.isAvailable,
      'isVerified': true, // Assuming all doctors are verified
      'totalRatings': doctor.totalRatings,
      'appointmentDuration': 30, // Default 30 minutes
      'bio': doctor.bio ?? 'No bio available',
    };
  }
}

class HealthTipsTool {
  static const String functionName = 'get_health_tips';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Provides health tips and information based on user query. Use this when user asks for health advice, tips, or general health information.',
    Schema(
      SchemaType.object,
      properties: {
        'topic': Schema(
          SchemaType.string,
          description: 'The health topic or category the user is asking about',
        ),
      },
      requiredProperties: ['topic'],
    ),
  );

  static Map<String, dynamic> execute(Map<String, dynamic> args) {
    final topic = args['topic'] as String;

    // Health tips in both English and Bangla
    final healthTips = {
      'general': {
        'title': 'সাধারণ স্বাস্থ্য পরামর্শ / General Health Tips',
        'tips': [
          'দিনে অন্তত ৮ গ্লাস পানি পান করুন / Drink at least 8 glasses of water daily',
          'নিয়মিত ব্যায়াম করুন / Exercise regularly',
          'পর্যাপ্ত ঘুমান (৭-৮ ঘন্টা) / Get enough sleep (7-8 hours)',
          'সুষম খাদ্য গ্রহণ করুন / Eat balanced diet',
          'মানসিক চাপ কমাতে মেডিটেশন করুন / Practice meditation to reduce stress'
        ]
      },
      'diet': {
        'title': 'খাদ্য ও পুষ্টি পরামর্শ / Diet and Nutrition Tips',
        'tips': [
          'তাজা ফল ও শাকসবজি খান / Eat fresh fruits and vegetables',
          'প্রক্রিয়াজাত খাবার এড়িয়ে চলুন / Avoid processed foods',
          'ছোট ছোট বেশিরভাগ খাবার খান / Eat small frequent meals',
          'লবণ ও চিনি সীমিত করুন / Limit salt and sugar intake',
          'পর্যাপ্ত প্রোটিন গ্রহণ করুন / Get adequate protein'
        ]
      },
      'exercise': {
        'title': 'ব্যায়াম পরামর্শ / Exercise Tips',
        'tips': [
          'সপ্তাহে ১৫০ মিনিট মাঝারি ব্যায়াম করুন / 150 minutes moderate exercise weekly',
          'হাঁটা是最好的 ব্যায়াম / Walking is the best exercise',
          'ইয়োগা ও মেডিটেশন চর্চা করুন / Practice yoga and meditation',
          'ধীরে ধীরে শুরু করুন / Start slowly and gradually increase',
          'শরীরচর্চার আগে ওয়ার্ম আপ করুন / Warm up before exercise'
        ]
      },
      'heart': {
        'title': 'হৃদযন্ত্রের স্বাস্থ্য পরামর্শ / Heart Health Tips',
        'tips': [
          'নিয়মিত রক্তচাপ চেক করুন / Check blood pressure regularly',
          'ধূমপান এড়িয়ে চলুন / Avoid smoking',
          'স্যাচুরেটেড ফ্যাট কম খান / Reduce saturated fat intake',
          'নিয়মিত কার্ডিও ব্যায়াম করুন / Do regular cardio exercises',
          'মানসিক চাপ নিয়ন্ত্রণ করুন / Manage mental stress'
        ]
      },
      'diabetes': {
        'title': 'ডায়াবেটিস ব্যবস্থাপনা / Diabetes Management',
        'tips': [
          'নিয়মিত ব্লাড সুগার মনিটর করুন / Monitor blood sugar regularly',
          'কার্বোহাইড্রেট ইনটেক নিয়ন্ত্রণ করুন / Control carbohydrate intake',
          'নিয়মিত ওষুধ নিন / Take medication regularly',
          'পায়ের যত্ন নিন / Take care of your feet',
          'নিয়মিত ডাক্তার দেখান / Visit doctor regularly'
        ]
      },
      'covid': {
        'title': 'কোভিড-১৯ প্রতিরোধ / COVID-19 Prevention',
        'tips': [
          'নিয়মিত হাত ধৌত করুন / Wash hands regularly',
          'মাস্ক পরুন / Wear mask',
          'সামাজিক দূরত্ব বজায় রাখুন / Maintain social distance',
          'ভ্যাকসিন নিন / Get vaccinated',
          'লক্ষণ দেখা দিলে টেস্ট করান / Get tested if symptoms appear'
        ]
      }
    };

    final selectedTopic =
        healthTips[topic.toLowerCase()] ?? healthTips['general']!;

    return {
      'status': 'success',
      'topic': topic,
      'title': selectedTopic['title'],
      'tips': selectedTopic['tips'],
      'message': 'Here are some health tips for $topic:',
    };
  }
}

class UpdateProfileTool {
  static const String functionName = 'update_profile';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Updates user profile fields. Use when user asks to change name, phone, or blood group.',
    Schema(
      SchemaType.object,
      properties: {
        'name': Schema(SchemaType.string, description: 'New full name'),
        'phone': Schema(SchemaType.string, description: 'New phone number'),
        'bloodGroup': Schema(SchemaType.string,
            description: 'One of A+,A-,B+,B-,O+,O-,AB+,AB-'),
      },
      requiredProperties: [],
    ),
  );
}

class PaymentTool {
  static const String functionName = 'initiate_payment';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Initiate an online payment using SSLCommerz. Prefer when user asks to pay bills or complete an order.',
    Schema(
      SchemaType.object,
      properties: {
        'amount': Schema(SchemaType.number, description: 'Amount in BDT'),
        'purpose': Schema(SchemaType.string,
            description:
                'Short payment reason like appointment, order, or medicine'),
        'orderId':
            Schema(SchemaType.string, description: 'Optional related order ID'),
        'method': Schema(SchemaType.string,
            description: 'Preferred method: bkash|nagad|rocket'),
      },
      requiredProperties: ['amount'],
    ),
  );
}

class OrderMedicineTool {
  static const String functionName = 'order_medicine';

  static final FunctionDeclaration functionDeclaration = FunctionDeclaration(
    functionName,
    'Create a medicine order from a list of name+quantity, and optionally pay now.',
    Schema(
      SchemaType.object,
      properties: {
        'items': Schema(
          SchemaType.array,
          description: 'Medicines to order',
          items: Schema(
            SchemaType.object,
            properties: {
              'name': Schema(SchemaType.string, description: 'Medicine name'),
              'quantity':
                  Schema(SchemaType.number, description: 'Quantity (integer)'),
            },
            requiredProperties: ['name', 'quantity'],
          ),
        ),
        'address': Schema(SchemaType.string, description: 'Shipping address'),
        'payNow': Schema(SchemaType.boolean,
            description: 'If true, initiate payment immediately'),
        'method': Schema(SchemaType.string,
            description: 'Payment method: bkash|nagad|rocket'),
      },
      requiredProperties: ['items'],
    ),
  );
}

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  String? get _apiKey => Env.env.geminiApiKey;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _canUseModel = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String? _lastUserText;
  final List<
      ({
        String text,
        bool isUser,
        bool isError,
        Map<String, dynamic>? functionResponse
      })> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _showDoctorList = false;
  bool _showMedicineList = false;
  double _bgTintOpacity = 0.22;
  bool _awaitingQuantity = false;
  Medicine? _pendingMedicine;

  // Dynamic suggestions
  List<String> _suggestions = [
    'ডাক্তার দেখাও', 'ওষুধ অর্ডার করো', 'অ্যাপয়েন্টমেন্ট নিতে চাই', 'স্বাস্থ্য টিপস',
  ];

  // Voice
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _addWelcomeMessage();
    // Precache local background image for faster display and load tint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/chatbot.jpg'), context);
      _loadDoctors();
      _loadMedicines();
      _loadTintOpacity();
      _initSpeech();
    });
  }

  Future<void> _loadTintOpacity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble('bg_tint_opacity');
      if (val != null) setState(() => _bgTintOpacity = val.clamp(0.0, 0.8));
    } catch (_) {}
  }

  Future<void> _saveTintOpacity(double opacity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bg_tint_opacity', opacity);
    } catch (_) {}
  }

  void _showTintPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        double tmp = _bgTintOpacity;
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Background tint opacity',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Slider(
                  value: tmp,
                  min: 0.0,
                  max: 0.8,
                  divisions: 80,
                  label: tmp.toStringAsFixed(2),
                  onChanged: (v) => setModalState(() => tmp = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setModalState(() => tmp = 0.12),
                      child: const Text('Light'),
                    ),
                    TextButton(
                      onPressed: () => setModalState(() => tmp = 0.22),
                      child: const Text('Default'),
                    ),
                    TextButton(
                      onPressed: () => setModalState(() => tmp = 0.45),
                      child: const Text('Darker'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _bgTintOpacity = tmp);
                          _saveTintOpacity(tmp);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }

  void _loadDoctors() {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    if (doctorProvider.doctors.isEmpty) {
      doctorProvider.loadDoctors();
    }
  }

  void _loadMedicines() {
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    if (medProvider.medicines.isEmpty) {
      medProvider.loadMedicines();
    }
  }

  Future<void> _initSpeech() async {
    final ok = await _stt.initialize(
      onError: (_) { if (mounted) setState(() => _isListening = false); },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _isListening = false);
          // auto-send when speech finishes with text
          if (_controller.text.trim().isNotEmpty) _sendMessage();
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  Future<void> _toggleVoice() async {
    if (!_sttAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }
    _controller.clear();
    setState(() => _isListening = true);
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _controller.text = r.recognizedWords);
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      },
    );
  }

  /// Builds a real-time context string injected before every AI message
  String _buildRealtimeContext() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final doctorProvider =
        Provider.of<DoctorProvider>(context, listen: false);
    final medProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);

    // Doctors
    final doctorLines = doctorProvider.doctors.take(20).map((d) =>
        '  - ${d.name} | ${d.specialty} | fee:৳${d.consultationFee ?? '?'} | '
        'available:${d.isAvailable}').join('\n');

    // Medicines in stock
    final medLines = medProvider.medicines
        .where((m) => m.stockQuantity > 0)
        .take(30)
        .map((m) =>
            '  - ${m.name} | ৳${m.finalPrice.toStringAsFixed(0)} | stock:${m.stockQuantity}')
        .join('\n');

    final patientName = authProvider.currentUser?.displayName ?? 'Patient';

    return '''
[LIVE CONTEXT — $dateStr]
Patient: $patientName

Available Doctors (${doctorProvider.doctors.length} total):
$doctorLines

Medicines in Stock (${medProvider.medicines.where((m) => m.stockQuantity > 0).length} items):
$medLines
[END CONTEXT]

''';
  }

  void _initializeModel() {
    final useProxy = Env.env.geminiProxyUrl.isNotEmpty;
    _canUseModel = (_apiKey != null && _apiKey!.isNotEmpty) || useProxy;

    if (!_canUseModel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.insert(0, (
            text:
                'Gemini API key missing or empty, and no proxy configured. Please set GEMINI_API_KEY in .env or GEMINI_PROXY_URL to enable MediPro Assistant.',
            isUser: false,
            isError: true,
            functionResponse: null,
          ));
        });
      });
      return;
    }

    if (!useProxy) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey ?? '',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
        ),
        tools: [
          Tool(functionDeclarations: [
            AppointmentTool.functionDeclaration,
            DoctorListTool.functionDeclaration,
            HealthTipsTool.functionDeclaration,
            UpdateProfileTool.functionDeclaration,
            PaymentTool.functionDeclaration,
            OrderMedicineTool.functionDeclaration,
          ])
        ],
      );
      _chat = _model.startChat();
      if (_canUseModel) {
        try {
          _chat.sendMessage(Content.text(_agentSystemPrompt()));
        } catch (_) {}
      }
    }
  }

  static String _agentSystemPrompt() => '''
You are MediPro, an AI health agent embedded in the Medicore app. You MUST act directly — never just explain how to do things.

RULES (follow strictly):
1. When user says anything about booking an appointment / ডাক্তার দেখাবো / appointment নিতে চাই → IMMEDIATELY call book_appointment tool. Extract doctor name, date-time (default tomorrow 10:00 if not given), and issue from user text.
2. When user says anything about ordering medicine / ওষুধ অর্ডার / buy medicine → IMMEDIATELY call order_medicine tool with the medicine name and quantity (default 1).
3. When user asks to see doctors / ডাক্তার দেখাও → call show_doctors.
4. When user asks for health tips → call get_health_tips.
5. When user asks to update profile / নাম/ফোন বদলাও → call update_profile.
6. NEVER say "you can book by going to..." — just DO IT using tools.
7. Reply in Bangla (বাংলা) by default. Short, friendly, action-oriented.
8. After every tool action, confirm what was done and suggest a next step.
9. The LIVE CONTEXT block in each message has real doctor names and medicines — use exact names from there when calling tools.
10. If user says "ডাক্তারের সাথে অ্যাপয়েন্টমেন্ট নাও" without specifying a doctor, ask which doctor (show options from context). Then immediately book.
''';

  // Dynamic suggestions based on last bot message content
  List<String> _computeSuggestions(String lastBotText) {
    final t = lastBotText.toLowerCase();
    if (t.contains('appointment') || t.contains('অ্যাপয়েন্টমেন্ট') || t.contains('বুক')) {
      return ['আমার অ্যাপয়েন্টমেন্ট দেখাও', 'আরেকজন ডাক্তার দেখাও', 'বাতিল করতে চাই', 'স্বাস্থ্য টিপস'];
    }
    if (t.contains('cart') || t.contains('কার্ট') || t.contains('order') || t.contains('অর্ডার')) {
      return ['Checkout করতে চাই', 'আরো ওষুধ যোগ করো', 'কার্ট দেখাও', 'ডাক্তার দেখাও'];
    }
    if (t.contains('doctor') || t.contains('ডাক্তার')) {
      return ['অ্যাপয়েন্টমেন্ট নিতে চাই', 'ওষুধ অর্ডার করতে চাই', 'স্বাস্থ্য টিপস দাও', 'ওষুধ দেখাও'];
    }
    if (t.contains('medicine') || t.contains('ওষুধ')) {
      return ['Paracetamol 2টা অর্ডার করো', 'ডাক্তার দেখাও', 'কার্ট দেখাও', 'অ্যাপয়েন্টমেন্ট নিতে চাই'];
    }
    if (t.contains('tip') || t.contains('পরামর্শ')) {
      return ['ডাক্তার দেখাও', 'ওষুধ অর্ডার', 'অ্যাপয়েন্টমেন্ট নিতে চাই', 'ডায়াবেটিস টিপস'];
    }
    return ['ডাক্তার দেখাও', 'ওষুধ অর্ডার করো', 'অ্যাপয়েন্টমেন্ট নিতে চাই', 'স্বাস্থ্য টিপস'];
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.insert(0, (
        text: "🩺 স্বাগতম! আমি MediPro, আপনার স্বাস্থ্য সহায়ক এজেন্ট।\n\n"
            "আমি আপনাকে সাহায্য করতে পারি:\n"
            "• 🏥 ডাক্তার অ্যাপয়েন্টমেন্ট বুকিং\n"
            "• 💊 ওষুধ অর্ডার এবং তথ্য\n"
            "• 📋 স্বাস্থ্য পরামর্শ ও টিপস\n"
            "• 🔍 ডাক্তার এবং ওষুধ খোঁজা\n\n"
            "আপনি আমাকে জিজ্ঞাসা করতে পারেন:\n"
            "- 'ডাক্তার দেখাও' (Show doctors)\n"
            "- 'ওষুধ তালিকা' (Medicine list)\n"
            "- 'প্যারাসিটামল আছে কি?' (Is paracetamol available?)\n"
            "- 'স্বাস্থ্য টিপস' (Health tips)\n\n"
            "Welcome! I'm MediPro, your health assistant.\n\n"
            "I can help with:\n"
            "• Doctor appointments\n"
            "• Medicine orders and info\n"
            "• Health tips and advice\n"
            "• Finding doctors and medicines",
        isUser: false,
        isError: false,
        functionResponse: null
      ));
    });
  }

  String? _getFallbackResponse(String text) {
    final lowerText = text.toLowerCase();
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    if (lowerText.contains('medicine') || lowerText.contains('ঔষধ')) {
      if (lowerText.contains('order') ||
          lowerText.contains('অর্ডার') ||
          lowerText.contains('buy') ||
          lowerText.contains('কিন')) {
        return '🛒 ওষুধ অর্ডার করতে:\n'
            '1. "ওষুধ তালিকা দেখাও" বলুন\n'
            '2. পছন্দের ওষুধের কার্ডে "Order" ক্লিক করুন\n'
            '3. পরিমাণ এবং ঠিকানা বলুন\n\n'
            'উদাহরণ: "প্যারাসিটামল 10টা অর্ডার করুন"\n\n'
            'To order medicine:\n'
            '1. Say "Show medicine list"\n'
            '2. Click "Order" on preferred medicine\'s card\n'
            '3. Mention quantity and address\n\n'
            'Example: "Order 10 Paracetamol"';
      } else if (lowerText.contains('store') ||
          lowerText.contains('স্টোর') ||
          lowerText.contains('list') ||
          lowerText.contains('তালিকা')) {
        final medProvider =
            Provider.of<MedicineProvider>(context, listen: false);
        final medicines = medProvider.medicines.take(5);
        final medNames = medicines.map((m) => m.name).join(', ');
        setState(() => _showMedicineList = true);
        return '💊 উপলব্ধ ওষুধ: $medNames\n\n'
            '💡 টিপ: কার্ডে "Order" বাটনে ক্লিক করে অর্ডার করুন!\n\n'
            'Available medicines: $medNames\n\n'
            'Tip: Click "Order" on cards to place orders!';
      } else if (lowerText.startsWith('is ') &&
          lowerText.contains(' available')) {
        final medProvider =
            Provider.of<MedicineProvider>(context, listen: false);
        final parts = lowerText.split(' ');
        if (parts.length >= 3) {
          final medName = parts.sublist(1, parts.length - 1).join(' ');
          final candidates = medProvider.medicines.where(
              (m) => m.name.toLowerCase().contains(medName.toLowerCase()));
          if (candidates.isNotEmpty) {
            final med = candidates.first;
            return '✅ ${med.name} উপলব্ধ! দাম: ৳${med.finalPrice}\n'
                '📦 স্টক: ${med.stockQuantity} টি\n'
                '💡 "Order ${med.name}" বলে অর্ডার করুন\n\n'
                '${med.name} is available! Price: ৳${med.finalPrice}\n'
                'Stock: ${med.stockQuantity} units\n'
                'Say "Order ${med.name}" to place order';
          } else {
            return '❌ $medName উপলব্ধ নয়। অন্য ওষুধ খোঁজুন বা স্টোরে যান।\n\n'
                '$medName is not available. Try other medicines or visit store.';
          }
        }
      } else {
        return '💊 ওষুধ সম্পর্কে জিজ্ঞাসা করুন:\n'
            '- "ওষুধ তালিকা দেখাও" (Show medicine list)\n'
            '- "প্যারাসিটামল আছে কি?" (Is paracetamol available?)\n'
            '- "ওষুধ অর্ডার করুন" (Order medicine)\n\n'
            'Ask about medicines:\n'
            '- "Show medicine list"\n'
            '- "Is paracetamol available?"\n'
            '- "Order medicine"';
      }
    } else if (lowerText.contains('doctor') ||
        lowerText.contains('ডাক্তার') ||
        lowerText.contains('list') ||
        lowerText.contains('তালিকা')) {
      // Show doctor list
      if (doctorProvider.doctors.isNotEmpty) {
        final doctors = doctorProvider.doctors.take(5); // Show first 5 doctors
        final doctorNames = doctors.map((d) => d.name).join(', ');
        setState(() => _showDoctorList = true);
        return '🏥 উপলব্ধ ডাক্তাররা: $doctorNames\n\n'
            '💡 টিপ: কার্ডে "Book" বাটনে ক্লিক করে অ্যাপয়েন্টমেন্ট বুক করুন!\n\n'
            'Available doctors: $doctorNames\n\n'
            'Tip: Click "Book" on cards to schedule appointments!';
      } else {
        return '😔 দুঃখিত, কোনো ডাক্তার পাওয়া যায়নি। পরে আবার চেষ্টা করুন।\n\n'
            'Sorry, no doctors available. Please try again later.';
      }
    } else if (lowerText.contains('tip') ||
        lowerText.contains('টিপস') ||
        lowerText.contains('advice') ||
        lowerText.contains('পরামর্শ') ||
        lowerText.contains('health') ||
        lowerText.contains('স্বাস্থ্য')) {
      // Give health tips
      return '💡 স্বাস্থ্য টিপস:\n'
          '• 🏃‍♂️ নিয়মিত ব্যায়াম করুন (Exercise regularly)\n'
          '• 🥗 সুষম খাবার খান (Eat balanced diet)\n'
          '• 😴 পর্যাপ্ত ঘুম নিন (Get enough sleep)\n'
          '• 🧘‍♀️ স্ট্রেস কমান (Reduce stress)\n'
          '• 🩺 নিয়মিত চেকআপ করান (Regular check-ups)\n'
          '• 🚭 ধূমপান এবং অ্যালকোহল এড়িয়ে চলুন (Avoid smoking and alcohol)\n\n'
          'Health Tips:\n'
          '• Exercise regularly\n'
          '• Eat balanced diet\n'
          '• Get enough sleep\n'
          '• Reduce stress\n'
          '• Regular check-ups\n'
          '• Avoid smoking and alcohol';
    } else if (lowerText.contains('appointment') ||
        lowerText.contains('অ্যাপয়েন্টমেন্ট') ||
        lowerText.contains('book') ||
        lowerText.contains('বুক')) {
      // Suggest booking
      return '📅 অ্যাপয়েন্টমেন্ট বুক করতে:\n'
          '1. "ডাক্তার দেখাও" বলুন\n'
          '2. পছন্দের ডাক্তারের কার্ডে "Book" ক্লিক করুন\n'
          '3. তারিখ, সময় এবং সমস্যা বলুন\n\n'
          'উদাহরণ: "ডা. আহমেদ হাসানের সাথে আগামীকাল ৫টা অ্যাপয়েন্টমেন্ট বুক করুন জ্বরের জন্য"\n\n'
          'To book appointment:\n'
          '1. Say "Show me doctors"\n'
          '2. Click "Book" on preferred doctor\'s card\n'
          '3. Mention date, time, and issue\n\n'
          'Example: "Book appointment with Dr. Ahmed Hasan tomorrow at 5 PM for fever"';
    } else {
      // Generic response
      return '🤖 আমি আপনাকে সাহায্য করতে পারি:\n'
          '🏥 ডাক্তার তালিকা দেখানো\n'
          '💊 ওষুধ তথ্য এবং অর্ডার\n'
          '📅 অ্যাপয়েন্টমেন্ট বুকিং\n'
          '💡 স্বাস্থ্য পরামর্শ\n\n'
          'আরও বিস্তারিত বলুন, যেমন:\n'
          '- "ডাক্তার দেখাও"\n'
          '- "ওষুধ তালিকা"\n'
          '- "স্বাস্থ্য টিপস"\n\n'
          'I can help with:\n'
          '🏥 Doctor lists\n'
          '💊 Medicine info and orders\n'
          '📅 Appointment booking\n'
          '💡 Health advice\n\n'
          'Be more specific, like:\n'
          '- "Show doctors"\n'
          '- "Medicine list"\n'
          '- "Health tips"';
    }
    return null;
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Unfocus to avoid inactive InputConnection warnings
    try {
      _inputFocusNode.unfocus();
    } catch (_) {}

    _lastUserText = text;
    _controller.clear();
    // Quick intent: show medicine list on simple queries
    if (!_awaitingQuantity) {
      final handled = await _maybeHandleQuickIntents(text);
      if (handled) return;
    }
    // If awaiting quantity for a previously selected medicine, handle locally
    if (_awaitingQuantity && _pendingMedicine != null) {
      setState(() {
        _messages.insert(0,
            (text: text, isUser: true, isError: false, functionResponse: null));
      });

      final match = RegExp(r"\d+").firstMatch(text);
      if (match == null) {
        setState(() {
          _messages.insert(0, (
            text:
                'অনুগ্রহ করে শুধু সংখ্যা লিখুন (যেমন 2)। / Please enter a number (e.g., 2).',
            isUser: false,
            isError: true,
            functionResponse: {'action': 'quantity_invalid'},
          ));
        });
        return;
      }

      final requested = int.tryParse(match.group(0)!) ?? 0;
      if (requested <= 0) {
        setState(() {
          _messages.insert(0, (
            text: 'পরিমাণ ১ বা তার বেশি দিন। / Quantity must be at least 1.',
            isUser: false,
            isError: true,
            functionResponse: {'action': 'quantity_invalid'},
          ));
        });
        return;
      }

      final cart = Provider.of<CartProvider>(context, listen: false);
      final med = _pendingMedicine!;
      final existing = cart.getItemQuantity(med.id);
      final remaining = med.stockQuantity - existing;
      final addQty = remaining <= 0 ? 0 : requested.clamp(1, remaining);
      if (addQty <= 0) {
        setState(() {
          _messages.insert(0, (
            text:
                'দুঃখিত, ${med.name} স্টকে নেই বা কার্টে সীমা পূর্ণ। / Out of stock or maxed in cart.',
            isUser: false,
            isError: true,
            functionResponse: {'action': 'out_of_stock', 'medicine': med.name},
          ));
          _awaitingQuantity = false;
          _pendingMedicine = null;
        });
        return;
      }

      cart.addToCartWithQuantity(med, addQty);
      final subtotal = med.finalPrice * addQty;
      final confirmText =
          '✅ কার্টে যোগ হয়েছে: ${med.name} ×$addQty • ৳${subtotal.toStringAsFixed(2)}\n\nএখন পেমেন্টে নেওয়া হচ্ছে... / Taking you to payment now.';

      setState(() {
        _messages.insert(0, (
          text: confirmText,
          isUser: false,
          isError: false,
          functionResponse: {
            'status': 'success',
            'action': 'cart_updated',
            'medicine': med.name,
            'quantity': addQty,
            'subtotal': subtotal,
          },
        ));
        _awaitingQuantity = false;
        _pendingMedicine = null;
      });

      Navigator.pushNamed(context, Routes.checkout);
      return;
    }
    if (!mounted) return;
    setState(() {
      _messages.insert(0,
          (text: text, isUser: true, isError: false, functionResponse: null));
      _isLoading = true;
      _showDoctorList = false;
      _showMedicineList = false;
    });

    _scrollToTop();

    try {
      final useProxy = Env.env.geminiProxyUrl.isNotEmpty;
      String? responseText;

      if (useProxy) {
        final contextText = _buildRealtimeContext() + text;
        responseText = await GeminiProxyClient.generateTextViaProxy(contextText);
      } else {
        // Inject live data context so AI always has fresh info
        final enriched = _buildRealtimeContext() + text;
        final content = Content.text(enriched);
        final response = _canUseModel ? await _chat.sendMessage(content) : null;

        if (response == null) {
          // Model not available
          if (mounted) {
            setState(() {
              _messages.insert(0, (
                text:
                    'MediPro Assistant is currently unavailable. Please check your API key or network and try again.',
                isUser: false,
                isError: true,
                functionResponse: null,
              ));
            });
          }
          return;
        }

        if (response.functionCalls.isNotEmpty) {
          for (final functionCall in response.functionCalls) {
            await _handleFunctionCall(functionCall);
          }
        } else if (response.text != null) {
          responseText = response.text;
        } else {
          throw Exception('No response from AI');
        }
      }

      if (responseText != null) {
        if (mounted) {
          setState(() {
            _messages.insert(0, (
              text: responseText!,
              isUser: false,
              isError: false,
              functionResponse: null
            ));
            _suggestions = _computeSuggestions(responseText);
          });
        }
      }
    } catch (e) {
      // Try fallback response first
      String? fallbackResponse = _getFallbackResponse(text);
      if (fallbackResponse != null) {
        if (mounted) {
          setState(() {
            _messages.insert(0, (
              text: fallbackResponse,
              isUser: false,
              isError: false,
              functionResponse: null
            ));
          });
        }
      } else {
        String errorMessage;
        if (e.toString().contains('quota') ||
            e.toString().contains('exceeded')) {
          errorMessage =
              '⚠️ দুঃখিত, API কোটা শেষ হয়ে গেছে। বিলিং এনাবল করুন বা কোটা বাড়ান।\n\n'
              'Sorry, API quota exceeded. Enable billing or increase quota in Google Cloud Console.\n\n'
              '💡 টিপ: অফলাইনে আমি ডাক্তার তালিকা, ওষুধ তথ্য এবং স্বাস্থ্য টিপস দিতে পারি!';
        } else {
          errorMessage = '🌐 কানেকশন সমস্যা। অফলাইন মোডে চালিয়ে যাচ্ছি...\n\n'
              'Connection issue. Continuing in offline mode...\n\n'
              '🤖 আমি অফলাইনে সাহায্য করতে পারি:\n'
              '• ডাক্তার তালিকা দেখানো\n'
              '• ওষুধ তথ্য এবং অর্ডার\n'
              '• স্বাস্থ্য পরামর্শ\n\n'
              'আপনার প্রশ্ন জিজ্ঞাসা করুন!';
        }
        if (mounted) {
          setState(() {
            _messages.insert(0, (
              text: errorMessage,
              isUser: false,
              isError: true,
              functionResponse: null
            ));
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToTop();
    }
  }

  Future<bool> _maybeHandleQuickIntents(String text) async {
    final lower = text.toLowerCase().trim();
    // Triggers for medicine list intent
    final triggers = <bool>[
      lower == 'medicine',
      lower == 'medicines',
      lower == 'show medicine',
      lower == 'show medicines',
      lower == 'medicine list',
      lower == 'show medicine list',
      lower.contains('medicine') &&
          (lower.contains('show') ||
              lower.contains('list') ||
              lower.contains('store')),
      lower.contains('ওষুধ'),
      lower.contains('ওষুধ তালিকা'),
      lower.contains('ওষুধ দেখাও'),
    ];
    if (triggers.any((t) => t)) {
      final medProvider = Provider.of<MedicineProvider>(context, listen: false);
      if (medProvider.medicines.isEmpty) {
        await medProvider.loadMedicines();
      }

      final meds = medProvider.medicines;
      String reply;
      if (meds.isEmpty) {
        reply = '😕 কোনো ওষুধ পাওয়া যায়নি। পরে চেষ্টা করুন।';
      } else {
        final top = meds.take(8).toList();
        final lines = top
            .map((m) => '${m.name} (৳${m.finalPrice.toStringAsFixed(2)})')
            .join(', ');
        reply = '💊 উপলব্ধ ওষুধ (শীর্ষ ${top.length}): $lines\n\n'
            '➡️ যে কোনো কার্ডে "Order" চাপুন, তারপর পরিমাণ লিখুন।';
      }

      setState(() {
        // Show user message echo
        _messages.insert(0, (
          text: text,
          isUser: true,
          isError: false,
          functionResponse: null,
        ));
        // Show bot reply and reveal medicine list
        _messages.insert(0, (
          text: reply,
          isUser: false,
          isError: false,
          functionResponse: {'action': 'show_medicine_list'},
        ));
        _showMedicineList = true;
        _showDoctorList = false;
      });
      _scrollToTop();
      return true;
    }

    // Triggers for doctor list intent
    final doctorTriggers = <bool>[
      lower == 'doctor',
      lower == 'doctors',
      lower == 'show doctor',
      lower == 'show doctors',
      lower == 'doctor list',
      lower == 'show doctor list',
      (lower.contains('doctor') &&
          (lower.contains('show') ||
              lower.contains('list') ||
              lower.contains('available'))),
      lower.contains('ডাক্তার'),
      lower.contains('ডাক্তার দেখাও'),
      lower.contains('ডাক্তার তালিকা'),
      lower.contains('ডাক্তার দেখান'),
    ];
    if (doctorTriggers.any((t) => t)) {
      final doctorProvider =
          Provider.of<DoctorProvider>(context, listen: false);
      if (doctorProvider.doctors.isEmpty) {
        await doctorProvider.loadDoctors();
      }

      final docs = doctorProvider.doctors;
      String reply;
      if (docs.isEmpty) {
        reply = '😕 কোনো ডাক্তার পাওয়া যায়নি। পরে চেষ্টা করুন।';
      } else {
        final top = docs.take(8).toList();
        final lines = top
            .map((d) =>
                '${d.name} — ${d.specialty}${d.consultationFee != null ? ' (Fee ৳${d.consultationFee})' : ''}')
            .join(', ');
        reply = '🏥 উপলব্ধ ডাক্তার (শীর্ষ ${top.length}): $lines\n\n'
            '➡️ যে কোনো কার্ডে "Book" চাপুন, তারপর সময় বাছাই করুন।';
      }

      setState(() {
        // Echo user text
        _messages.insert(0, (
          text: text,
          isUser: true,
          isError: false,
          functionResponse: null,
        ));
        // Bot reply and reveal doctor list
        _messages.insert(0, (
          text: reply,
          isUser: false,
          isError: false,
          functionResponse: {'action': 'show_doctor_list'},
        ));
        _showDoctorList = true;
        _showMedicineList = false;
      });
      _scrollToTop();
      return true;
    }
    return false;
  }

  Future<void> _handleFunctionCall(FunctionCall functionCall) async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apptService = AppointmentService();

    if (functionCall.name == AppointmentTool.functionName) {
      final args = functionCall.args;

      setState(() {
        _messages.insert(0, (
          text:
              '${args['doctorName']} ডাক্তারের সাথে অ্যাপয়েন্টমেন্ট বুক করা হচ্ছে... / Booking appointment with ${args['doctorName']}...',
          isUser: false,
          isError: false,
          functionResponse: null
        ));
      });

      // Validate and map inputs
      final doctorName = (args['doctorName'] ?? '').toString();
      final dateTimeStr = (args['dateTime'] ?? '').toString();
      final issue = (args['patientIssue'] ?? '').toString();

      Map<String, dynamic> functionResponse;

      try {
        if (!authProvider.isLoggedIn) {
          throw Exception('Please sign in to book an appointment');
        }

        if (doctorName.isEmpty || dateTimeStr.isEmpty || issue.isEmpty) {
          throw Exception(
              'Missing required fields: doctorName, dateTime, patientIssue');
        }

        // Find doctor by name (case-insensitive, allow partial prefix match)
        final doctors = doctorProvider.doctors;
        Doctor? doctor = doctors.firstWhere(
          (d) => d.name.toLowerCase() == doctorName.toLowerCase(),
          orElse: () => doctors.firstWhere(
            (d) => d.name.toLowerCase().contains(doctorName.toLowerCase()),
            orElse: () => Doctor(
              uid: '',
              name: '',
              email: '',
              specialty: '',
              isAvailable: false,
              rating: 0.0,
              totalRatings: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );

        if (doctor.uid.isEmpty) {
          final suggestions = doctors.take(5).map((d) => d.name).join(', ');
          throw Exception(
              'Doctor "$doctorName" not found. Try one of: $suggestions');
        }

        // Parse date/time
        DateTime appointmentDate = DateTime.parse(dateTimeStr);
        if (appointmentDate.isBefore(DateTime.now())) {
          throw Exception(
              'Cannot book in the past. Please provide a future date and time.');
        }

        // Optional simple hours check (8AM-8PM)
        final hour = appointmentDate.hour;
        if (hour < 8 || hour >= 20) {
          throw Exception(
              'Appointments can be booked between 8:00 AM and 8:00 PM');
        }

        final user = authProvider.currentUser!;
        final created = await apptService.bookAppointment(
          patientId: user.id,
          patientName: user.name,
          doctorId: doctor.uid,
          doctorName: doctor.name,
          doctorSpecialty: doctor.specialty,
          appointmentDate: appointmentDate,
          timeSlot: DateFormat('h:mm a').format(appointmentDate),
          reason: issue,
          consultationFee: doctor.consultationFee ?? 0.0,
          notes: null,
        );

        functionResponse = {
          'status': 'success',
          'message':
              'Your appointment with ${doctor.name} has been booked successfully.',
          'booking_id': created.id,
          'scheduled_time':
              DateFormat('EEE, MMM d, yyyy h:mm a').format(appointmentDate),
          'doctor_name': doctor.name,
          'patient_issue': issue,
          'action': 'appointment_booked',
        };
      } catch (e) {
        functionResponse = {
          'status': 'error',
          'message': e.toString().replaceFirst('Exception: ', ''),
        };
      }

      setState(() {
        _messages.insert(0, (
          text: functionResponse['message'] as String,
          isUser: false,
          isError: functionResponse['status'] == 'error',
          functionResponse: functionResponse,
        ));
      });

      final responseContent = Content.functionResponse(
        functionCall.name,
        functionResponse,
      );

      if (_canUseModel) {
        await _chat.sendMessage(responseContent);
      }
    } else if (functionCall.name == DoctorListTool.functionName) {
      // Use the actual doctors from DoctorProvider
      final doctors = doctorProvider.doctors;
      final functionResponse = DoctorListTool.execute(doctors);

      setState(() {
        _messages.insert(0, (
          text: functionResponse['message'] as String,
          isUser: false,
          isError: false,
          functionResponse: functionResponse
        ));
        _showDoctorList = true;
      });

      final responseContent = Content.functionResponse(
        functionCall.name,
        functionResponse,
      );

      if (_canUseModel) {
        await _chat.sendMessage(responseContent);
      }
    } else if (functionCall.name == HealthTipsTool.functionName) {
      final args = functionCall.args;
      final functionResponse =
          HealthTipsTool.execute(Map<String, dynamic>.from(args));

      final tipsText = '${functionResponse['message'] as String}\n\n'
          '${functionResponse['title']}\n\n'
          '${(functionResponse['tips'] as List).map((tip) => '• $tip').join('\n')}';

      setState(() {
        _messages.insert(0, (
          text: tipsText,
          isUser: false,
          isError: false,
          functionResponse: functionResponse
        ));
      });

      final responseContent = Content.functionResponse(
        functionCall.name,
        functionResponse,
      );

      if (_canUseModel) {
        await _chat.sendMessage(responseContent);
      }
    } else if (functionCall.name == UpdateProfileTool.functionName) {
      final args = Map<String, dynamic>.from(functionCall.args);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Map<String, dynamic> updates = {};
      if (args['name'] != null && (args['name'] as String).trim().isNotEmpty) {
        updates['name'] = (args['name'] as String).trim();
      }
      if (args['phone'] != null &&
          (args['phone'] as String).trim().isNotEmpty) {
        updates['phone'] = (args['phone'] as String).trim();
      }
      String? bg = args['bloodGroup'] as String?;
      bool ok = true;
      String message =
          'আপনার প্রোফাইল আপডেট করা হয়েছে। / Profile updated successfully.';
      try {
        if (updates.isNotEmpty) {
          final res = await authProvider.updateProfile(updates);
          ok = ok && res;
        }
        if (bg != null && bg.trim().isNotEmpty) {
          final res2 = await authProvider
              .updateHealthProfile({'bloodGroup': bg.trim().toUpperCase()});
          ok = ok && res2;
        }
        if (!ok) {
          message =
              'প্রোফাইল আপডেটে সমস্যা হয়েছে। / Failed to update profile.';
        }
      } catch (e) {
        ok = false;
        message = 'ত্রুটি: ${e.toString()}';
      }

      final functionResponse = {
        'status': ok ? 'success' : 'error',
        'message': message,
        if (updates.containsKey('name')) 'name': updates['name'],
        if (updates.containsKey('phone')) 'phone': updates['phone'],
        if (bg != null) 'bloodGroup': bg,
      };

      setState(() {
        _messages.insert(0, (
          text: message,
          isUser: false,
          isError: !ok,
          functionResponse: functionResponse,
        ));
      });

      final responseContent = Content.functionResponse(
        functionCall.name,
        functionResponse,
      );

      if (_canUseModel) {
        await _chat.sendMessage(responseContent);
      }
    } else if (functionCall.name == PaymentTool.functionName) {
      final args = Map<String, dynamic>.from(functionCall.args);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        final msg = 'পেমেন্ট করার জন্য লগইন প্রয়োজন। / Please sign in to pay.';
        setState(() {
          _messages.insert(0, (
            text: msg,
            isUser: false,
            isError: true,
            functionResponse: {
              'status': 'error',
              'message': msg,
            },
          ));
        });
        if (_canUseModel) {
          await _chat.sendMessage(Content.functionResponse(functionCall.name, {
            'status': 'error',
            'message': 'auth_required',
          }));
        }
        return;
      }

      final amount = (args['amount'] as num).toDouble();
      final purpose = (args['purpose'] as String?) ?? 'Payment';
      final orderId = (args['orderId'] as String?) ??
          'ADHOC_${DateTime.now().millisecondsSinceEpoch}';
      final methodStr = (args['method'] as String?)?.toLowerCase();
      PaymentMethod method = PaymentMethod.bkash;
      if (methodStr == 'nagad') method = PaymentMethod.nagad;
      if (methodStr == 'rocket') method = PaymentMethod.rocket;

      final user = authProvider.currentUser!;
      final paymentService = PaymentService();
      String textMsg;
      Map<String, dynamic> functionResponse;
      try {
        final payment = await paymentService.processSslPayment(
          context: context,
          orderId: orderId,
          amount: amount,
          method: method,
          customerName: user.name,
          customerEmail: user.email,
          customerPhone: user.phone,
        );
        final ok = payment.status == 'successful';
        textMsg = ok
            ? 'পেমেন্ট সফল হয়েছে। ট্রান্স্যাকশন: ${payment.id} • Amount ৳${payment.amount.toStringAsFixed(2)}'
            : 'পেমেন্ট ব্যর্থ বা বাতিল হয়েছে। / Payment failed or cancelled.';
        functionResponse = {
          'status': ok ? 'success' : 'error',
          'message': textMsg,
          'paymentId': payment.id,
          'orderId': orderId,
          'amount': payment.amount,
          'purpose': purpose,
          'method': payment.method,
        };
      } catch (e) {
        textMsg = 'পেমেন্ট ব্যর্থ: ${e.toString()}';
        functionResponse = {
          'status': 'error',
          'message': textMsg,
        };
      }

      setState(() {
        _messages.insert(0, (
          text: textMsg,
          isUser: false,
          isError: functionResponse['status'] != 'success',
          functionResponse: functionResponse,
        ));
      });
      if (_canUseModel) {
        await _chat.sendMessage(
            Content.functionResponse(functionCall.name, functionResponse));
      }
    } else if (functionCall.name == OrderMedicineTool.functionName) {
      final args = Map<String, dynamic>.from(functionCall.args);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final medProvider = Provider.of<MedicineProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (!authProvider.isLoggedIn) {
        final msg = 'অর্ডার করতে লগইন করুন। / Please sign in to order.';
        setState(() {
          _messages.insert(0, (
            text: msg,
            isUser: false,
            isError: true,
            functionResponse: {'status': 'error', 'message': msg},
          ));
        });
        if (_canUseModel) {
          await _chat.sendMessage(Content.functionResponse(functionCall.name, {
            'status': 'error',
            'message': 'auth_required',
          }));
        }
        return;
      }

      // Ensure medicines are loaded
      if (!medProvider.hasMedicines) {
        await medProvider.loadMedicines();
      }

      final List<dynamic> itemsReq = args['items'] as List<dynamic>;
      final List<Map<String, dynamic>> addedItems = [];
      final List<String> notFound = [];
      for (final raw in itemsReq) {
        final m = Map<String, dynamic>.from(raw as Map);
        final name = (m['name'] as String).trim();
        final qty = (m['quantity'] as num).toInt();
        final candidates = medProvider.medicines.where((med) =>
            med.isActive &&
            (med.name.toLowerCase() == name.toLowerCase() ||
                med.name.toLowerCase().contains(name.toLowerCase())));
        if (candidates.isEmpty) {
          notFound.add(name);
          continue;
        }
        final med = candidates.first;
        final requestedQty = qty.clamp(1, 100);
        final existingQty = cartProvider.getItemQuantity(med.id);
        final remainingStock = (med.stockQuantity - existingQty);
        final addQty =
            remainingStock <= 0 ? 0 : requestedQty.clamp(1, remainingStock);

        if (addQty > 0) {
          cartProvider.addToCartWithQuantity(med, addQty);
          addedItems.add({
            'id': med.id,
            'name': med.name,
            'addedQty': addQty,
            'unitPrice': med.finalPrice,
            'subtotal': med.finalPrice * addQty,
            'inCartQty': cartProvider.getItemQuantity(med.id),
          });
        } else {
          // Out of stock or already maxed in cart
          notFound.add('$name (out of stock)');
        }
      }

      if (addedItems.isEmpty) {
        final msg = 'কোনো ওষুধ মেলেনি: ${notFound.join(', ')}';
        setState(() {
          _messages.insert(0, (
            text: msg,
            isUser: false,
            isError: true,
            functionResponse: {'status': 'error', 'message': msg},
          ));
        });
        if (_canUseModel) {
          await _chat.sendMessage(Content.functionResponse(functionCall.name, {
            'status': 'error',
            'message': 'no_items_matched',
            'notFound': notFound,
          }));
        }
        return;
      }

      // Summaries
      final totalAdded = addedItems.fold<double>(
          0.0,
          (sum, i) =>
              sum + ((i['unitPrice'] as double) * (i['addedQty'] as int)));
      final totalItemsCount = cartProvider.totalItemsCount;
      final payNow = (args['payNow'] as bool?) ?? false;
      final addedLines = addedItems
          .map((i) =>
              "• ${i['name']} ×${i['addedQty']} (৳${(i['unitPrice'] as double).toStringAsFixed(2)})")
          .join('\n');
      final partials =
          notFound.isEmpty ? '' : '\n\nSome not added: ${notFound.join(', ')}';
      final textMsg = '🛒 কার্টে যোগ হয়েছে:\n$addedLines\n\nমোট যোগ: '
          '৳${totalAdded.toStringAsFixed(2)} • কার্টে মোট আইটেম: $totalItemsCount'
          '$partials\n\n${payNow ? 'এখন Checkout এ নেওয়া হচ্ছে...' : 'Review করে Checkout করুন।'}';

      final functionResponse = {
        'status': 'success',
        'message': textMsg,
        'action': 'cart_updated',
        'added': addedItems,
        if (notFound.isNotEmpty) 'notFound': notFound,
        'cart': cartProvider.cartSummary,
      };

      setState(() {
        _messages.insert(0, (
          text: textMsg,
          isUser: false,
          isError: false,
          functionResponse: functionResponse,
        ));
      });
      if (_canUseModel) {
        await _chat.sendMessage(
            Content.functionResponse(functionCall.name, functionResponse));
      }

      // Navigate to Cart or Checkout as per user intent
      if (payNow) {
        Navigator.pushNamed(context, Routes.checkout);
      } else {
        Navigator.pushNamed(context, Routes.cart);
      }
    }
  }

  void _selectDoctor(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(doctor: doctor),
      ),
    );
  }

  void _selectMedicine(String medicineName) {
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    if (medProvider.medicines.isEmpty) {
      setState(() {
        _messages.insert(0, (
          text:
              '😕 ওষুধ তালিকা লোড হচ্ছে বা খালি। পরে আবার চেষ্টা করুন। / Medicines are loading or unavailable. Please try again.',
          isUser: false,
          isError: true,
          functionResponse: null,
        ));
      });
      return;
    }

    final candidates = medProvider.medicines.where((m) =>
        m.isActive &&
        (m.name.toLowerCase() == medicineName.toLowerCase() ||
            m.name.toLowerCase().contains(medicineName.toLowerCase())));
    if (candidates.isEmpty) {
      setState(() {
        _messages.insert(0, (
          text: '❌ $medicineName মেলেনি। অন্যটি চেষ্টা করুন। / Not found.',
          isUser: false,
          isError: true,
          functionResponse: null,
        ));
      });
      return;
    }

    final med = candidates.first;
    if (med.isOutOfStock) {
      setState(() {
        _messages.insert(0, (
          text: '📦 ${med.name} স্টকে নেই। অন্য ওষুধ বেছে নিন। / Out of stock.',
          isUser: false,
          isError: true,
          functionResponse: null,
        ));
      });
      return;
    }

    setState(() {
      _pendingMedicine = med;
      _awaitingQuantity = true;
      _messages.insert(0, (
        text:
            'ℹ️ ${med.name} নির্বাচন করা হয়েছে। কতটি নিতে চান? শুধু সংখ্যা লিখুন (যেমন 2)।\n\n${med.name} selected. How many units? Reply with a number (e.g., 2).',
        isUser: false,
        isError: false,
        functionResponse: {'action': 'awaiting_quantity', 'medicine': med.name},
      ));
    });
    try {
      _inputFocusNode.requestFocus();
    } catch (_) {}
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediPro Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _showTintPicker,
            icon: Icon(Icons.opacity, color: Colors.white.withOpacity(0.9)),
            tooltip: 'Adjust background tint',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/chatbot.jpg',
                      fit: BoxFit.cover,
                      // Darken slightly so chat bubbles remain readable
                      color: Colors.black.withOpacity(_bgTintOpacity),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),

                  // Soft overlay to adjust tint and improve contrast
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.6),
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Chat content on top
                  Positioned.fill(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildChatList(),
                  ),
                ],
              ),
            ),
            if (_showDoctorList) Flexible(child: _buildDoctorList()),
            if (_showMedicineList) Flexible(child: _buildMedicineList()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 80,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How can I help you today?',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ask me about health, doctors, medicines, or book appointments!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // Quick suggestion chips (expanded)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _suggestChip('🏥 ডাক্তার দেখাও', () {
                        _controller.text = 'Show me the list of doctors';
                        _sendMessage();
                      }),
                      _suggestChip('💊 ওষুধ তালিকা', () {
                        _controller.text = 'Show medicine list';
                        _sendMessage();
                      }),
                      _suggestChip('💡 স্বাস্থ্য টিপস', () {
                        _controller.text = 'Give me some general health tips';
                        _sendMessage();
                      }),
                      _suggestChip('🔍 প্যারাসিটামল?', () {
                        _controller.text = 'Is paracetamol available?';
                        _sendMessage();
                      }),
                      _suggestChip('📅 অ্যাপয়েন্টমেন্ট', () {
                        _controller.text = 'How to book appointment?';
                        _sendMessage();
                      }),
                      _suggestChip('🛒 ওষুধ অর্ডার', () {
                        _controller.text = 'How to order medicine?';
                        _sendMessage();
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<DoctorProvider>(
                        builder: (context, doctorProvider, child) {
                          return ElevatedButton.icon(
                            onPressed: () {
                              _controller.text = 'Show me the list of doctors';
                              _sendMessage();
                            },
                            icon: const Icon(Icons.medical_services),
                            label: const Text('View Doctors'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        onPressed: () {
                          _controller.text = 'Give me some general health tips';
                          _sendMessage();
                        },
                        icon: const Icon(Icons.health_and_safety),
                        label: const Text('Health Tips'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller.text = 'Show medicine list';
                      _sendMessage();
                    },
                    icon: const Icon(Icons.local_pharmacy),
                    label: const Text('Browse Medicines'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == 0) {
          return _buildLoadingIndicator();
        }

        final messageIndex = _isLoading ? index - 1 : index;
        final message = _messages[messageIndex];

        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MediPro is thinking...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Please wait',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ({
        String text,
        bool isUser,
        bool isError,
        Map<String, dynamic>? functionResponse
      }) message) {
    final isAppointmentSuccess =
        message.functionResponse?['status'] == 'success';
    final isHealthTips = message.functionResponse?['topic'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.medical_services,
                size: 18,
                color: Colors.blue.shade700,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () async {
                await Clipboard.setData(ClipboardData(text: message.text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : isAppointmentSuccess
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isHealthTips
                              ? LinearGradient(
                                  colors: [
                                    Colors.orange.shade50,
                                    Colors.orange.shade100
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : message.isError
                                  ? LinearGradient(
                                      colors: [
                                        Colors.red.shade50,
                                        Colors.red.shade100
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                  borderRadius: BorderRadius.circular(20),
                  border: isAppointmentSuccess
                      ? Border.all(color: Colors.green.shade200, width: 2)
                      : isHealthTips
                          ? Border.all(color: Colors.orange.shade200, width: 1)
                          : message.isError
                              ? Border.all(color: Colors.red.shade200, width: 1)
                              : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAppointmentSuccess)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Appointment Confirmed!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (isHealthTips)
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: Colors.orange.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Health Tips',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (isAppointmentSuccess || isHealthTips)
                      const SizedBox(height: 8),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : Colors.grey.shade800,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    if (message.isError) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Retry | আবার চেষ্টা'),
                            onPressed: _lastUserText == null
                                ? null
                                : () {
                                    _controller.text = _lastUserText!;
                                    _sendMessage();
                                  },
                          ),
                          ActionChip(
                            label: const Text('View Doctors | ডাক্তার দেখুন'),
                            onPressed: () {
                              _controller.text = 'Show me the list of doctors';
                              _sendMessage();
                            },
                          ),
                          ActionChip(
                            label: const Text(
                                'Book Appointment | অ্যাপয়েন্টমেন্ট'),
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.doctorList);
                            },
                          ),
                          ActionChip(
                            label: const Text('Go to Store | স্টোরে যান'),
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.store);
                            },
                          ),
                          ActionChip(
                            label: const Text('My Orders | আমার অর্ডার'),
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.myOrders);
                            },
                          ),
                        ],
                      ),
                    ],
                    if (message.functionResponse?['booking_id'] != null)
                      ..._buildAppointmentDetails(message.functionResponse!),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAppointmentDetails(Map<String, dynamic> response) {
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade100.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Doctor: ${response['doctor_name']}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Time: ${response['scheduled_time']}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Issue: ${response['patient_issue']}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Booking ID: ${response['booking_id']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final id = response['booking_id'];
                  if (id != null) {
                    Navigator.pushNamed(context, Routes.appointmentDetail,
                        arguments: id);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildDoctorList() {
    return Consumer<DoctorProvider>(
      builder: (context, doctorProvider, child) {
        final doctors = doctorProvider.doctors;

        if (doctors.isEmpty) {
          return Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Center(
              child: Text(
                'No doctors available at the moment',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available Doctors (${doctors.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.medical_services,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: Colors.blue.shade600,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  doctor.specialty,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    if (doctor.experienceYears != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${doctor.experienceYears} yrs',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (doctor.consultationFee != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Fee: ৳${doctor.consultationFee}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: doctor.isAvailable
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doctor.isAvailable ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: doctor.isAvailable
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: doctor.isAvailable
                                      ? () => _selectDoctor(doctor)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'Book',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicineList() {
    return Consumer<MedicineProvider>(
      builder: (context, medProvider, child) {
        final medicines = medProvider.medicines;

        if (medicines.isEmpty) {
          return Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Center(
              child: Text(
                'No medicines available',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available Medicines (${medicines.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.local_pharmacy,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    return Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_pharmacy,
                            color: Colors.green.shade600,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '৳${med.finalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    med.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () => _selectMedicine(med.name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Order',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _suggestChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      onPressed: onTap,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions chips
          if (_suggestions.isNotEmpty && !_isLoading)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    _controller.text = _suggestions[i];
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice mic button
          _VoiceMicButton(
            isListening: _isListening,
            available: _sttAvailable,
            onTap: _toggleVoice,
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isListening
                      ? Colors.red.shade300
                      : Colors.grey.shade300,
                  width: _isListening ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'Listening...'
                      : 'Ask anything...',
                  hintStyle: TextStyle(
                    color: _isListening
                        ? Colors.red.shade300
                        : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _controller.text.trim().isEmpty && !_isLoading
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : [Colors.blue.shade500, Colors.blue.shade700],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stt.stop();
    _controller.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Voice mic button ────────────────────────────────────────────────────────

class _VoiceMicButton extends StatefulWidget {
  final bool isListening;
  final bool available;
  final VoidCallback onTap;

  const _VoiceMicButton({
    required this.isListening,
    required this.available,
    required this.onTap,
  });

  @override
  State<_VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<_VoiceMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = widget.isListening;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: listening ? _scale.value : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: listening ? Colors.red.shade600 : Colors.blue.shade600,
            boxShadow: [
              BoxShadow(
                color: (listening ? Colors.red : Colors.blue)
                    .withValues(alpha: listening ? 0.45 : 0.25),
                blurRadius: listening ? 14 : 6,
                spreadRadius: listening ? 3 : 0,
              ),
            ],
          ),
          child: Icon(
            listening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
