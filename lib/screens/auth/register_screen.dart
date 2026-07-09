import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mators_car/screens/auth/login_screen.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';

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

  final AuthService _authService = AuthService();

  String _getAccountTypeName() {
    switch (widget.accountTypeId) {
      case 1:
        return 'فرد';
      case 2:
        return 'شركة';
      case 3:
        return 'ورشة';
      default:
        return '';
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب الموافقة على الشروط والأحكام')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final response = await _authService.register(
          name: _nameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          accountTypeId: widget.accountTypeId,
        );

        final token = response['access_token'];
        await AuthStorage.saveToken(token);

        Navigator.pushReplacementNamed(
          context,
          widget.accountTypeId == 1 ? '/home' : '/verification',
        );
      } on DioException catch (e) {
        String errorMessage = 'حدث خطأ أثناء التسجيل';
        if (e.response?.data != null) {
          if (e.response?.data['errors'] != null) {
            errorMessage = e.response?.data['errors'].entries
                .map((e) => '${e.value.join(', ')}')
                .join('\n');
          } else if (e.response?.data['message'] != null) {
            errorMessage = e.response?.data['message'];
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
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
                  Text(
                    widget.accountTypeId == 1
                        ? 'الاسم الكامل'
                        : 'اسم ${_getAccountTypeName()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
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
                  const Text(
                    'البريد الإلكتروني',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
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
                  const Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
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
                      if (value.length < 8) {
                        return 'رقم الهاتف غير صالح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل كلمة المرور
                  const Text(
                    'كلمة المرور',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,

                    hint: 'ادخل كلمة المرور',
                    isPassword: true,
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
                  const Text(
                    'تأكيد كلمة المرور',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,

                    hint: 'اعِد إدخال كلمة المرور',
                    isPassword: true,
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

                  // تنبيه لمراجعة المستندات (للشركات والورش)
                  if (widget.accountTypeId != 1) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFEF3C7,
                        ), // خلفية صفراء خفيفة للتنبيه
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سيتم مراجعة مستنداتك من قبل الإدارة قبل تفعيل الحساب',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // حقل الشروط والأحكام بتصميم منسق وثابت
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(
                          0xFF051329,
                        ), // لون داكن مطابق للزر
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'أوافق على ',
                              style: TextStyle(color: Color(0xFF4B5563)),
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Show terms and conditions
                              },
                              child: const Text(
                                'الشروط والأحكام',
                                style: TextStyle(
                                  color: Color(0xFF0052CC),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF0052CC),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
