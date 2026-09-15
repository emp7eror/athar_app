import 'package:get/get.dart';

/// One tafsir edition, as the server lists it (`GET /quran/tafsirs`).
class TafsirEdition {
  const TafsirEdition({
    required this.slug,
    required this.language,
    required this.nameAr,
    required this.nameEn,
    required this.authorAr,
    required this.authorEn,
    required this.url,
    required this.isDefault,
  });

  factory TafsirEdition.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] ?? '').toString().trim();
    final url = s('url');
    return TafsirEdition(
      slug: s('slug'),
      language: s('language').toLowerCase(),
      nameAr: s('name_ar'),
      nameEn: s('name_en'),
      authorAr: s('author_ar'),
      authorEn: s('author_en'),
      url: url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      isDefault: j['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'language': language,
        'name_ar': nameAr,
        'name_en': nameEn,
        'author_ar': authorAr,
        'author_en': authorEn,
        'url': url,
        'is_default': isDefault,
      };

  final String slug;

  /// ISO 639-1 code, e.g. `ar`, `en`, `ur`.
  final String language;
  final String nameAr;
  final String nameEn;
  final String authorAr;
  final String authorEn;

  /// The folder holding `{surah}/{ayah}.json`.
  final String url;

  /// Shown to readers of [language] who haven't chosen a tafsir.
  final bool isDefault;

  bool get isValid => slug.isNotEmpty && url.isNotEmpty && (nameAr.isNotEmpty || nameEn.isNotEmpty);

  static bool get _arabicApp => Get.locale?.languageCode == 'ar';

  static String _pick(String ar, String en) => _arabicApp ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);

  /// The name in the app's language.
  String get name => _pick(nameAr, nameEn);

  /// The author in the app's language; empty when it only repeats the name.
  String get author {
    final a = _pick(authorAr, authorEn);
    return a == name ? '' : a;
  }
}

/// The tafsir for one ayah.
class AyahTafsir {
  const AyahTafsir({
    required this.text,
    required this.surah,
    required this.ayah,
    required this.sourceAyah,
  });

  final String text;
  final int surah;

  /// The ayah that was asked for.
  final int ayah;

  /// The ayah the text is stored under. Tafsirs that explain several ayahs
  /// together store it on the first one, so this can be earlier than [ayah].
  final int sourceAyah;

  bool get sharedWithEarlierAyah => sourceAyah != ayah;
}

/// Native names for the language codes, so a reader recognises their own
/// language whatever language the app is in.
abstract final class TafsirLanguages {
  static const native = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'ur': 'اردو',
    'bn': 'বাংলা',
    'id': 'Bahasa Indonesia',
    'tr': 'Türkçe',
    'ru': 'Русский',
    'fa': 'فارسی',
    'ku': 'کوردی',
    'sq': 'Shqip',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'bs': 'Bosanski',
    'sr': 'Српски',
    'zh': '中文',
    'ja': '日本語',
    'vi': 'Tiếng Việt',
    'th': 'ไทย',
    'km': 'ខ្មែរ',
    'tl': 'Tagalog',
    'hi': 'हिन्दी',
    'ml': 'മലയാളം',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'si': 'සිංහල',
    'as': 'অসমীয়া',
    'ps': 'پښتو',
    'ug': 'ئۇيغۇرچە',
    'az': 'Azərbaycanca',
    'uz': 'Oʻzbekcha',
    'ky': 'Кыргызча',
    'ff': 'Fulfulde',
  };

  static String label(String code) => native[code] ?? code.toUpperCase();
}
