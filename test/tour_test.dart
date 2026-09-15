import 'package:athar/core/theme/app_theme.dart';
import 'package:athar/core/tour/tour_models.dart';
import 'package:athar/core/tour/tour_service.dart';
import 'package:athar/core/tour/tour_widgets.dart';
import 'package:athar/data/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// In-memory stand-in for StorageProvider (GetStorage needs a platform).
class _FakeStorage extends GetxService implements StorageProvider {
  final done = <String, Set<String>>{};

  @override
  bool get isLoggedIn => true;

  @override
  Map<String, dynamic>? get cachedUser => {'id': 7};

  @override
  Set<String> completedTours(String userKey) => {...?done[userKey]};

  @override
  void markTourCompleted(String userKey, String pageId) =>
      (done[userKey] ??= <String>{}).add(pageId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _demo = PageTour(
  pageId: 'demo',
  steps: [
    TourStep(target: 'a', titleKey: 'Step A', bodyKey: 'about a'),
    TourStep(target: 'b', titleKey: 'Step B', bodyKey: 'about b'),
    TourStep(target: 'missing', titleKey: 'Step M', bodyKey: 'never shown'),
  ],
);

Widget _app() => MaterialApp(
      // Plain theme + the brand palette (AppTheme itself pulls Google Fonts).
      theme: ThemeData(extensions: [AtharPalette.light]),
      home: Scaffold(
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
          children: const [
            Row(children: [Expanded(child: Text('Page')), TourHelpButton(pageId: 'demo')]),
            TourTarget(id: 'a', child: SizedBox(height: 80, child: Text('A'))),
            SizedBox(height: 1500),
            TourTarget(id: 'b', child: SizedBox(height: 80, child: Text('B'))),
            SizedBox(height: 400),
          ],
        ),
      ),
    );

Future<void> _advance(WidgetTester tester, [int ms = 2000]) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeStorage storage;
  late TourService service;

  setUp(() {
    storage = Get.put<StorageProvider>(_FakeStorage()) as _FakeStorage;
    service = Get.put(TourService([_demo]));
  });

  tearDown(Get.reset);

  testWidgets('first visit: shows steps, scrolls to targets, skips missing ones, saves on Done',
      (tester) async {
    await tester.pumpWidget(_app());
    final page = tester.element(find.text('A'));

    service.maybeStart('demo', page);
    await _advance(tester);

    expect(find.text('Step A'), findsOneWidget);
    expect(find.text('tour_skip'), findsOneWidget);
    expect(service.running.value, 'demo');

    await tester.tap(find.text('tour_next'));
    await _advance(tester);

    // B was 1.5k px down: it must have been scrolled on screen.
    expect(find.text('Step B'), findsOneWidget);
    final b = tester.getRect(find.text('B'));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(b.top >= screen.top && b.bottom <= screen.bottom, isTrue,
        reason: 'B $b should be scrolled inside $screen');

    // The third step's target doesn't exist → Next finishes the tour.
    await tester.tap(find.text('tour_next'));
    await _advance(tester, 4000);

    expect(find.text('Step B'), findsNothing);
    expect(find.text('Step M'), findsNothing);
    expect(service.running.value, isNull);
    expect(storage.completedTours('7'), contains('demo'));

    // Never auto-starts again.
    service.maybeStart('demo', page);
    await _advance(tester);
    expect(find.text('Step A'), findsNothing);
  });

  testWidgets('Skip saves; Help replays a completed tour; back button closes it',
      (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await _advance(tester);
    expect(find.text('Step A'), findsOneWidget);

    await tester.tap(find.text('tour_skip'));
    await _advance(tester);
    expect(find.text('Step A'), findsNothing);
    expect(storage.completedTours('7'), contains('demo'));

    // Replay works even though it's completed.
    await tester.drag(find.byType(ListView), const Offset(0, 3000)); // back to top
    await _advance(tester, 500);
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await _advance(tester);
    expect(find.text('Step A'), findsOneWidget);

    // Android back = skip, and the page underneath stays put.
    await tester.binding.handlePopRoute();
    await _advance(tester);
    expect(find.text('Step A'), findsNothing);
    expect(find.text('Page'), findsOneWidget);
    expect(service.running.value, isNull);
  });

  testWidgets('a tab tour does not start while its tab is hidden, and is not saved',
      (tester) async {
    // GetxServices ignore a plain delete.
    Get.delete<TourService>(force: true);
    service = Get.put(TourService([
      PageTour(pageId: 'demo', isTab: true, steps: _demo.steps),
    ]));
    await tester.pumpWidget(_app());

    service.activeTab.value = 'other';
    service.maybeStart('demo', tester.element(find.text('A')));
    await _advance(tester);

    expect(find.text('Step A'), findsNothing);
    expect(storage.completedTours('7'), isNot(contains('demo')));
  });

  testWidgets('8-step coach mark fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Get.delete<TourService>(force: true);
    service = Get.put(TourService([
      PageTour(
        pageId: 'demo',
        steps: [
          for (var i = 0; i < 8; i++)
            TourStep(target: 'a', titleKey: 'Step $i', bodyKey: 'A fairly long description to wrap.'),
        ],
      ),
    ]));
    await tester.pumpWidget(_app());

    service.maybeStart('demo', tester.element(find.text('A')));
    await _advance(tester);
    expect(find.text('Step 0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Walk to the last step: Skip disappears, Done appears, still no overflow.
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('tour_next'));
      await _advance(tester, 1000);
    }
    expect(find.text('Step 7'), findsOneWidget);
    expect(find.text('tour_skip'), findsNothing);
    expect(find.text('tour_done'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('tour_done'));
    await _advance(tester);
    expect(storage.completedTours('7'), contains('demo'));
  });

  testWidgets('no Help button for a page without a tour', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: [AtharPalette.light]),
      home: const Scaffold(body: TourHelpButton(pageId: 'nothing-here')),
    ));
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
  });
}
