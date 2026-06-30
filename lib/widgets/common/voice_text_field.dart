// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A TextField wrapper that shows a mic button in the suffix.
/// Tapping the mic starts voice recognition and appends (or replaces)
/// the recognised text into the [controller].
class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final String? hintText;
  final String? labelText;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool obscureText;
  final bool append; // true = append recognised text; false = replace
  final String localeId; // e.g. 'bn_BD' for Bengali, 'en_US' for English

  const VoiceTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.hintText,
    this.labelText,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.obscureText = false,
    this.append = true,
    this.localeId = 'en_US',
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField>
    with SingleTickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ok = await _stt.initialize(
      onError: (_) => _stopListening(),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (mounted) setState(() => _available = ok);
  }

  Future<void> _toggleListening() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_listening) {
      _stopListening();
      return;
    }

    setState(() => _listening = true);

    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: widget.localeId,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords;
        if (words.isEmpty) return;

        final ctrl = widget.controller;
        if (widget.append) {
          final current = ctrl.text;
          final separator = current.isNotEmpty &&
                  !current.endsWith(' ') &&
                  !current.endsWith('\n')
              ? ' '
              : '';
          ctrl.text = '$current$separator$words';
        } else {
          ctrl.text = words;
        }
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        widget.onChanged?.call(ctrl.text);
      },
    );
  }

  void _stopListening() {
    _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
        );

    final micButton = widget.readOnly || widget.obscureText
        ? null
        : GestureDetector(
            onTap: _toggleListening,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _listening
                  ? AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Icon(
                        Icons.mic_rounded,
                        color: Color.lerp(Colors.red.shade400,
                            Colors.red.shade700, _pulse.value),
                        size: 22,
                      ),
                    )
                  : Icon(
                      Icons.mic_none_rounded,
                      color: _available
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      size: 22,
                    ),
            ),
          );

    final decoration = base.copyWith(
      suffixIcon: micButton != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (base.suffixIcon != null) base.suffixIcon!,
                micButton,
              ],
            )
          : base.suffixIcon,
    );

    return TextField(
      controller: widget.controller,
      decoration: decoration,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
    );
  }
}

/// Lightweight mic icon button — attach to any existing TextField's suffixIcon.
/// Usage:
///   suffixIcon: VoiceSuffixButton(controller: _ctrl, onResult: (t) { ... })
class VoiceSuffixButton extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onResult;
  final bool append;
  final String localeId;

  const VoiceSuffixButton({
    super.key,
    required this.controller,
    this.onResult,
    this.append = true,
    this.localeId = 'en_US',
  });

  @override
  State<VoiceSuffixButton> createState() => _VoiceSuffixButtonState();
}

class _VoiceSuffixButtonState extends State<VoiceSuffixButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _stt
        .initialize(
          onError: (_) => _stop(),
          onStatus: (s) {
            if (s == 'done' || s == 'notListening') {
              if (mounted) setState(() => _listening = false);
            }
          },
        )
        .then((ok) => { if (mounted) setState(() => _available = ok) });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_available) return;
    if (_listening) { _stop(); return; }
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: widget.localeId,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (r) {
        if (!mounted || r.recognizedWords.isEmpty) return;
        final ctrl = widget.controller;
        final words = r.recognizedWords;
        if (widget.append) {
          final sep = ctrl.text.isNotEmpty && !ctrl.text.endsWith(' ') ? ' ' : '';
          ctrl.text = '${ctrl.text}$sep$words';
        } else {
          ctrl.text = words;
        }
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        widget.onResult?.call(ctrl.text);
      },
    );
  }

  void _stop() {
    _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available && !_listening) {
      return Icon(Icons.mic_off_rounded, color: Colors.grey.shade300, size: 20);
    }
    return GestureDetector(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _listening
            ? AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Icon(
                  Icons.mic_rounded,
                  color: Color.lerp(
                      Colors.red.shade400, Colors.red.shade700, _pulse.value),
                  size: 22,
                ),
              )
            : Icon(
                Icons.mic_none_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
      ),
    );
  }
}
