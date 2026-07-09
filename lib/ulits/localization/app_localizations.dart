import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  // هنا تضع نصوصك لاحقاً كما طلبت
  static const Map<String, Map<String, String>> _keys = {
    'ar': {
      'choose_language': 'اختر اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      // ضع بقية النصوص العربية هنا...
    },
    'en': {
      'choose_language': 'Choose Language',
      'arabic': 'Arabic',
      'english': 'English',
      // ضع بقية النصوص الإنجليزية هنا...
    },
  };

  Future<bool> load() async {
    _localizedStrings = _keys[locale.languageCode] ?? _keys['en']!;
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

// إختصار ذكي مريح جداً لاستدعاء الترجمة في أي ويدجت عن طريق: context.tr('key')
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}
