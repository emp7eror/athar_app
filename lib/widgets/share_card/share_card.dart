import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/athar_theme_presets.dart';
import '../../core/design/athar_typography.dart';

/// What a share card says. Shared by the ayah card and the Adhkar & Duas card.
class ShareCardContent {
  const ShareCardContent({
    required this.text,
    this.kicker,
    this.title,
    this.badge,
    this.footer,
    this.note,
    this.quranic = false,
  });

  /// The text itself — an ayah, a dhikr, a dua.
  final String text;

  /// The small label at the top: a surah, a collection, a category.
  final String? kicker;

  /// A heading over the text: when it is said («دعاء الذهاب إلى المسجد»).
  final String? title;

  /// A short highlight under the text, e.g. «يُقال ثلاث مرات».
  final String? badge;

  /// The source line at the bottom: the ayah's place, a hadith reference.
  final String? footer;

  /// Optional extra paragraph — a virtue — shown only when asked for.
  final String? note;

  /// Quran text: the Mushaf typeface sized for it.
  final bool quranic;
}

enum ShareCardDesign {
  classic('share_design_classic'),
  arch('share_design_arch'),
  pattern('share_design_pattern'),
  minimal('share_design_minimal');

  const ShareCardDesign(this.labelKey);
  final String labelKey;

  static ShareCardDesign byName(String? name) =>
      values.firstWhere((d) => d.name == name, orElse: () => classic);
}

/// Story (9:16, for statuses) or post (4:5, for feeds). Both grow taller for
/// long texts rather than shrinking them past legibility.
enum ShareCardFormat {
  story(640, 'share_format_story'),
  post(450, 'share_format_post');

  const ShareCardFormat(this.minHeight, this.labelKey);
  final double minHeight;
  final String labelKey;

  static ShareCardFormat byName(String? name) =>
      values.firstWhere((f) => f.name == name, orElse: () => story);
}

/// The card's colours, taken from the theme the reader chose in the app, plus
/// Athar's gold — so a shared card looks like the app it came from.
class ShareCardPalette {
  const ShareCardPalette._({
    required this.deep,
    required this.deeper,
    required this.vivid,
    required this.glow,
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkMuted,
  });

  factory ShareCardPalette.of(AtharThemePreset p) {
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final ink = mix(p.brand, Colors.black, 0.45);
    return ShareCardPalette._(
      deep: mix(p.brand, p.vivid, 0.38),
      deeper: mix(p.brand, Colors.black, 0.35),
      vivid: p.vivid,
      glow: p.vividOnDark,
      paper: mix(p.lightBackground, Colors.white, 0.35),
      paperDeep: p.lightSurface,
      ink: ink,
      inkMuted: mix(ink, p.lightBackground, 0.42),
    );
  }

  static const gold = Color(0xFFC8A95B);
  static const goldSoft = Color(0xFFE3CF98);

  final Color deep;
  final Color deeper;
  final Color vivid;
  final Color glow;
  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkMuted;
}

/// A shareable card, 360 logical pixels wide (captured at 3x: 1080px).
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.content,
    required this.design,
    required this.palette,
    this.format = ShareCardFormat.story,
    this.showNote = false,
  });

  final ShareCardContent content;
  final ShareCardDesign design;
  final ShareCardPalette palette;
  final ShareCardFormat format;
  final bool showNote;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final card = switch (design) {
      ShareCardDesign.classic => _Classic(this),
      ShareCardDesign.arch => _Arch(this),
      ShareCardDesign.pattern => _Pattern(this),
      ShareCardDesign.minimal => _Minimal(this),
    };

    // Arabic content, always right to left; no inherited text decoration.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: AtharFonts.arabic,
          decoration: TextDecoration.none,
        ),
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: format.minHeight),
            child: IntrinsicHeight(child: card),
          ),
        ),
      ),
    );
  }

  /// The text's size, by its length and the room the format gives it.
  double get textSize {
    final n = content.text.length;
    final post = format == ShareCardFormat.post;
    final base = content.quranic ? 28.0 : 25.0;
    final double size;
    if (n < 90) {
      size = base;
    } else if (n < 200) {
      size = base - 3;
    } else if (n < 400) {
      size = base - 6;
    } else if (n < 800) {
      size = base - 9;
    } else if (n < 1400) {
      size = base - 11;
    } else {
      size = base - 13;
    }
    return post ? size - 2 : size;
  }

  TextStyle bodyStyle(Color color) => AtharTypography.quran(
    size: textSize,
    color: color,
    height: content.quranic ? 2.1 : 1.95,
  ).copyWith(decoration: TextDecoration.none);
}

// ── Shared pieces ────────────────────────────────────────────────────────

/// Athar's mark and name, for the corner of every card.
class _Brand extends StatelessWidget {
  const _Brand({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', width: 20, height: 20),
        const SizedBox(width: 6),
        Text(
          'أثر',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A thin rule with a small diamond at its centre.
class _OrnamentRule extends StatelessWidget {
  const _OrnamentRule({required this.color, this.width = 140});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 12,
      child: CustomPaint(painter: _RulePainter(color)),
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final c = size.width / 2;
    final line = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(c - 10, y), line);
    canvas.drawLine(Offset(c + 10, y), Offset(size.width, y), line);
    final d = Path()
      ..moveTo(c, y - 5)
      ..lineTo(c + 5, y)
      ..lineTo(c, y + 5)
      ..lineTo(c - 5, y)
      ..close();
    canvas.drawPath(d, Paint()..color = color);
    canvas.drawCircle(Offset(c - 14, y), 1.6, Paint()..color = color);
    canvas.drawCircle(Offset(c + 14, y), 1.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.color != color;
}

/// An eight-pointed star — two overlapping squares — the classic motif.
Path _star(Offset c, double r) {
  final path = Path();
  for (var k = 0; k < 2; k++) {
    final a0 = k * math.pi / 4;
    for (var i = 0; i < 4; i++) {
      final a = a0 + i * math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
  }
  return path;
}

/// A tiled lattice of eight-pointed stars and the diamonds between them.
class _StarLatticePainter extends CustomPainter {
  _StarLatticePainter(this.color, {this.cell = 46});
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r = cell * 0.42;
    for (var y = -cell; y < size.height + cell; y += cell) {
      for (var x = -cell; x < size.width + cell; x += cell) {
        canvas.drawPath(_star(Offset(x, y), r), stroke);
        canvas.drawCircle(
          Offset(x + cell / 2, y + cell / 2),
          cell * 0.08,
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarLatticePainter old) =>
      old.color != color || old.cell != cell;
}

/// A small star in each corner of a frame.
class _CornerStarsPainter extends CustomPainter {
  _CornerStarsPainter(this.color);
  final Color color;
  static const inset = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    for (final c in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawPath(_star(c, 6), fill);
    }
  }

  @override
  bool shouldRepaint(_CornerStarsPainter old) => old.color != color;
}

/// A pointed (mihrab) arch over a rectangle.
class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper();

  @override
  Path getClip(Size s) => archPath(s);

  static Path archPath(Size s) {
    final shoulder = math.min(s.width * 0.62, s.height * 0.32);
    return Path()
      ..moveTo(0, s.height)
      ..lineTo(0, shoulder)
      ..cubicTo(
        0,
        shoulder * 0.42,
        s.width * 0.32,
        shoulder * 0.12,
        s.width / 2,
        0,
      )
      ..cubicTo(
        s.width * 0.68,
        shoulder * 0.12,
        s.width,
        shoulder * 0.42,
        s.width,
        shoulder,
      )
      ..lineTo(s.width, s.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArchStrokePainter extends CustomPainter {
  _ArchStrokePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _ArchClipper.archPath(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_ArchStrokePainter old) => old.color != color;
}

/// The pill under the text: «يُقال ثلاث مرات».
class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Title, text, badge and note, centred — the body every design shares.
class _Body extends StatelessWidget {
  const _Body({
    required this.card,
    required this.textColor,
    required this.titleColor,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.noteColor,
    this.align = TextAlign.center,
  });

  final ShareCard card;
  final Color textColor;
  final Color titleColor;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color noteColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final c = card.content;
    final cross = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: cross,
      children: [
        if (c.title != null) ...[
          Text(
            c.title!,
            textAlign: align,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(c.text, textAlign: align, style: card.bodyStyle(textColor)),
        if (c.badge != null) ...[
          const SizedBox(height: 16),
          _Badge(
            text: c.badge!,
            background: badgeBackground,
            foreground: badgeForeground,
          ),
        ],
        if (card.showNote && c.note != null) ...[
          const SizedBox(height: 16),
          Text(
            c.note!,
            textAlign: align,
            style: TextStyle(color: noteColor, fontSize: 12.5, height: 1.75),
          ),
        ],
      ],
    );
  }
}

/// The source line and Athar's mark.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.text,
    required this.textColor,
    required this.brandColor,
  });

  final String? text;
  final Color textColor;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: text == null
              ? const SizedBox.shrink()
              : Text(
                  text!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11.5,
                    height: 1.6,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        _Brand(color: brandColor),
      ],
    );
  }
}

// ── Designs ──────────────────────────────────────────────────────────────

/// Deep theme gradient, a double gold frame with corner stars, gold ornaments.
class _Classic extends StatelessWidget {
  const _Classic(this.card);
  final ShareCard card;

  @override
  Widget build(BuildContext context) {
    final p = card.palette;
    const gold = ShareCardPalette.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.deep, p.deeper],
        ),
      ),
      child: Stack(
        children: [
          // A soft glow behind the text.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.85,
                  colors: [p.glow.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gold.withValues(alpha: 0.45)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: CustomPaint(
                  foregroundPainter: _CornerStarsPainter(
                    gold.withValues(alpha: 0.8),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.75),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                      child: Column(
                        children: [
                          const Text(
                            '۞',
                            style: TextStyle(color: gold, fontSize: 22),
                          ),
                          if (card.content.kicker != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: gold.withValues(alpha: 0.10),
                                border: Border.all(
                                  color: gold.withValues(alpha: 0.7),
                                ),
                              ),
                              child: Text(
                                card.content.kicker!,
                                style: const TextStyle(
                                  color: ShareCardPalette.goldSoft,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 26),
                              child: _Body(
                                card: card,
                                textColor: Colors.white,
                                titleColor: ShareCardPalette.goldSoft,
                                badgeBackground: gold,
                                badgeForeground: p.deeper,
                                noteColor: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                          const _OrnamentRule(color: gold),
                          const SizedBox(height: 12),
                          _Footer(
                            text: card.content.footer,
                            textColor: Colors.white.withValues(alpha: 0.7),
                            brandColor: gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A paper mihrab arch, gold-edged, standing on the deep theme colour.
class _Arch extends StatelessWidget {
  const _Arch(this.card);
  final ShareCard card;

  @override
  Widget build(BuildContext context) {
    final p = card.palette;
    const gold = ShareCardPalette.gold;
    return ColoredBox(
      color: p.deeper,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StarLatticePainter(
                Colors.white.withValues(alpha: 0.05),
                cell: 56,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
            child: Column(
              children: [
                if (card.content.kicker != null) ...[
                  Text(
                    card.content.kicker!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ShareCardPalette.goldSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: CustomPaint(
                    foregroundPainter: _ArchStrokePainter(gold),
                    child: ClipPath(
                      clipper: const _ArchClipper(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [p.paper, p.paperDeep],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 96, 24, 28),
                          child: Column(
                            children: [
                              Expanded(
                                child: _Body(
                                  card: card,
                                  textColor: p.ink,
                                  titleColor: p.vivid,
                                  badgeBackground: p.vivid,
                                  badgeForeground: Colors.white,
                                  noteColor: p.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _OrnamentRule(
                                color: p.vivid.withValues(alpha: 0.8),
                                width: 110,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Footer(
                  text: card.content.footer,
                  textColor: Colors.white.withValues(alpha: 0.72),
                  brandColor: gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A diagonal theme gradient under a star lattice, with a frosted panel.
class _Pattern extends StatelessWidget {
  const _Pattern(this.card);
  final ShareCard card;

  @override
  Widget build(BuildContext context) {
    final p = card.palette;
    const gold = ShareCardPalette.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [p.vivid, p.deep, p.deeper],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StarLatticePainter(
                Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    if (card.content.kicker != null)
                      Expanded(
                        child: Text(
                          card.content.kicker!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    CustomPaint(
                      size: const Size(18, 18),
                      painter: _SingleStarPainter(gold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: p.deeper.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: _Body(
                      card: card,
                      textColor: Colors.white,
                      titleColor: ShareCardPalette.goldSoft,
                      badgeBackground: Colors.white.withValues(alpha: 0.14),
                      badgeForeground: ShareCardPalette.goldSoft,
                      noteColor: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Footer(
                  text: card.content.footer,
                  textColor: Colors.white.withValues(alpha: 0.75),
                  brandColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleStarPainter extends CustomPainter {
  _SingleStarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _star(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SingleStarPainter old) => old.color != color;
}

/// Light paper, a vivid band on the reading side, generous type.
class _Minimal extends StatelessWidget {
  const _Minimal(this.card);
  final ShareCard card;

  @override
  Widget build(BuildContext context) {
    final p = card.palette;
    return ColoredBox(
      color: p.paper,
      child: Stack(
        children: [
          // The band on the reading (right) side.
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.vivid, ShareCardPalette.gold],
                ),
              ),
            ),
          ),
          // A large, faint star behind the text.
          PositionedDirectional(
            end: -60,
            bottom: -60,
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _OutlineStarPainter(p.vivid.withValues(alpha: 0.07)),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(34, 30, 26, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.content.kicker != null)
                  Text(
                    card.content.kicker!,
                    style: TextStyle(
                      color: p.vivid,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(width: 36, height: 3, color: ShareCardPalette.gold),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: _Body(
                      card: card,
                      textColor: p.ink,
                      titleColor: p.vivid,
                      badgeBackground: p.vivid.withValues(alpha: 0.12),
                      badgeForeground: p.vivid,
                      noteColor: p.inkMuted,
                      align: TextAlign.start,
                    ),
                  ),
                ),
                Divider(height: 1, color: p.inkMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                _Footer(
                  text: card.content.footer,
                  textColor: p.inkMuted,
                  brandColor: p.vivid,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineStarPainter extends CustomPainter {
  _OutlineStarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawPath(_star(c, size.shortestSide / 2 - 6), stroke);
    canvas.drawCircle(c, size.shortestSide * 0.18, stroke..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(_OutlineStarPainter old) => old.color != color;
}
