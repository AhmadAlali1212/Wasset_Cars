import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/services/controllers/auth_service.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthService _authService = AuthService();

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppSnackbar.showWarning(context, title: 'كلمة المرور غير متطابقة');
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _authService.verifyPasswordOtp(
          email: widget.email,
          otp: _otpController.text,
        );

        await _authService.resetPassword(
          email: widget.email,
          otp: _otpController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

        if (!mounted) {
          return;
        }

        AppSnackbar.showSuccess(context, title: 'تم تغيير كلمة المرور بنجاح');

        Navigator.popUntil(context, (route) => route.isFirst);
      } on DioException catch (e) {
        final String message =
            ((e.response?.data is Map
                    ? (e.response!.data as Map)['message']
                    : null)
                ?.toString()) ??
            'حدث خطأ أثناء إعادة تعيين كلمة المرور';
        if (mounted) {
          AppSnackbar.showError(context, title: 'تعذّر تغيير كلمة المرور', subtitle: message);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_open_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'إنشاء كلمة مرور جديدة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'للحساب: ${widget.email}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _otpController,
                      hint: 'أدخل رمز OTP',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رمز OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'أدخل كلمة المرور الجديدة',
                      icon: Icons.lock_outlined,
                      isPassword: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخل كلمة المرور';
                        }
                        if (value.length < 8) {
                          return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hint: 'أعد إدخال كلمة المرور',
                      icon: Icons.lock_outlined,
                      isPassword: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء تأكيد كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    AuthButton(
                      text: 'تغيير كلمة المرور',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                      gradient: AppColors.primaryGradient,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
