import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// نتيجة محاولة الدفع عبر Stripe.
enum StripePaymentOutcome { success, canceled, failed }

class StripePaymentResult {
  final StripePaymentOutcome outcome;
  final String? message;

  const StripePaymentResult(this.outcome, {this.message});
}

/// يغلّف تفاعل flutter_stripe (تهيئة وعرض ورقة الدفع) في مكان واحد
/// حتى لا تتكرر نفس المنطق بكل شاشة محفظة (فردي/معرض).
class StripePaymentHelper {
  StripePaymentHelper._();

  // الحد الأقصى المسموح به من السيرفر لكل عملية شحن واحدة (بالدولار الأمريكي).
  // /wallet/stripe/create-intent يرفض أي amount_usd أكبر من هذه القيمة بخطأ 422.
  static const double maxTopupAmountUsd = 10000;

  static final Random _random = Random.secure();

  /// يولّد request_id فريداً (بصيغة UUID v4) مطلوباً إلزامياً من السيرفر
  /// مع كل طلب /wallet/stripe/create-intent (يُستخدم كمفتاح idempotency
  /// لمنع تكرار نفس عملية الشحن عند إعادة المحاولة).
  static String generateRequestId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // نسخة UUID v4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant RFC 4122
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  /// يبحث عن أول مفتاح موجود ضمن مجموعة أسماء محتملة، لأن تسمية حقول
  /// استجابة create-intent قد تختلف قليلاً (client_secret / clientSecret...).
  static String? _pick(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static String? extractClientSecret(Map<String, dynamic> response) {
    return _pick(response, [
      'client_secret',
      'clientSecret',
      'payment_intent_client_secret',
    ]);
  }

  static String? extractRequestId(Map<String, dynamic> response) {
    return _pick(response, ['request_id', 'requestId', 'id', 'topup_request_id']);
  }

  // نأخذ المفتاح العلني مباشرة من رد /wallet/stripe/create-intent
  // (الكونترولر يُرجعه كـ publishable_key = config('services.stripe.key'))
  // بدل الاعتماد على قيمة ثابتة بالتطبيق، لضمان تطابقه دائماً مع نفس
  // حساب/وضع Stripe المُستخدم فعلياً بالباك-إند.
  static String? extractPublishableKey(Map<String, dynamic> response) {
    return _pick(response, ['publishable_key', 'publishableKey', 'stripe_key']);
  }

  // رد /wallet/stripe/topups/{requestId} يُرجع الحالة متداخلة هكذا:
  // { "topup": { "status": "credited", ... } } وليست على المستوى الأعلى،
  // لذلك نتحقق من الشكلين لتفادي قراءة null بالخطأ رغم أن الحالة فعلاً credited.
  static String? extractTopupStatus(Map<String, dynamic> response) {
    final topup = response['topup'];
    if (topup is Map) {
      final nested = topup['status'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString();
      }
    }
    return _pick(response, ['status']);
  }

  static bool _looksLikeValidKey(String? key) {
    return key != null &&
        key.isNotEmpty &&
        key.startsWith('pk_') &&
        !key.contains('ضع_مفتاحك');
  }

  /// يتحقق أن هناك مفتاحاً علنياً صالحاً (إما القادم من السيرفر أو
  /// القيمة الافتراضية بـ constans.dart)، لعرض رسالة واضحة بدل خطأ Stripe
  /// المبهم لو نسي أحدهما ضبط مفتاحه.
  static bool get isPublishableKeyConfigured =>
      _looksLikeValidKey(Stripe.publishableKey);

  /// يهيّئ ورقة الدفع (Payment Sheet) ويعرضها للمستخدم لإكمال الدفع
  /// باستخدام client_secret القادم من /wallet/stripe/create-intent.
  /// [serverPublishableKey]: المفتاح العلني القادم من رد السيرفر نفسه —
  /// إن وُجد ويكون صالحاً، يُستخدم بدل القيمة الثابتة في constans.dart
  /// (وبذلك يبقى دائماً مطابقاً لنفس حساب/وضع Stripe الفعلي بالباك-إند).
  static Future<StripePaymentResult> pay({
    required String clientSecret,
    String? serverPublishableKey,
    String merchantDisplayName = 'Syria Motor',
  }) async {
    if (_looksLikeValidKey(serverPublishableKey) &&
        serverPublishableKey != Stripe.publishableKey) {
      Stripe.publishableKey = serverPublishableKey!;
      await Stripe.instance.applySettings();
    }

    if (!isPublishableKeyConfigured) {
      return const StripePaymentResult(
        StripePaymentOutcome.failed,
        message:
            'لم يتم ضبط مفتاح Stripe العلني (Publishable Key) بعد.\n'
            'تأكد من ضبط STRIPE_KEY في ملف .env بالباك-إند، أو ضع مفتاحك '
            'الحقيقي (pk_test_...) في lib/ulits/constans.dart كخيار احتياطي، '
            'من https://dashboard.stripe.com/test/apikeys',
      );
    }
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return const StripePaymentResult(StripePaymentOutcome.success);
    } on StripeException catch (e) {
      final message = (e.error.localizedMessage ?? e.error.message ?? '')
          .toString();
      final codeText = e.error.code.toString().toLowerCase();
      final isCanceled =
          codeText.contains('cancel') ||
          message.toLowerCase().contains('cancel') ||
          message.contains('تم الإلغاء');
      if (isCanceled) {
        return const StripePaymentResult(StripePaymentOutcome.canceled);
      }
      return StripePaymentResult(
        StripePaymentOutcome.failed,
        message: message.isEmpty ? 'فشلت عملية الدفع' : message,
      );
    } catch (e) {
      return StripePaymentResult(
        StripePaymentOutcome.failed,
        message: e.toString(),
      );
    }
  }
}
