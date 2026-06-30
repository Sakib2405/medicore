// lib/utils/sample_data_generator.dart
// ignore_for_file: avoid_print, unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/appointment_model.dart';

class SampleDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bangladeshi Doctor Names and Specialties
  final List<Map<String, dynamic>> _bangladeshiDoctors = [
    {
      'id': 'doc_001',
      'name': 'ডা. আহমেদ হাসান',
      'specialty': 'কার্ডিওলজিস্ট',
      'bmdcNumber': 'A-12345',
      'email': 'ahmed.hasan@example.com',
      'phone': '+8801712345678',
      'experience': '১৫ বছর',
      'rating': 4.8,
      'available': true,
      'fees': 500, // Consultation fees in Taka
      'chamber': 'ঢাকা মেডিকেল কলেজ হাসপাতাল',
      'visitTime': 'সকাল ৯টা - দুপুর ১টা',
      'imageUrl': 'https://example.com/doctor1.jpg'
    },
    {
      'id': 'doc_002',
      'name': 'ডা. ফাতেমা বেগম',
      'specialty': 'গাইনোকলজিস্ট',
      'bmdcNumber': 'B-67890',
      'email': 'fatema.begum@example.com',
      'phone': '+8801812345678',
      'experience': '১২ বছর',
      'rating': 4.7,
      'available': true,
      'fees': 600,
      'chamber': 'বঙ্গবন্ধু শেখ মুজিব মেডিকেল বিশ্ববিদ্যালয়',
      'visitTime': 'বিকাল ৪টা - রাত ৮টা',
      'imageUrl': 'https://example.com/doctor2.jpg'
    },
    {
      'id': 'doc_003',
      'name': 'ডা. রাজীব কর',
      'specialty': 'অর্থোপেডিক সার্জন',
      'bmdcNumber': 'C-54321',
      'email': 'rajib.kar@example.com',
      'phone': '+8801912345678',
      'experience': '১০ বছর',
      'rating': 4.6,
      'available': true,
      'fees': 700,
      'chamber': 'আপোলো হাসপাতাল, ঢাকা',
      'visitTime': 'সকাল ১০টা - বিকাল ৫টা',
      'imageUrl': 'https://example.com/doctor3.jpg'
    },
    {
      'id': 'doc_004',
      'name': 'ডা. সুমাইয়া আক্তার',
      'specialty': 'পেডিয়াট্রিশিয়ান',
      'bmdcNumber': 'D-98765',
      'email': 'sumaiya.akter@example.com',
      'phone': '+8801612345678',
      'experience': '৮ বছর',
      'rating': 4.9,
      'available': true,
      'fees': 400,
      'chamber': 'ইবনে সিনা ডায়াগনস্টিক সেন্টার',
      'visitTime': 'সকাল ৮টা - দুপুর ২টা',
      'imageUrl': 'https://example.com/doctor4.jpg'
    },
    {
      'id': 'doc_005',
      'name': 'ডা. নাজমুল হক',
      'specialty': 'ডার্মাটোলজিস্ট',
      'bmdcNumber': 'E-13579',
      'email': 'nazmul.haque@example.com',
      'phone': '+8801512345678',
      'experience': '৭ বছর',
      'rating': 4.5,
      'available': true,
      'fees': 550,
      'chamber': 'ল্যাবএইড স্পেশালাইজড হাসপাতাল',
      'visitTime': 'বিকাল ৩টা - রাত ৯টা',
      'imageUrl': 'https://example.com/doctor5.jpg'
    }
  ];

  // Bangladeshi Patient Names
  final List<Map<String, dynamic>> _bangladeshiPatients = [
    {
      'id': 'patient_001',
      'name': 'করিম উদ্দিন',
      'email': 'karim.uddin@example.com',
      'phone': '+8801711122233',
      'age': 45,
      'gender': 'পুরুষ',
      'bloodGroup': 'O+',
      'address': 'মোহাম্মদপুর, ঢাকা'
    },
    {
      'id': 'patient_002',
      'name': 'আয়শা সিদ্দিকা',
      'email': 'aysha.siddika@example.com',
      'phone': '+8801722233344',
      'age': 32,
      'gender': 'মহিলা',
      'bloodGroup': 'A+',
      'address': 'গুলশান, ঢাকা'
    },
    {
      'id': 'patient_003',
      'name': 'রফিকুল ইসলাম',
      'email': 'rafiqul.islam@example.com',
      'phone': '+8801733344455',
      'age': 28,
      'gender': 'পুরুষ',
      'bloodGroup': 'B+',
      'address': 'উত্তরা, ঢাকা'
    },
    {
      'id': 'patient_004',
      'name': 'নুসরাত জাহান',
      'email': 'nusrat.jahan@example.com',
      'phone': '+8801744455566',
      'age': 35,
      'gender': 'মহিলা',
      'bloodGroup': 'AB+',
      'address': 'ধানমন্ডি, ঢাকা'
    }
  ];

  // Bangladeshi Medicine Data with Prices in Taka
  final List<Map<String, dynamic>> _bangladeshiMedicines = [
    {
      'id': 'med_001',
      'name': 'Napa Extra',
      'genericName': 'Paracetamol + Caffeine',
      'company': 'Beximco Pharmaceuticals',
      'price': 2.50,
      'type': 'ট্যাবলেট',
      'strength': '500mg + 65mg',
      'uses': 'জ্বর, মাথাব্যথা, দাঁতের ব্যথা',
      'availability': true
    },
    {
      'id': 'med_002',
      'name': 'Ace',
      'genericName': 'Aceclofenac',
      'company': 'Square Pharmaceuticals',
      'price': 8.00,
      'type': 'ট্যাবলেট',
      'strength': '100mg',
      'uses': 'বাতের ব্যথা, হাড়ের ব্যথা',
      'availability': true
    },
    {
      'id': 'med_003',
      'name': 'Montene',
      'genericName': 'Montelukast',
      'company': 'Incepta Pharmaceuticals',
      'price': 12.00,
      'type': 'ট্যাবলেট',
      'strength': '10mg',
      'uses': 'হাঁপানি, অ্যালার্জি',
      'availability': true
    },
    {
      'id': 'med_004',
      'name': 'Esloric',
      'genericName': 'Allopurinol',
      'company': 'Drug International',
      'price': 6.50,
      'type': 'ট্যাবলেট',
      'strength': '100mg',
      'uses': 'গাউট, ইউরিক অ্যাসিড',
      'availability': true
    },
    {
      'id': 'med_005',
      'name': 'Rex',
      'genericName': 'Omeprazole',
      'company': 'Opsonin Pharma',
      'price': 5.00,
      'type': 'ক্যাপসুল',
      'strength': '20mg',
      'uses': 'অ্যাসিডিটি, গ্যাস্ট্রিক',
      'availability': true
    },
    {
      'id': 'med_006',
      'name': 'Atova',
      'genericName': 'Atorvastatin',
      'company': 'Healthcare Pharmaceuticals',
      'price': 15.00,
      'type': 'ট্যাবলেট',
      'strength': '10mg',
      'uses': 'কোলেস্টেরল কমানো',
      'availability': true
    },
    {
      'id': 'med_007',
      'name': 'Metfor',
      'genericName': 'Metformin',
      'company': 'ACI Limited',
      'price': 4.00,
      'type': 'ট্যাবলেট',
      'strength': '500mg',
      'uses': 'ডায়াবেটিস নিয়ন্ত্রণ',
      'availability': true
    },
    {
      'id': 'med_008',
      'name': 'Ambrox',
      'genericName': 'Ambroxol',
      'company': 'Sanofi Bangladesh',
      'price': 7.50,
      'type': 'সিরাপ',
      'strength': '30mg/5ml',
      'uses': 'কাশি, কফ',
      'availability': true
    }
  ];

  // Bangladeshi Medical Reasons
  final List<String> _bangladeshiMedicalReasons = [
    'জ্বর ও সর্দি-কাশির সমস্যা',
    'পেটের ব্যথা ও গ্যাস্ট্রিক',
    'মাথাব্যথা ও মাইগ্রেন',
    'হাঁপানি ও শ্বাসকষ্ট',
    'ডায়াবেটিস চেকআপ',
    'প্রেসার ও হার্টের সমস্যা',
    'চর্মরোগ ও অ্যালার্জি',
    'হাড় ও জয়েন্টের ব্যথা',
    'সাধারণ স্বাস্থ্য পরীক্ষা',
    'ওষুধের প্রেসক্রিপশন'
  ];

  // Generate Sample Bangladeshi Data
  Future<void> generateSampleData() async {
    try {
      print('বাংলাদেশি স্যাম্পল ডেটা জেনারেট করা হচ্ছে...');

      // Add Bangladeshi Doctors
      for (final doctor in _bangladeshiDoctors) {
        await _firestore.collection('doctors').doc(doctor['id']).set(doctor);
        print('ডাক্তার যোগ করা হয়েছে: ${doctor['name']}');
      }

      // Add Bangladeshi Patients
      for (final patient in _bangladeshiPatients) {
        await _firestore.collection('patients').doc(patient['id']).set(patient);
        print('পেশেন্ট যোগ করা হয়েছে: ${patient['name']}');
      }

      // Add Bangladeshi Medicines
      for (final medicine in _bangladeshiMedicines) {
        await _firestore
            .collection('medicines')
            .doc(medicine['id'])
            .set(medicine);
        print(
            'ওষুধ যোগ করা হয়েছে: ${medicine['name']} - ${medicine['price']} টাকা');
      }

      // Generate Sample Appointments with Bangladeshi context
      await _generateBangladeshiAppointments();

      print('বাংলাদেশি স্যাম্পল ডেটা সফলভাবে জেনারেট করা হয়েছে!');
    } catch (e) {
      print('স্যাম্পল ডেটা জেনারেট করতে সমস্যা: $e');
      throw Exception('স্যাম্পল ডেটা জেনারেট করতে ব্যর্থ: $e');
    }
  }

  Future<void> _generateBangladeshiAppointments() async {
    final sampleAppointments = [
      {
        'patientId': 'patient_001',
        'doctorId': 'doc_001',
        'doctorName': 'ডা. আহমেদ হাসান',
        'doctorSpecialty': 'কার্ডিওলজিস্ট',
        'patientName': 'করিম উদ্দিন',
        'appointmentDate': Timestamp.fromDate(DateTime(2024, 2, 15, 10, 0)),
        'timeSlot': 'সকাল ১০:০০',
        'status': 'confirmed',
        'notes': 'হার্টের সাধারণ চেকআপ, ইসিজি টেস্টের প্রয়োজন',
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 10, 9, 0)),
        'reason': 'প্রেসার ও হার্টের সমস্যা',
        'consultationFee': 500,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 2, 12, 14, 30)),
      },
      {
        'patientId': 'patient_002',
        'doctorId': 'doc_002',
        'doctorName': 'ডা. ফাতেমা বেগম',
        'doctorSpecialty': 'গাইনোকলজিস্ট',
        'patientName': 'আয়শা সিদ্দিকা',
        'appointmentDate': Timestamp.fromDate(DateTime(2024, 2, 16, 16, 30)),
        'timeSlot': 'বিকাল ৪:৩০',
        'status': 'pending',
        'notes': 'নিয়মিত গাইনোকলজি চেকআপ',
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 11, 11, 0)),
        'reason': 'সাধারণ স্বাস্থ্য পরীক্ষা',
        'consultationFee': 600,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 2, 11, 11, 0)),
      },
      {
        'patientId': 'patient_003',
        'doctorId': 'doc_005',
        'doctorName': 'ডা. নাজমুল হক',
        'doctorSpecialty': 'ডার্মাটোলজিস্ট',
        'patientName': 'রফিকুল ইসলাম',
        'appointmentDate': Timestamp.fromDate(DateTime(2024, 2, 18, 17, 0)),
        'timeSlot': 'বিকাল ৫:০০',
        'status': 'confirmed',
        'notes': 'ত্বকের অ্যালার্জি সমস্যা, নতুন ক্রিম প্রেসক্রাইব করা হয়েছে',
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 5, 15, 0)),
        'reason': 'চর্মরোগ ও অ্যালার্জি',
        'consultationFee': 550,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 2, 17, 12, 0)),
      },
      {
        'patientId': 'patient_004',
        'doctorId': 'doc_003',
        'doctorName': 'ডা. রাজীব কর',
        'doctorSpecialty': 'অর্থোপেডিক সার্জন',
        'patientName': 'নুসরাত জাহান',
        'appointmentDate': Timestamp.fromDate(DateTime(2024, 2, 20, 11, 0)),
        'timeSlot': 'সকাল ১১:০০',
        'status': 'completed',
        'notes':
            'হাঁটুর ব্যথার চিকিৎসা completed, ফিজিওথেরাপি সুপারিশ করা হয়েছে',
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 8, 14, 0)),
        'reason': 'হাড় ও জয়েন্টের ব্যথা',
        'consultationFee': 700,
        'updatedAt': Timestamp.fromDate(DateTime(2024, 2, 20, 12, 0)),
      },
    ];

    // Example usage of _bangladeshiMedicalReasons: print all reasons
    print('বাংলাদেশি মেডিকেল কারণসমূহ:');
    for (final reason in _bangladeshiMedicalReasons) {
      print(reason);
    }

    // Add sample appointments to Firestore
    for (final appointmentData in sampleAppointments) {
      final docRef = _firestore.collection('appointments').doc();

      final appointmentWithId = {
        'id': docRef.id,
        ...appointmentData,
        // Example: attach all medical reasons to each appointment for demonstration
        'allMedicalReasons': _bangladeshiMedicalReasons,
      };

      await docRef.set(appointmentWithId);
      print(
          'অ্যাপয়েন্টমেন্ট যোগ করা হয়েছে: ${appointmentData['patientName']} - ${appointmentData['doctorName']}');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final collections = ['doctors', 'patients', 'medicines', 'appointments'];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      print('সমস্ত ডেটা সফলভাবে ডিলিট করা হয়েছে!');
    } catch (e) {
      print('ডেটা ডিলিট করতে সমস্যা: $e');
    }
  }

  // Check if sample data exists
  Future<bool> checkSampleDataExists() async {
    try {
      final appointmentsSnapshot =
          await _firestore.collection('appointments').limit(1).get();
      return appointmentsSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
