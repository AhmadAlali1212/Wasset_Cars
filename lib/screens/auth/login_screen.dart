import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/auth/acconnt_screen.dart';
import 'package:mators_car/screens/auth/forget_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';

import '../../services/auth_serivces.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AuthService _authService;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _authService = Provider.of<AuthService>(context, listen: false);
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) {
          return;
        }

        Navigator.pushReplacementNamed(context, '/main');
      } on DioException catch (e) {
        String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
        if (e.response != null) {
          if (e.response?.data['errors'] != null) {
            errorMessage = e.response?.data['errors'].entries
                .map((e) => '${e.value.join(', ')}')
                .join('\n');
          } else if (e.response?.data['message'] != null) {
            errorMessage = e.response?.data['message'];
          }
        }
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}')),
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
    // تم استخدام اللون الأبيض كلون خلفية أساسي لمحاكاة التصميم الجديد
    return Scaffold(
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
      body: ScaleTransition(
        scale: _animation,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // عنوان الشاشة الرئيسي بخط عريض وداكن
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937), // لون داكن عصري
                      ),
                    ),
                    const SizedBox(height: 30),

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
                      hint: 'ادخل البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      // ملاحظة: تأكد أن CustomTextField يدعم تخصيص الديكور الداخلي أو قم بتعديله ليتناسب مع التصميم بدون حواف دائرية مبالغ فيها
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) {
                          return 'البريد الإلكتروني غير صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

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
                      icon: Icons.lock_outline,
                      controller: _passwordController,
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
                          return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // رابط نسيت كلمة المرور أسفل الحقل مباشرة وبخط صغير أزرق كالتصميم
                    Align(
                      alignment:
                          Alignment
                              .centerLeft, // يتناسب مع التوجيه الأجنبي، يمكنك تحويله لـ centerRight إذا كان التطبيق كاملاً بالعربية
                      child: TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Future.delayed(const Duration(milliseconds: 100));
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ForgotPasswordScreen(),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.ease;
                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(
                            0xFF0052CC,
                          ), // اللون الأزرق الخاص بالروابط
                        ),
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration:
                                TextDecoration
                                    .underline, // خط تحت النص مثل الصورة
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // زر تسجيل الدخول العريض والمصمت بلون كحلي داكن جداً كالتصميم الرسمي
                    SizedBox(
                      width: double.infinity,
                      child: AuthButton(
                        text: 'تسجيل الدخول',
                        onPressed: _login,
                        isLoading: _isLoading,
                        // لتطابق دقيق مع الصورة، يفضل تغيير لون الزر داخل ويدجت AuthButton إلى اللون الكحلي الداكن (e.g., Color(0xFF051329))
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // السطر السفلي لإنشاء حساب جديد
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ليس لديك حساب؟ ',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountTypeScreen(),
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
                            'سجل الآن',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
