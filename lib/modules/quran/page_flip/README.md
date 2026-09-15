# Fork notice

This is a vendored fork of `turnable_page` v1.0.1 by Saeed Ahmed
(https://github.com/saeedahmed725/turnable_page), used in Athar with the
copyright holder's permission. The upstream LICENSE (TPPL) is kept verbatim
in `LICENSE`; the copyright remains Saeed Ahmed's.

Record the written permission here (date, and where the grant is on file)
before this ships:

    Permission granted by: Saeed Ahmed
    Date:
    On file at:

## Changes from upstream v1.0.1

- **Right-to-left reading.** `TurnablePage.readingDirection` binds the book on
  the right, for the Mushaf and for Arabic books generally. Upstream is
  left-bound only. See `lib/src/enums/reading_direction.dart`.
- **`TurnablePdf` and the `pdfrx` dependency removed.** Athar renders SVG
  pages, never PDFs, and `pdfrx` pulls in native PDFium on every platform.

Both are candidates to send upstream; the RTL work is the one worth a PR.
- Two analyzer fixes so the module is clean under Athar's lints: a missing
  `void` on `PageFlipController.initializeController`, and `Matrix4.scale`
  (deprecated) replaced by `Matrix4.diagonal3Values`.
- **Stale-canvas crash on paint fixed.** `RenderTurnableBook.paint` cached
  `context.canvas` in a local and kept using it across `paintChild`. Painting a
  child that needs its own layer ends the current recording, so the cached
  canvas referred to a disposed native peer and threw
  `Bad state: ... native peer has been collected` on the next draw — night mode
  puts a `ColorFilter` over each page, which is exactly such a child. The paint
  path now reads `context.canvas` fresh at every use, and the mid-turn page is
  placed with `pushTransform`/`pushClipPath` instead of raw canvas transforms
  that a layered child would never receive.
- **`FlipSettings.interactiveFold`** (default `true`, upstream behaviour). With
  it off the paper does not move while the finger is down: the page holds still
  and turns in one animation once the swipe is finished. Athar's Mushaf uses
  this — a thumb resting on the page must never lift its corner. The 250ms
  flick window is also lifted in that mode, since a page that gives no feedback
  under the finger has to accept a slow, deliberate drag as a turn.
- **`FlipSettings.paperColor`** (default white, upstream behaviour). Upstream
  painted the book ground, the sheet mid-turn and the trailing blank page in
  hardcoded `0xFFFFFFFF`. Athar feeds it `QuranPalette.groundFor(nightMode)`, so
  the paper is the Mushaf's own — no white flash behind a night-mode page.
- **The fold waits for movement.** Upstream called `startUserTouch` on
  touch-down, so merely resting a finger lifted the page corner. It now starts
  on the first movement past the drag threshold, from the point the finger
  landed. That also makes a whole-page `cornerTriggerAreaSize` safe: the paper
  can be grabbed anywhere without a still finger disturbing it.
- **A page mid-turn is no longer painted twice.** In portrait
  `getFlippingPage` returns a detached copy of the current page, and the copy
  keeps the original's index — so the flat page and the folded-over part of the
  sheet resolved to the same child. Flutter paints a child once per frame and
  the later call silently wins, so upstream drew the script onto the *back* of
  the sheet and left its face blank. The face now keeps the script and the
  folded-over back is painted in paper alone, which is also how a real page
  behaves.
- **`FlipSettings.alwaysPortrait`** (default `false`, upstream behaviour).
  Upstream `usePortrait` only *allows* a single page: the book still opens a
  two-page spread whenever the box is at least two pages wide. With the paper
  boundary disabled the book is laid out across the whole available width, so a
  phone in landscape always got a spread — a turn then moved two pages, and a
  reader that loads only the pages beside the current one showed the pages
  turned to as blank. `alwaysPortrait` rules the spread out in both sizing
  modes. Athar's Mushaf sets it.
