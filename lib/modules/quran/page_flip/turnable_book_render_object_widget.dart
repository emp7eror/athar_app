import 'package:flutter/widgets.dart';

import 'flip_settings.dart';
import 'turnable_page.dart';
import 'page_flip.dart';
import 'page_host.dart';
import 'render_turnable_book.dart';

class TurnableBookRenderObjectWidget extends MultiChildRenderObjectWidget {
  final int pageCount;
  final PageWidgetBuilder builder;
  final FlipSettings settings;
  final PageFlip pageFlip;

  TurnableBookRenderObjectWidget({
    super.key,
    required this.pageCount,
    required this.builder,
    required this.settings,
    required this.pageFlip,
  }) : super(
         children: List.generate(
           pageCount,
           (i) => PageHost(
             index: i,
             child: builder(WidgetsBinding.instance.rootElement!, i),
           ),
         ),
       );

  @override
  RenderTurnableBook createRenderObject(BuildContext context) {
    final render = RenderTurnableBook(settings, pageFlip);
    return render;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTurnableBook renderObject,
  ) {
    renderObject.updateSettings(settings);
  }
}
