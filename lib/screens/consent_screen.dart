import 'package:flutter/material.dart';

import '../services/privacy_notice.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Data-privacy notice and consent, shown before registration and to existing
/// accounts that have not agreed to the current notice. Pops `true` when the
/// student agrees and `false` (or nothing) when they decline or go back.
///
/// With [readOnly] it only displays the notice, for reading it again from
/// the Profile screen.
class ConsentScreen extends StatefulWidget {
  final bool readOnly;
  const ConsentScreen({super.key, this.readOnly = false});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        title: 'Privacy notice',
        showBack: true,
        onBack: () => Navigator.of(context).pop(false),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Privacy Notice and Consent', style: AppText.title),
                    const SizedBox(height: 8),
                    const Text(kNoticeIntro, style: AppText.bodyMuted),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.borderMid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final section in kNoticeSections) ...[
                            Text(section.heading, style: AppText.heading),
                            const SizedBox(height: 4),
                            Text(section.body, style: AppText.body),
                            const SizedBox(height: 14),
                          ],
                          Text('Notice version $kConsentVersion', style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.readOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: PrimaryButton(
                  label: 'Close',
                  bg: AppColors.dark,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              )
            else
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 24, 20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: AppColors.green,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(kConsentStatement, style: AppText.body),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: 'I agree',
                            bg: _agreed ? AppColors.green : AppColors.textLight,
                            onTap: _agreed ? () => Navigator.of(context).pop(true) : null,
                          ),
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: 'Not now',
                            outlined: true,
                            onTap: () => Navigator.of(context).pop(false),
                          ),
                        ],
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
}
