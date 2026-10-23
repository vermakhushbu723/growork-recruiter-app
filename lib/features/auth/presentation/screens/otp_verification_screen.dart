import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_header.dart';

/// What the OTP screen is for. Without a [target] it first asks for the
/// phone number or email.
class OtpArgs {
  const OtpArgs({this.target, this.reset = false, this.devOtp});

  final String? target;

  /// Password reset instead of login.
  final bool reset;

  /// Code returned by the server in dev mode, shown as a hint.
  final String? devOtp;
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, this.args = const OtpArgs()});

  final OtpArgs args;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final _targetController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String? _target = widget.args.target;
  late String? _devOtp = widget.args.devOtp;
  bool _isLoading = false;

  bool get _reset => widget.args.reset;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _targetController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _send(String target) async {
    setState(() => _isLoading = true);
    String? dev;
    final ok = await context.runApi(() async {
      dev = await ref
          .read(authProvider.notifier)
          .sendOtp(target, reset: _reset);
    });
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (ok) {
        _target = target;
        _devOtp = dev;
        for (final c in _controllers) {
          c.clear();
        }
      }
    });
    if (ok) context.showSnackBar('Code sent to $target');
  }

  Future<void> _verify() async {
    if (_code.length != 4) {
      context.showSnackBar('Enter the 4-digit code', isError: true);
      return;
    }
    if (_reset && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(authProvider.notifier);
    final ok = await context.runApi(
      () => _reset
          ? notifier.resetPassword(_target!, _code, _passwordController.text)
          : notifier.verifyLoginOtp(_target!, _code),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!ok) return;
    if (_reset) {
      context.showSnackBar('Password updated. Please log in.');
      context.go(RoutePaths.login);
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: target == null
                      ? 'Log in with OTP'
                      : (_reset ? 'Reset your password' : 'Verify your number'),
                  subtitle: target == null
                      ? 'Enter your registered phone number or email'
                      : 'Enter the 4-digit code sent to $target',
                ),
                const SizedBox(height: 32),
                if (target == null) ...[
                  AppTextField(
                    label: 'Phone or email',
                    hint: '10-digit mobile number or email',
                    controller: _targetController,
                    prefixIcon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        Validators.required(v, field: 'Phone or email'),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send Code',
                    isLoading: _isLoading,
                    onPressed: () {
                      final t = _targetController.text.trim();
                      if (t.length < 5) {
                        context.showSnackBar(
                          'Enter your phone number or email',
                          isError: true,
                        );
                        return;
                      }
                      _send(t);
                    },
                  ),
                ] else ...[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < 3 ? 12 : 0,
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                  decoration: const InputDecoration(
                                    counterText: '',
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  if (_devOtp != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Test mode — your code is $_devOtp',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_reset) ...[
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'New password',
                      hint: 'At least 6 characters',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      validator: Validators.password,
                    ),
                  ],
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _reset ? 'Reset Password' : 'Verify',
                    isLoading: _isLoading,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: context.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () => _send(target),
                        child: const Text(
                          'Resend',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
