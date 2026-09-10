import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'quran_mood_models.dart';

/// "Read by how you feel" — the questionnaire's data, and where the reader is
/// in it. The server owns the list; this only walks it.
class QuranMoodController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final loading = true.obs;
  final failed = false.obs;

  final sections = <MoodSection>[].obs;

  /// How to read the results — a passage is a suggestion for reflection in its
  /// context, not a promise of an outcome — shown beneath them.
  final guidance = <LocalizedText>[].obs;

  final section = Rxn<MoodSection>();
  final category = Rxn<MoodCategory>();

  static const stepCount = 3;

  /// 0: what weighs on the heart; 1: which feeling; 2: the passages.
  int get step => category.value != null ? 2 : (section.value != null ? 1 : 0);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    try {
      final res = await _api.quranMoods();

      sections.assignAll(
        (res['sections'] is List ? res['sections'] as List : const [])
            .whereType<Map>()
            .map((s) => MoodSection.fromJson(Map<String, dynamic>.from(s)))
            // A section with nothing to pick would be a dead end.
            .where((s) => s.categories.isNotEmpty),
      );

      final notes = res['notes'];
      guidance.assignAll([
        if (notes is Map) ...[
          ..._texts(notes['interpretation']),
          ..._texts(notes['usage']),
        ],
      ]);

      loading.value = false;
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      failed.value = true;
      loading.value = false;
    }
  }

  void chooseSection(MoodSection s) {
    category.value = null;
    section.value = s;
  }

  void chooseCategory(MoodCategory c) => category.value = c;

  /// One step back through the questionnaire. False when already on the first
  /// question — the screen itself should close then.
  bool back() {
    if (category.value != null) {
      category.value = null;
      return true;
    }
    if (section.value != null) {
      section.value = null;
      return true;
    }
    return false;
  }

  static Iterable<LocalizedText> _texts(dynamic list) => list is List
      ? list.map(LocalizedText.fromJson).where((t) => t.text.isNotEmpty)
      : const <LocalizedText>[];
}
