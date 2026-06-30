// lib/screens/admin/sample_data_screen.dart
import 'package:flutter/material.dart';
// import 'package:medicore/utils/sample_data_generator.dart';
// If the file exists elsewhere, update the path accordingly, e.g.:
import 'package:medicore/utils/sample_data_generator.dart';

class SampleDataScreen extends StatefulWidget {
  const SampleDataScreen({super.key});

  @override
  State<SampleDataScreen> createState() => _SampleDataScreenState();
}

class _SampleDataScreenState extends State<SampleDataScreen> {
  final SampleDataGenerator _dataGenerator = SampleDataGenerator();
  bool _isGenerating = false;
  bool _isClearing = false;
  String _message = '';

  Future<void> _generateSampleData() async {
    setState(() {
      _isGenerating = true;
      _message = 'স্যাম্পল ডেটা জেনারেট করা হচ্ছে...';
    });

    try {
      await _dataGenerator.generateSampleData();
      setState(() {
        _message = 'বাংলাদেশি স্যাম্পল ডেটা সফলভাবে জেনারেট করা হয়েছে!';
      });
    } catch (e) {
      setState(() {
        _message = 'ত্রুটি: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isClearing = true;
      _message = 'সমস্ত ডেটা ডিলিট করা হচ্ছে...';
    });

    try {
      await _dataGenerator.clearAllData();
      setState(() {
        _message = 'সমস্ত ডেটা সফলভাবে ডিলিট করা হয়েছে!';
      });
    } catch (e) {
      setState(() {
        _message = 'ত্রুটি: $e';
      });
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বাংলাদেশি স্যাম্পল ডেটা'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.medical_services,
                        size: 50, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      'বাংলাদেশি মেডিকেল ডেটা',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'বাংলাদেশি ডাক্তার, রোগী, ওষুধ এবং অ্যাপয়েন্টমেন্টের স্যাম্পল ডেটা জেনারেট করুন',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateSampleData,
              icon: _isGenerating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.data_array),
              label: Text(_isGenerating
                  ? 'জেনারেট হচ্ছে...'
                  : 'স্যাম্পল ডেটা জেনারেট করুন'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isClearing ? null : _clearAllData,
              icon: _isClearing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(
                  _isClearing ? 'ডিলিট হচ্ছে...' : 'সমস্ত ডেটা ডিলিট করুন'),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('ত্রুটি')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _message.contains('ত্রুটি') ? Colors.red : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _message.contains('ত্রুটি')
                          ? Icons.error
                          : Icons.check_circle,
                      color: _message.contains('ত্রুটি')
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_message)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'স্যাম্পল ডেটা তালিকা:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    Text('• ৫ জন বাংলাদেশি ডাক্তার (বিভিন্ন স্পেশালিটি)'),
                    Text('• ৪ জন বাংলাদেশি রোগী'),
                    Text('• ৮ ধরনের ওষুধ (টাকায় দামসহ)'),
                    Text('• ৪টি অ্যাপয়েন্টমেন্ট (বাংলাদেশি কনটেক্সট)'),
                    SizedBox(height: 16),
                    Text(
                      'ডাক্তারদের তথ্য:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• বাংলা নাম ও স্পেশালিটি'),
                    Text('• BMDC রেজিস্ট্রেশন নম্বর'),
                    Text('• কনসালটেশন ফি (টাকায়)'),
                    Text('• চেম্বার ও ভিজিট টাইম'),
                    SizedBox(height: 16),
                    Text(
                      'ওষুধের তথ্য:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• বাংলা ও ইংরেজি নাম'),
                    Text('• জেনেরিক নাম ও কোম্পানি'),
                    Text('• দাম (টাকায়) ও স্ট্রেন্থ'),
                    Text('• ব্যবহার ও টাইপ'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
