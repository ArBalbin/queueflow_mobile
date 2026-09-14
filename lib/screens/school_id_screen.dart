import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

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
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const verticalPadding = 40.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Welcome,',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                            ),
                            const TextSpan(
                              text: ' This is your first time signing in.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter your student ID number to link it to this Google account. You'll only need to do this once.",
                        style: AppText.bodyMuted,
                      ),
                      const SizedBox(height: 32),
                      const Text('STUDENT ID', style: AppText.overline),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.borderMid),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14, color: AppColors.dark),
                          decoration: const InputDecoration(
                            hintText: 'ex. 21-1234',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Continue',
                        bg: AppColors.green,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}