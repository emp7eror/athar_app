import 'package:get/get.dart';

/// One reciter, as the server lists it (`GET /quran/reciters`).
class Reciter {
  const Reciter({
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.url,
    required this.extension,
    required this.isDefault,
  });

  factory Reciter.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] ?? '').toString().trim();
    final url = s('url');
    final ext = s('file_extension');
    return Reciter(
      slug: s('slug'),
      nameAr: s('name_ar'),
      nameEn: s('name_en'),
      url: url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      extension: ext.isEmpty ? 'mp3' : ext,
      isDefault: j['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name_ar': nameAr,
        'name_en': nameEn,
        'url': url,
        'file_extension': extension,
        'is_default': isDefault,
      };

  final String slug;
  final String nameAr;
  final String nameEn;

  /// The folder holding one file per ayah.
  final String url;
  final String extension;
  final bool isDefault;

  bool get isValid => slug.isNotEmpty && url.isNotEmpty && (nameAr.isNotEmpty || nameEn.isNotEmpty);

  /// The name in the app's language.
  String get name => Get.locale?.languageCode == 'ar'
      ? (nameAr.isNotEmpty ? nameAr : nameEn)
      : (nameEn.isNotEmpty ? nameEn : nameAr);

  /// The audio of [surah]:[ayah], e.g. `…/alafasy/002255.mp3`.
  String audioUrl(int surah, int ayah) =>
      '$url/${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.$extension';
}
