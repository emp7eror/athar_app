import 'dart:async';

import 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'quran_mood_models.dart';

enum FeelingSuggestState { idle, sending, sent, failed, closed }

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

  final suggestState = FeelingSuggestState.idle.obs;
  final suggestMessage = RxnString();
  final canSuggest = false.obs;
  String? _suggestionToken;

  /// A catalog result is shown at once while more passages are looked for;
  /// what turns up is added to the category for everyone.
  final loadingMore = false.obs;
  final moreAdded = 0.obs;
  final moreFailed = false.obs;

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
    } catch (e, stack) {
      ErrorReporter.report(e, stack);
      failed.value = true;
    } finally {
      loading.value = false;
    }
  }

  void chooseSection(MoodSection s) {
    category.value = null;
    section.value = s;
  }

  void chooseCategory(MoodCategory c) => category.value = c;

  /// One step back. False when already on the first step — the screen itself
  /// should close then.
  bool back() {
    if (showingSearch) {
      _clearSearch();
      return true;
    }
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

    try {
      final res = await _api.quranFeeling(
        feeling,
        Get.locale?.languageCode == 'ar' ? 'ar' : 'en',
        cancelToken: cancel,
      );
      final result = MoodCategory.fromJson(res.category);

      found.value = result;
      urgent.value = res.urgent;
      _suggestionToken = res.suggestionToken;
      canSuggest.value =
          !res.urgent &&
          res.suggestionToken != null &&
          result.passages.isNotEmpty;

      if (res.more) unawaited(_loadMore(result, cancel));
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

  /// Asks for more passages for the catalog result already on screen, and
  /// appends them when they arrive. The title and explanation stay as shown —
  /// including any urgent guidance that leads them.
  Future<void> _loadMore(MoodCategory shown, CancelToken cancel) async {
    loadingMore.value = true;
    moreAdded.value = 0;
    moreFailed.value = false;

    try {
      final res = await _api.quranFeelingMore(shown.id, cancelToken: cancel);
      if (!identical(_cancel, cancel)) return;

      final updated = MoodCategory.fromJson(res);
      final added = updated.passages.length - shown.passages.length;
      if (added > 0) {
        found.value = MoodCategory(
          id: shown.id,
          sectionId: shown.sectionId,
          title: shown.title,
          relevance: shown.relevance,
          pages: updated.pages,
          passages: updated.passages,
          sourceUrls: updated.sourceUrls,
        );
        moreAdded.value = added;
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && identical(_cancel, cancel)) {
        moreFailed.value = true;
      }
    } catch (_) {
      if (identical(_cancel, cancel)) moreFailed.value = true;
    } finally {
      if (identical(_cancel, cancel)) loadingMore.value = false;
    }
  }

  /// Stops the request and goes back to writing.
  void cancelSearch() => _clearSearch();

  /// Offers the result for the shared list, at the person's own choice.
  Future<void> suggest() async {
    final token = _suggestionToken;
    if (token == null || suggestState.value == FeelingSuggestState.sending) {
      return;
    }

    suggestState.value = FeelingSuggestState.sending;
    suggestMessage.value = null;

    try {
      final res = await _api.quranFeelingSuggest(token);
      _suggestionToken = null;
      suggestMessage.value = res['message']?.toString();
      suggestState.value = FeelingSuggestState.sent;
    } on ApiException catch (e) {
      suggestMessage.value = e.message;
      if (e.status == 429) {
        suggestState.value = FeelingSuggestState.failed;
      } else {
        // Expired or no longer valid: sending it again can't help.
        _suggestionToken = null;
        suggestState.value = FeelingSuggestState.closed;
      }
    } catch (_) {
      suggestState.value = FeelingSuggestState.failed;
    }
  }

  void _clearSearch() {
    _cancel?.cancel();
    _cancel = null;
    searching.value = false;
    searchError.value = null;
    found.value = null;
    urgent.value = false;
    canSuggest.value = false;
    loadingMore.value = false;
    moreAdded.value = 0;
    moreFailed.value = false;
    _suggestionToken = null;
    suggestState.value = FeelingSuggestState.idle;
    suggestMessage.value = null;
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
    input.dispose();
    focus.dispose();
    super.onClose();
  }
}
