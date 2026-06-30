import 'package:flutter/material.dart';
import 'package:medicore/providers/ai_provider.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';
import 'package:provider/provider.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final List<String> _selectedSymptoms = [];
  final _otherSymptomsController = TextEditingController();

  final List<String> _commonSymptoms = [
    'Fever',
    'Cough',
    'Headache',
    'Sore Throat',
    'Shortness of Breath',
    'Fatigue',
    'Runny Nose',
    'Body Ache',
    'Nausea',
    'Vomiting',
    'Diarrhea',
    'Dizziness',
    'Chest Pain',
    'Skin Rash',
    'Loss of Appetite',
    'Chills',
    'Stomach Pain',
    'Joint Pain',
  ];

  @override
  void dispose() {
    _otherSymptomsController.dispose();
    super.dispose();
  }

  void _onSymptomSelected(bool selected, String symptom) {
    setState(() {
      if (selected) {
        _selectedSymptoms.add(symptom);
      } else {
        _selectedSymptoms.remove(symptom);
      }
    });
  }

  Future<void> _analyzeSymptoms() async {
    if (_selectedSymptoms.isEmpty &&
        _otherSymptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom.')),
      );
      return;
    }

    final aiProvider = Provider.of<AiProvider>(context, listen: false);

    // Start analysis — show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AnalysisResultDialog(aiProvider: aiProvider),
    );

    await aiProvider.analyzeSymptoms(
      _selectedSymptoms,
      _otherSymptomsController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select your symptoms below and our AI will provide an initial assessment. This is not a medical diagnosis.',
                      style: TextStyle(color: Color(0xFF1E40AF), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Common Symptoms',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _commonSymptoms.map((symptom) {
                final selected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: selected,
                  onSelected: (v) => _onSymptomSelected(v, symptom),
                  selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF2563EB) : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Additional Symptoms',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            VoiceTextField(
              controller: _otherSymptomsController,
              decoration: InputDecoration(
                labelText: 'Describe other symptoms (optional)',
                hintText: 'e.g., muscle ache, night sweats...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 12),
            if (_selectedSymptoms.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedSymptoms.length} symptom${_selectedSymptoms.length > 1 ? 's' : ''} selected',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _analyzeSymptoms,
                icon: const Icon(Icons.psychology_outlined),
                label: const Text(
                  'Analyze My Symptoms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AnalysisResultDialog extends StatelessWidget {
  final AiProvider aiProvider;

  const _AnalysisResultDialog({required this.aiProvider});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.psychology_outlined, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: ChangeNotifierProvider.value(
        value: aiProvider,
        child: Consumer<AiProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing your symptoms...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is not a medical diagnosis. Please consult a doctor.',
                            style: TextStyle(color: Color(0xFFEA580C), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    provider.analysisResult ?? 'No result available.',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
