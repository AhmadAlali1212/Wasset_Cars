import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/auth/login_screen.dart';
import 'package:mators_car/screens/auth/verification_screen.dart';
import 'package:mators_car/services/controllers/auth_serivces.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/auth/register/register_screen_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final int accountTypeId;

  const RegisterScreen({super.key, required this.accountTypeId});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _obscurePassword = true;

  late AuthService _authService;

  String _getAccountTypeName() {
    switch (widget.accountTypeId) {
      case 1:
        return 'فرد';
      case 2:
        return 'شركة';
      default:
        return '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        AppSnackbar.showWarning(
          context,
          title: 'يجب الموافقة على الشروط والأحكام',
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _authService.register(
          name: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          accountTypeId: widget.accountTypeId,
        );

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => VerificationScreen(
                  accountTypeId: widget.accountTypeId,
                  email: _emailController.text,
                ),
          ),
        );
      } on DioException catch (e) {
        String errorMessage = 'حدث خطأ أثناء التسجيل';
        final responseData = e.response?.data;

        if (responseData is Map && responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map;
          final lines =
              errors.entries.map((entry) {
                final value = entry.value;
                if (value is List) {
                  return '${entry.key}: ${value.join(', ')}';
                }
                return '${entry.key}: ${value.toString()}';
              }).toList();
          if (lines.isNotEmpty) {
            errorMessage = lines.join('\n');
          }
        } else if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
        // ملاحظة: لا نستخدم e.message/e.error/e.toString() كرسالة احتياطية
        // بعد الآن لأنها نصوص تقنية خام (مثل "DioException [connection
        // timeout]")، غير مناسبة لعرضها على المستخدم. تُطبع فقط بالتصحيح.
        debugPrint('Register DioException: $e');
        if (!mounted) {
          return;
        }
        AppSnackbar.showError(
          context,
          title: 'تعذّر إنشاء الحساب',
          subtitle: errorMessage,
        );
      } catch (e) {
        if (!mounted) {
          return;
        }
        AppSnackbar.showError(
          context,
          title: 'تعذّر إنشاء الحساب',
          subtitle: 'حدث خطأ غير متوقع أثناء التسجيل',
          debugMessage: e,
        );
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
      // خلفية بيضاء بالكامل مطابقة للتصميم العصري
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان الرئيسي بنمط Carvana
                  const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // عرض نوع الحساب المختار بشكل مبسط كجزء من الهوية الجديدة
                  Text(
                    'نوع الحساب الحالي: ${_getAccountTypeName()}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // حقل الاسم
                  RegisterFieldLabel(
                    widget.accountTypeId == 1
                        ? 'الاسم الكامل'
                        : 'اسم ${_getAccountTypeName()}',
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    icon: Icons.person,
                    controller: _nameController,
                    hint:
                        widget.accountTypeId == 1
                            ? 'ادخل اسمك الكامل'
                            : 'ادخل اسم ${_getAccountTypeName()}',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل البريد الإلكتروني
                  const RegisterFieldLabel('البريد الإلكتروني'),
                  const SizedBox(height: 8),
                  CustomTextField(
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    hint: 'ادخل بريدك الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return 'البريد الإلكتروني غير صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل رقم الهاتف
                  const RegisterFieldLabel('رقم الهاتف'),
                  const SizedBox(height: 8),
                  CustomTextField(
                    icon: Icons.phone_android_outlined,
                    controller: _phoneController,
                    hint: 'ادخل رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الهاتف';
                      }
                      if (value.length < 10) {
                        return 'رقم الهاتف غير صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  const RegisterFieldLabel('كلمة المرور'),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,

                    hint: 'ادخل كلمة المرور',
                    isPassword: _obscurePassword,

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل تأكيد كلمة المرور
                  const RegisterFieldLabel('تأكيد كلمة المرور'),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,

                    hint: 'اعِد إدخال كلمة المرور',
                    isPassword: _obscurePassword,

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // تنبيه لمراجعة المستندات (للشركات)
                  if (widget.accountTypeId != 1) ...[
                    const DocumentReviewNotice(),
                    const SizedBox(height: 20),
                  ],

                  // حقل الشروط والأحكام بتصميم منسق وثابت
                  TermsAgreementRow(
                    accepted: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    onTapTerms: () {
                      // TODO: Show terms and conditions
                    },
                  ),
                  const SizedBox(height: 28),

                  // زر إنشاء الحساب العريض بلون كحلي داكن
                  SizedBox(
                    width: double.infinity,
                    child: AuthButton(
                      text: 'إنشاء حساب',
                      onPressed: _register,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // السطر السفلي للانتقال لتسجيل الدخول
                  LoginPromptRow(
                    onTapLogin: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
