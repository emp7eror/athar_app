/// A bilingual (ar/en) piece of text — the API sends both languages for every
/// field so the client just picks based on its own current locale, the same
/// pattern already used for level titles etc.
class BilingualText {
  final String ar, en;
  const BilingualText({required this.ar, required this.en});

  factory BilingualText.fromJson(Map<String, dynamic> j) =>
      BilingualText(ar: j['ar'] ?? '', en: j['en'] ?? '');

  String of(bool isAr) => isAr ? ar : en;
}

/// One numbered section of a legal document — a heading plus any mix of
/// paragraphs, a bullet list, a highlighted note, and/or a contact email.
class LegalSection {
  final BilingualText heading;
  final List<BilingualText> paragraphs;
  final List<BilingualText> list;
  final BilingualText? note;
  final String? email;

  const LegalSection({
    required this.heading,
    this.paragraphs = const [],
    this.list = const [],
    this.note,
    this.email,
  });

  factory LegalSection.fromJson(Map<String, dynamic> j) => LegalSection(
        heading: BilingualText.fromJson(j['heading'] ?? {}),
        paragraphs: (j['paragraphs'] as List? ?? [])
            .map((e) => BilingualText.fromJson(e as Map<String, dynamic>))
            .toList(),
        list: (j['list'] as List? ?? [])
            .map((e) => BilingualText.fromJson(e as Map<String, dynamic>))
            .toList(),
        note: j['note'] is Map ? BilingualText.fromJson(j['note']) : null,
        email: j['email'],
      );
}

/// A full legal document (Terms or Privacy) from `GET /legal/terms|privacy`.
class LegalDocument {
  final BilingualText title;
  final String updatedAt;
  final BilingualText intro;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.title,
    required this.updatedAt,
    required this.intro,
    required this.sections,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> j) => LegalDocument(
        title: BilingualText.fromJson(j['title'] ?? {}),
        updatedAt: j['updated_at'] ?? '',
        intro: BilingualText.fromJson(j['intro'] ?? {}),
        sections: (j['sections'] as List? ?? [])
            .map((e) => LegalSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
