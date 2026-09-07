import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Shown once, right after a student's first-ever Google sign-in, to link
/// their Gbox account to their school ID number. Pops back to
/// StudentLoginScreen with the entered ID (or null if cancelled).
class SchoolIdScreen extends StatefulWidget {
  const SchoolIdScreen({super.key});

  @override
  State<SchoolIdScreen> createState() => _SchoolIdScreenState();
}

class _SchoolIdScreenState extends State<SchoolIdScreen> {
  final _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Enter your student ID number.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'One more step',
        showBack: true,
        // Popping with no value cancels the in-progress sign-up and returns
        // the caller (StudentLoginScreen) to the login screen.
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome! This is your first time signing in.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your student ID number to link it to this Google account. '
              "You'll only need to do this once.",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text(
              'STUDENT ID',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.borderMid),
                borderRadius: BorderRadius.circular(9),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 13, color: AppColors.dark),
                decoration: const InputDecoration(
                  hintText: 'e.g. 21-1234',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textLight),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 10, color: AppColors.red),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(label: 'Continue', onTap: _submit),
          ],
        ),
      ),
    );
  }
}
