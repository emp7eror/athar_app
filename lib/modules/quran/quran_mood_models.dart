import 'package:get/get.dart';

int _int(dynamic v) => (v as num?)?.round() ?? 0;

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
  String get text {
    final arabic = Get.locale?.languageCode == 'ar';
    final primary = arabic ? ar : en;
    return primary.isNotEmpty ? primary : (arabic ? en : ar);
  }
}

/// A surah and ayah range suggested for a feeling, and the pages it spans.
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
    pages: (json['pages'] is List ? json['pages'] as List : const [])
        .map(_int)
        .where((p) => p > 0)
        .toList(),
    isCompleteSurah: json['is_complete_surah'] == true,
  );

  final int surahNumber;
  final LocalizedText surahName;
  final int ayahStart;
  final int ayahEnd;
  final List<int> pages;
  final bool isCompleteSurah;

  /// Where reading starts; the passage continues on the following pages.
  int get firstPage => pages.isEmpty ? 1 : pages.first;
}

/// A feeling or life situation — the answer to the second question.
class MoodCategory {
  const MoodCategory({
    required this.id,
    required this.title,
    required this.relevance,
    required this.passages,
  });

  factory MoodCategory.fromJson(Map<String, dynamic> json) => MoodCategory(
    id: json['id']?.toString() ?? '',
    title: LocalizedText.fromJson(json['title']),
    relevance: LocalizedText.fromJson(json['relevance']),
    passages: (json['passages'] is List ? json['passages'] as List : const [])
        .whereType<Map>()
        .map((p) => MoodPassage.fromJson(Map<String, dynamic>.from(p)))
        .where((p) => p.pages.isNotEmpty)
        .toList(),
  );

  final String id;
  final LocalizedText title;
  final LocalizedText relevance;
  final List<MoodPassage> passages;
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
    categories:
        (json['categories'] is List ? json['categories'] as List : const [])
            .whereType<Map>()
            .map((c) => MoodCategory.fromJson(Map<String, dynamic>.from(c)))
            .where((c) => c.passages.isNotEmpty)
            .toList(),
  );

  final String id;
  final LocalizedText title;
  final List<MoodCategory> categories;
}
