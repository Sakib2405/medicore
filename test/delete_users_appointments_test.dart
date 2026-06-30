// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Delete only Users and Appointments data from Firebase
/// Run with: flutter test test/delete_users_appointments_test.dart -v
void main() {
  group('Delete Users and Appointments Only', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      firestore = FirebaseFirestore.instance;
    });

    test('Show current Users and Appointments count', () async {
      print('\n📊 Current Data Statistics:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      try {
        final usersCount = await firestore.collection('users').count().get();
        print('  👥 Users: ${usersCount.count ?? 0} documents');

        final appointmentsCount =
            await firestore.collection('appointments').count().get();
        print('  📅 Appointments: ${appointmentsCount.count ?? 0} documents');

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      } catch (e) {
        print('Error getting counts: $e');
      }
    });

    test('DELETE Users Collection', () async {
      print('\n🗑️  Deleting Users Collection...');

      try {
        final query = firestore.collection('users');
        final docs = await query.get();

        print('📄 Found ${docs.docs.length} user documents');

        if (docs.docs.isEmpty) {
          print('✅ Users collection is already empty\n');
          return;
        }

        WriteBatch batch = firestore.batch();
        int count = 0;

        for (final doc in docs.docs) {
          batch.delete(doc.reference);
          count++;

          if (count % 100 == 0) {
            await batch.commit();
            print('   ✅ Deleted $count users...');
            batch = firestore.batch();
          }
        }

        if (count % 100 != 0) {
          await batch.commit();
        }

        print('✅ Successfully deleted $count users\n');
      } catch (e) {
        print('❌ Error deleting users: $e\n');
      }
    });

    test('DELETE Appointments Collection', () async {
      print('\n🗑️  Deleting Appointments Collection...');

      try {
        final query = firestore.collection('appointments');
        final docs = await query.get();

        print('📄 Found ${docs.docs.length} appointment documents');

        if (docs.docs.isEmpty) {
          print('✅ Appointments collection is already empty\n');
          return;
        }

        WriteBatch batch = firestore.batch();
        int count = 0;

        for (final doc in docs.docs) {
          batch.delete(doc.reference);
          count++;

          if (count % 100 == 0) {
            await batch.commit();
            print('   ✅ Deleted $count appointments...');
            batch = firestore.batch();
          }
        }

        if (count % 100 != 0) {
          await batch.commit();
        }

        print('✅ Successfully deleted $count appointments\n');
      } catch (e) {
        print('❌ Error deleting appointments: $e\n');
      }
    });

    test('Verify deletion complete', () async {
      print('\n✅ Verification:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      try {
        final usersCount = await firestore.collection('users').count().get();
        final userDocs = usersCount.count ?? 0;
        print('  👥 Users remaining: $userDocs');

        final appointmentsCount =
            await firestore.collection('appointments').count().get();
        final appointmentDocs = appointmentsCount.count ?? 0;
        print('  📅 Appointments remaining: $appointmentDocs');

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (userDocs == 0 && appointmentDocs == 0) {
          print('\n🎉 All Users and Appointments deleted successfully!\n');
        } else {
          print('\n⚠️  Some data still remains\n');
        }
      } catch (e) {
        print('Error during verification: $e');
      }
    });
  });
}
