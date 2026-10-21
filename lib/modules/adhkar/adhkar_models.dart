import 'package:get/get.dart';

/// Adhkar & Duas content, as the app holds it — the public library and the
/// reader's own collections, both cached for offline reading.
///
/// Every item carries the key its progress is counted under: `p{id}` for a
/// public item, `u{id}` for one of the reader's own.

enum AdhkarType {
  adhkar,
  dua;

  static AdhkarType parse(Object? v) =>
      v == 'dua' ? AdhkarType.dua : AdhkarType.adhkar;
}

/// Picks the text for the app's language, falling back to the other one.
String localized(String? ar, String? en) {
  final isAr = (Get.locale?.languageCode ?? 'ar') == 'ar';
  final primary = isAr ? ar : en;
  final fallback = isAr ? en : ar;
  return (primary?.trim().isNotEmpty ?? false)
      ? primary!.trim()
      : (fallback ?? '').trim();
}

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

int? _int(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}');

class AdhkarItem {
  const AdhkarItem({
    required this.id,
    required this.key,
    required this.text,
    required this.isPersonal,
    this.occasionAr,
    this.occasionEn,
    this.target,
    this.reference,
    this.virtue,
    this.notes,
    this.categoryId,
    this.sourceItemId,
  });

  final int id;
  final String key;
  final String text;
  final bool isPersonal;

  /// When it is said («دعاء الذهاب إلى المسجد»), where the collection name
  /// does not already say it. A personal item has one, in both fields.
  final String? occasionAr;
  final String? occasionEn;

  String? get occasion {
    final o = localized(occasionAr, occasionEn);
    return o.isEmpty ? null : o;
  }

  /// Null when the item has no required repetition count.
  final int? target;
  final String? reference;
  final String? virtue;
  final String? notes;

  /// A public Dua's category.
  final int? categoryId;

  /// For a personal copy: the public item it was copied from, if still there.
  final int? sourceItemId;

  bool get hasTarget => (target ?? 0) > 0;
  bool get hasDetails => reference != null || virtue != null || notes != null;

  factory AdhkarItem.fromJson(
    Map<String, dynamic> j, {
    required bool personal,
  }) => AdhkarItem(
    id: _int(j['id']) ?? 0,
    key: _str(j['key']) ?? '${personal ? 'u' : 'p'}${j['id']}',
    text: _str(j['text']) ?? '',
    isPersonal: personal,
    occasionAr: _str(personal ? j['occasion'] : j['occasion_ar']),
    occasionEn: _str(personal ? j['occasion'] : j['occasion_en']),
    target: _int(j['target_count']),
    reference: _str(j['reference']),
    virtue: _str(j['virtue']),
    notes: _str(j['notes']),
    categoryId: _int(j['category_id']),
    sourceItemId: _int(j['source_item_id']),
  );
}

/// Where a collection comes from. Public ones are read-only.
enum AdhkarSource { publicCollection, publicCategory, personal }

class AdhkarCollection {
  const AdhkarCollection({
    required this.id,
    required this.source,
    required this.type,
    required this.nameAr,
    required this.nameEn,
    required this.items,
    this.descriptionAr,
    this.descriptionEn,
    this.slug,
    this.categoryId,
    this.icon,
  });

  final int id;
  final AdhkarSource source;

  /// The icon the reader picked (a key of `adhkarIcons`); personal only.
  final String? icon;
  final AdhkarType type;

  /// A personal collection's name is the same in both fields.
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;

  /// `morning` / `evening` for the built-in public collections.
  final String? slug;

  /// A Dua category — the category itself, or the one a personal Dua
  /// collection is filed under.
  final int? categoryId;
  final List<AdhkarItem> items;

  bool get isPersonal => source == AdhkarSource.personal;

  /// Stable across reloads; used for routes and to find the collection again.
  String get uid => switch (source) {
    AdhkarSource.publicCollection => 'pc$id',
    AdhkarSource.publicCategory => 'cat$id',
    AdhkarSource.personal => 'uc$id',
  };

  String get name => localized(nameAr, nameEn);
  String? get description {
    final d = localized(descriptionAr, descriptionEn);
    return d.isEmpty ? null : d;
  }

  AdhkarCollection copyWith({List<AdhkarItem>? items}) => AdhkarCollection(
    id: id,
    source: source,
    type: type,
    nameAr: nameAr,
    nameEn: nameEn,
    descriptionAr: descriptionAr,
    descriptionEn: descriptionEn,
    slug: slug,
    categoryId: categoryId,
    icon: icon,
    items: items ?? this.items,
  );

  static List<AdhkarItem> _items(Object? list, {required bool personal}) => [
    if (list is List)
      for (final e in list)
        if (e is Map)
          AdhkarItem.fromJson(Map<String, dynamic>.from(e), personal: personal),
  ];

  factory AdhkarCollection.publicFromJson(Map<String, dynamic> j) =>
      AdhkarCollection(
        id: _int(j['id']) ?? 0,
        source: AdhkarSource.publicCollection,
        type: AdhkarType.adhkar,
        nameAr: _str(j['name_ar']) ?? '',
        nameEn: _str(j['name_en']) ?? '',
        descriptionAr: _str(j['description_ar']),
        descriptionEn: _str(j['description_en']),
        slug: _str(j['slug']),
        items: _items(j['items'], personal: false),
      );

  /// A public Dua category, read like a collection of its Duas.
  factory AdhkarCollection.categoryFromJson(Map<String, dynamic> j) =>
      AdhkarCollection(
        id: _int(j['id']) ?? 0,
        slug: _str(j['slug']),
        source: AdhkarSource.publicCategory,
        type: AdhkarType.dua,
        nameAr: _str(j['name_ar']) ?? '',
        nameEn: _str(j['name_en']) ?? '',
        descriptionAr: _str(j['description_ar']),
        descriptionEn: _str(j['description_en']),
        categoryId: _int(j['id']),
        items: _items(j['duas'], personal: false),
      );

  factory AdhkarCollection.personalFromJson(Map<String, dynamic> j) {
    final name = _str(j['name']) ?? '';
    final description = _str(j['description']);
    return AdhkarCollection(
      id: _int(j['id']) ?? 0,
      source: AdhkarSource.personal,
      type: AdhkarType.parse(j['type']),
      nameAr: name,
      nameEn: name,
      descriptionAr: description,
      descriptionEn: description,
      categoryId: _int(j['category_id']),
      icon: _str(j['icon']),
      items: _items(j['items'], personal: true),
    );
  }
}

/// A Dua category, for the filter chips.
class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final int id;
  final String nameAr;
  final String nameEn;

  String get name => localized(nameAr, nameEn);
}

/// Text search over Adhkar and Duas, insensitive to diacritics, tatweel and
/// the common letter variants (أ إ آ ٱ → ا, ى → ي, ة → ه, ؤ → و, ئ → ي).
abstract final class AdhkarSearch {
  static final _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static final _space = RegExp(r'\s+');

  static String normalize(String input) {
    var s = input.replaceAll(_marks, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    return s.toLowerCase().replaceAll(_space, ' ').trim();
  }

  /// Every word of [query] appears in [text] (after normalizing both).
  static bool matches(String text, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final haystack = normalize(text);
    for (final word in normalizedQuery.split(' ')) {
      if (!haystack.contains(word)) return false;
    }
    return true;
  }
}
