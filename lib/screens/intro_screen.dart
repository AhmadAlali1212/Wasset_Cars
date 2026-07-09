import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // تعيين الصورة النظيفة الجديدة كخلفية
        // ستحتاج إلى إضافة ملف image_4.png إلى مجلد أصولك
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/intro.jpg'), // أو مسار صورتك
            fit: BoxFit.cover, // أو BoxFit.fill حسب الحاجة
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // شعار/عنوان التطبيق بالعربية (Wasset CARs - "واسط كارز")
              const Text(
                'وسيط كارز', // أو 'Wasset CARs' بالعربية
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 40),

              // العبارة التسويقية الفرعية بالعربية
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'الطريقة الجديدة\nلشراء سيارتك المفضلة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // تخطيط الأزرار (فوق مبنى السيارات النظيف)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // زر "ابدأ الآن" بالعربية
                    ElevatedButton(
                      onPressed: () {
                        // إجراء تسجيل الدخول
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1E73BE,
                        ), // لون الزر الأصلي
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // لجعل الزر يملأ العرض كما في الصورة
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'ابدأ الآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // زر "تصفح كزائر" بالعربية
                    TextButton(
                      onPressed: () {
                        // تصفح كزائر
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.9),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'تصفح كزائر',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration:
                              TextDecoration.underline, // خط سفلي للتمييز
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
