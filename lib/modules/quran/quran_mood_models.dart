import 'package:get/get.dart';

int _int(dynamic v) => (v as num?)?.round() ?? 0;

List<dynamic> _list(dynamic v) => v is List ? v : const [];

/// A string carried in both of the app's languages.
class LocalizedText {
  const LocalizedText(this.ar, this.en);

  factory LocalizedText.fromJson(dynamic json) => json is Map
      ? LocalizedText(
          json['ar']?.toString() ?? '',
          json['en']?.toString() ?? '',
        )
      : const LocalizedText('', '');

  final String ar;
  final String en;

  /// The reader's language, falling back to the other when it is missing.
  /// Read at build time, so switching language needs no refetch.
  String get text {
    final arabic = Get.locale?.languageCode == 'ar';
    final primary = arabic ? ar : en;
    return primary.isNotEmpty ? primary : (arabic ? en : ar);
  }
}

/// A surah and ayah range, and the pages it spans.
///
/// [pages] are verified on the server for the 604-page Madinah Mushaf, or
/// empty when they couldn't be — never partial.
class MoodPassage {
  const MoodPassage({
    required this.surahNumber,
    required this.surahName,
    required this.ayahStart,
    required this.ayahEnd,
    required this.pages,
    required this.isCompleteSurah,
  });

  factory MoodPassage.fromJson(Map<String, dynamic> json) => MoodPassage(
    surahNumber: _int(json['surah_number']),
    surahName: LocalizedText.fromJson(json['surah_name']),
    ayahStart: _int(json['ayah_start']),
    ayahEnd: _int(json['ayah_end']),
    pages: _list(json['pages']).map(_int).where((p) => p > 0).toList(),
    isCompleteSurah: json['is_complete_surah'] == true,
  );

  final int surahNumber;
  final LocalizedText surahName;
  final int ayahStart;
  final int ayahEnd;
  final List<int> pages;
  final bool isCompleteSurah;
}

/// A feeling or life situation and the passages suggested for it.
///
/// Mirrors the backend's resources/schemas/quran_category.schema.json (id,
/// section_id, title, relevance, pages, passages, source_urls) — the shape of
/// both the questionnaire's categories and a "find passages by feeling" result.
class MoodCategory {
  const MoodCategory({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.relevance,
    required this.pages,
    required this.passages,
    required this.sourceUrls,
  });

  factory MoodCategory.fromJson(Map<String, dynamic> json) => MoodCategory(
    id: json['id']?.toString() ?? '',
    sectionId: json['section_id']?.toString() ?? '',
    title: LocalizedText.fromJson(json['title']),
    relevance: LocalizedText.fromJson(json['relevance']),
    pages: _list(json['pages']).map(_int).where((p) => p > 0).toList(),
    passages: _list(json['passages'])
        .whereType<Map>()
        .map((p) => MoodPassage.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
    sourceUrls: _list(json['source_urls']).whereType<String>().toList(),
  );

  final String id;
  final String sectionId;
  final LocalizedText title;
  final LocalizedText relevance;
  final List<int> pages;
  final List<MoodPassage> passages;
  final List<String> sourceUrls;
}

/// A broad area of life — the answer to the first question.
class MoodSection {
  const MoodSection({
    required this.id,
    required this.title,
    required this.categories,
  });

  factory MoodSection.fromJson(Map<String, dynamic> json) => MoodSection(
    id: json['id']?.toString() ?? '',
    title: LocalizedText.fromJson(json['title']),
    categories: _list(json['categories'])
        .whereType<Map>()
        .map((c) => MoodCategory.fromJson(Map<String, dynamic>.from(c)))
        // An answer with nothing behind it would be a dead end.
        .where((c) => c.passages.isNotEmpty)
        .toList(),
  );

  final String id;
  final LocalizedText title;
  final List<MoodCategory> categories;
}
