import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';
import '../models/queue_models.dart';
import '../services/queue_api.dart';
import '../services/queue_navigation.dart';
import '../services/queue_session_store.dart';
import '../services/student_session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _queueController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _queueController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final queue = _queueController.text.trim();
    final token = _tokenController.text.trim();

    if (queue.isEmpty || token.isEmpty) {
      setState(
        () =>
            _errorMessage = 'Please enter both queue number and access token.',
      );
      return;
    }

    try {
      await _startSession(queueInput: queue, tokenInput: token);
    } on FormatException catch (error) {
      _showError(error.message);
    } on QueueApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to check your ticket. Please try again.');
    }
  }

  Future<void> _handleScan() async {
    if (_isLoading) return;

    final rawValue = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || rawValue == null) return;

    try {
      final credentials = QueueSessionStore.api.parseTicketQr(rawValue);
      _queueController.text = credentials.queueLabel;
      _tokenController.text = credentials.accessToken;

      await _startSessionWithCredentials(credentials);
    } on FormatException catch (error) {
      _showError(error.message);
    } on QueueApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to check your ticket. Please try again.');
    }
  }

  Future<void> _startSession({
    required String queueInput,
    required String tokenInput,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final snapshot = await QueueSessionStore.startSession(
      queueInput: queueInput,
      tokenInput: tokenInput,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, routeForQueueSnapshot(snapshot));
  }

  Future<void> _startSessionWithCredentials(
    QueueCredentials credentials,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final snapshot = await QueueSessionStore.startSessionWithCredentials(
      credentials,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, routeForQueueSnapshot(snapshot));
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: QAppBar(
        showBack: true,
        onBack: () => Navigator.of(context).pushReplacementNamed(
          StudentSessionStore.isLoggedIn ? '/student/home' : '/student/login',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const Text(
                'CHECK YOUR QUEUE',
                textAlign: TextAlign.center,
                style: AppText.title,
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your ticket details below',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: 28),
              _ScanQrButton(onTap: _isLoading ? null : _handleScan),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.borderMid)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: AppColors.borderMid)),
                ],
              ),
              const SizedBox(height: 20),
              _InputField(
                label: 'QUEUE NUMBER',
                hint: 'e.g. Q004',
                controller: _queueController,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              _InputField(
                label: 'ACCESS TOKEN',
                hint: 'Enter your unique code',
                controller: _tokenController,
                isPassword: true,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      )
                    : PrimaryButton(
                        label: 'Check My Status',
                        bg: AppColors.green,
                        onTap: _handleLogin,
                      ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Token is shown on your queue slip',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanQrButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ScanQrButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
        decoration: BoxDecoration(
          color: enabled ? AppColors.greenLight : AppColors.border,
          border: Border.all(color: AppColors.green, width: 1.2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: enabled ? AppColors.greenDark : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              'Scan Ticket QR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.greenDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AppText.overline),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderMid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.isPassword && _obscure,
              textCapitalization: widget.textCapitalization,
              style: const TextStyle(fontSize: 14, color: AppColors.dark),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
                suffixIcon: widget.isPassword
                    ? GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      );
}