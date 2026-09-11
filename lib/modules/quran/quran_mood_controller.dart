import 'dart:async';

import 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'quran_mood_models.dart';

/// "Read by how you feel": one way from a feeling to passages.
///
/// Pick what's closest from the list (two questions), or describe it in your
/// own words and let the server find or prepare a matching category. Both
/// routes end on the same results.
///
/// The list and every result carry both languages, so switching the app's
/// language re-renders them without asking again. What someone types is only
/// ever sent in the request itself — never reported, stored or logged here.
class QuranMoodController extends GetxController {
  final _api = Get.find<ApiProvider>();

  // ── The list ──────────────────────────────────────────────────────────────

  final loading = true.obs;
  final failed = false.obs;

  final sections = <MoodSection>[].obs;

  /// How to read the results — a passage is a suggestion for reflection in its
  /// context, not a promise of an outcome — shown beneath them.
  final guidance = <LocalizedText>[].obs;

  final section = Rxn<MoodSection>();
  final category = Rxn<MoodCategory>();

  /// For a category picked from the list: passages the AI suggested for its
  /// topic, shown as suggestions while an admin reviews them.
  final suggestedLoading = false.obs;
  final suggested = Rxn<MoodCategory>();
  final suggestedFailed = false.obs;
  CancelToken? _suggestCancel;

  // ── In your own words ─────────────────────────────────────────────────────

  /// Matches the server's limit.
  static const maxChars = 1000;

  final input = TextEditingController();
  final focus = FocusNode();
  final inputError = RxnString();

  final searching = false.obs;
  final searchError = RxnString();
  final found = Rxn<MoodCategory>();

  /// The server led the result with urgent safety guidance.
  final urgent = false.obs;

  /// The result was written for this feeling rather than taken from a saved
  /// category, so its passages are already the personal ones.
  final foundIsPersonal = false.obs;

  /// Passages suited to what was written, beyond the general category shown —
  /// looked for while the general ones are already on screen.
  final personalLoading = false.obs;
  final personal = Rxn<MoodCategory>();
  final personalFailed = false.obs;

  CancelToken? _cancel;

  // ── Where the screen is ───────────────────────────────────────────────────

  static const stepCount = 3;

  /// The results step is about a written feeling: in flight, failed or found.
  bool get showingSearch =>
      searching.value || searchError.value != null || found.value != null;

  /// 0: what weighs on the heart; 1: which feeling; 2: the passages.
  int get step {
    if (showingSearch || category.value != null) return 2;
    return section.value != null ? 1 : 0;
  }

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

      sections.assignAll(_parseSections(res));

      final notes = res['notes'];
      guidance.assignAll([
        if (notes is Map) ...[
          ..._texts(notes['interpretation']),
          ..._texts(notes['usage']),
        ],
      ]);
    } catch (e, stack) {
      ErrorReporter.report(e, stack);
      failed.value = true;
    } finally {
      loading.value = false;
    }
  }

  void chooseSection(MoodSection s) {
    _clearSuggested();
    category.value = null;
    section.value = s;
  }

  void chooseCategory(MoodCategory c) {
    category.value = c;
    unawaited(_refreshPicked(c.id));
    unawaited(_loadSuggested(c));
  }

  /// Re-reads the list quietly — no loading state — so a category picked
  /// from it shows passages added since the screen opened, such as a
  /// suggestion an admin has just approved. The list on screen stays if this
  /// fails.
  Future<void> _refreshPicked(String pickedId) async {
    try {
      final fresh = _parseSections(await _api.quranMoods());
      if (fresh.isEmpty) return;

      sections.assignAll(fresh);
      if (category.value?.id != pickedId) return;

      for (final s in fresh) {
        for (final c in s.categories) {
          if (c.id != pickedId) continue;
          if (section.value?.id == s.id) section.value = s;
          category.value = c;
          return;
        }
      }
    } catch (_) {
      // Keep what is already shown.
    }
  }

  static List<MoodSection> _parseSections(Map<String, dynamic> res) =>
      (res['sections'] is List ? res['sections'] as List : const [])
          .whereType<Map>()
          .map((s) => MoodSection.fromJson(Map<String, dynamic>.from(s)))
          // A section with nothing to pick would be a dead end.
          .where((s) => s.categories.isNotEmpty)
          .toList();

  /// Asks for passages suggested for [picked]'s topic. Only the category is
  /// sent — nothing the reader typed.
  Future<void> _loadSuggested(MoodCategory picked) async {
    _clearSuggested();
    final cancel = _suggestCancel = CancelToken();
    suggestedLoading.value = true;

    try {
      final res = await _api.quranMoodSuggestions(
        picked.id,
        cancelToken: cancel,
      );
      if (!identical(_suggestCancel, cancel)) return;
      suggested.value = MoodCategory.fromJson(res);
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && identical(_suggestCancel, cancel)) {
        suggestedFailed.value = true;
      }
    } catch (_) {
      if (identical(_suggestCancel, cancel)) suggestedFailed.value = true;
    } finally {
      if (identical(_suggestCancel, cancel)) suggestedLoading.value = false;
    }
  }

  void _clearSuggested() {
    _suggestCancel?.cancel();
    _suggestCancel = null;
    suggestedLoading.value = false;
    suggested.value = null;
    suggestedFailed.value = false;
  }

  /// One step back. False when already on the first step — the screen itself
  /// should close then.
  bool back() {
    if (showingSearch) {
      _clearSearch();
      return true;
    }
    if (category.value != null) {
      _clearSuggested();
      category.value = null;
      return true;
    }
    if (section.value != null) {
      section.value = null;
      return true;
    }
    return false;
  }

  void useExample(String text) {
    input.text = text;
    input.selection = TextSelection.collapsed(offset: text.length);
    inputError.value = null;
    focus.requestFocus();
  }

  Future<void> submitFeeling() async {
    final feeling = input.text.trim();
    if (feeling.isEmpty) {
      inputError.value = 'quran_feel_empty_input'.tr;
      focus.requestFocus();
      return;
    }

    focus.unfocus();
    _clearSearch();
    section.value = null;
    category.value = null;

    final cancel = _cancel = CancelToken();
    searching.value = true;

    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';

    try {
      final res = await _api.quranFeeling(feeling, locale, cancelToken: cancel);
      final result = MoodCategory.fromJson(res.category);

      found.value = result;
      foundIsPersonal.value = res.generated;
      urgent.value = res.urgent;

      if (res.personal) {
        unawaited(_loadPersonal(feeling, result, locale, cancel));
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) searchError.value = _messageFor(e);
    } on ApiException catch (e) {
      searchError.value = e.message.isNotEmpty
          ? e.message
          : 'quran_feel_failed'.tr;
    } catch (e, stack) {
      // Only unexpected parsing problems reach here; they carry no input.
      ErrorReporter.report(e, stack);
      searchError.value = 'quran_feel_failed'.tr;
    } finally {
      if (identical(_cancel, cancel)) searching.value = false;
    }
  }

  /// Asks for passages suited to what was written, while the general passages
  /// of [general] are already on screen. The text is sent again for this and
  /// isn't kept here afterwards.
  Future<void> _loadPersonal(
    String feeling,
    MoodCategory general,
    String locale,
    CancelToken cancel,
  ) async {
    personalLoading.value = true;
    personal.value = null;
    personalFailed.value = false;

    try {
      final res = await _api.quranFeelingPersonal(
        feeling,
        general.id,
        locale,
        cancelToken: cancel,
      );
      if (!identical(_cancel, cancel)) return;
      personal.value = MoodCategory.fromJson(res);
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && identical(_cancel, cancel)) {
        personalFailed.value = true;
      }
    } catch (_) {
      if (identical(_cancel, cancel)) personalFailed.value = true;
    } finally {
      if (identical(_cancel, cancel)) personalLoading.value = false;
    }
  }

  /// Stops the request and goes back to writing.
  void cancelSearch() => _clearSearch();

  void _clearSearch() {
    _cancel?.cancel();
    _cancel = null;
    searching.value = false;
    searchError.value = null;
    found.value = null;
    urgent.value = false;
    foundIsPersonal.value = false;
    personalLoading.value = false;
    personal.value = null;
    personalFailed.value = false;
  }

  String _messageFor(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final message = data['message'] as String;
      if (message.isNotEmpty) return message;
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => 'quran_feel_network'.tr,
      _ => 'quran_feel_failed'.tr,
    };
  }

  static Iterable<LocalizedText> _texts(dynamic list) => list is List
      ? list.map(LocalizedText.fromJson).where((t) => t.text.isNotEmpty)
      : const <LocalizedText>[];

  @override
  void onClose() {
    _cancel?.cancel();
    _suggestCancel?.cancel();
    input.dispose();
    focus.dispose();
    super.onClose();
  }
}
