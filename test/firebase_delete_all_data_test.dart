// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Delete all Firebase data
/// Run with: flutter test test/firebase_delete_all_data_test.dart
void main() {
  group('Firebase Data Management', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      firestore = FirebaseFirestore.instance;
    });

    test('Print current Firebase statistics', () async {
      print('\n📊 Current Firebase Statistics:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final collections = [
        'users',
        'doctors',
        'patients',
        'appointments',
        'prescriptions',
        'medical_records',
        'hospitals',
        'health_profiles',
        'orders',
        'medicines',
        'cart',
        'reviews',
        'notifications',
        'accounts',
        'profiles',
      ];

      int totalDocs = 0;

      for (final collection in collections) {
        try {
          final count = await firestore.collection(collection).count().get();
          final docCount = count.count ?? 0;
          if (docCount > 0) {
            print('  📄 $collection: $docCount documents');
            totalDocs += docCount;
          }
        } catch (e) {
          // Collection might not exist
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('  ✅ Total: $totalDocs documents\n');
    });

    test('DELETE ALL FIREBASE DATA', () async {
      print('\n🔴 Starting deletion of ALL Firebase data...\n');

      final collections = [
        'users',
        'doctors',
        'patients',
        'appointments',
        'prescriptions',
        'medical_records',
        'hospitals',
        'health_profiles',
        'orders',
        'medicines',
        'cart',
        'reviews',
        'notifications',
        'accounts',
        'profiles',
      ];

      int totalDeleted = 0;

      for (final collection in collections) {
        try {
          final query = firestore.collection(collection);
          final docs = await query.get();

          if (docs.docs.isNotEmpty) {
            print(
                '🗑️  Deleting collection: $collection (${docs.docs.length} docs)');

            // Delete in batches
            WriteBatch batch = firestore.batch();
            int batchCount = 0;

            for (final doc in docs.docs) {
              batch.delete(doc.reference);
              batchCount++;
              totalDeleted++;

              if (batchCount % 100 == 0) {
                await batch.commit();
                print('   ✅ Deleted $batchCount documents...');
                batch = firestore.batch();
              }
            }

            // Commit remaining
            if (batchCount % 100 != 0) {
              await batch.commit();
              print('   ✅ Deleted remaining $batchCount documents');
            }
          }
        } catch (e) {
          // Collection might not exist, continue
        }
      }

      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ Successfully deleted $totalDeleted documents!');
      print('🎉 All Firebase data has been cleared!\n');
    });

    test('Delete specific collection', () async {
      // Change 'appointments' to any collection you want to delete
      const collectionToDelete = 'appointments';

      print('\n🗑️  Deleting collection: $collectionToDelete');

      try {
        final query = firestore.collection(collectionToDelete);
        final docs = await query.get();

        print('Found ${docs.docs.length} documents');

        WriteBatch batch = firestore.batch();
        int count = 0;

        for (final doc in docs.docs) {
          batch.delete(doc.reference);
          count++;

          if (count % 100 == 0) {
            await batch.commit();
            batch = firestore.batch();
          }
        }

        if (count > 0) {
          await batch.commit();
        }

        print('✅ Deleted $count documents from $collectionToDelete');
      } catch (e) {
        print('❌ Error: $e');
      }
    });

    test('Verify deletion complete', () async {
      print('\n✅ Verifying Firebase is empty...');

      final collections = [
        'users',
        'doctors',
        'patients',
        'appointments',
        'prescriptions',
        'medical_records',
        'hospitals',
        'health_profiles',
        'orders',
        'medicines',
        'cart',
        'reviews',
        'notifications',
      ];

      int remainingDocs = 0;

      for (final collection in collections) {
        try {
          final count = await firestore.collection(collection).count().get();
          remainingDocs += count.count ?? 0;
        } catch (e) {
          // Collection doesn't exist
        }
      }

      print('📊 Remaining documents: $remainingDocs');
      if (remainingDocs == 0) {
        print('🎉 Firebase is completely empty!\n');
      } else {
        print('⚠️  Still $remainingDocs documents remaining\n');
      }
    });
  });
}
