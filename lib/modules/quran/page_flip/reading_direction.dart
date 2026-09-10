/// The side the book is bound on, and so the way the pages travel.
///
/// A Latin book is bound on the left and read [leftToRight]: the free edge is
/// on the right, and going forward carries it leftward. A Mushaf, and Arabic
/// books generally, are bound on the right and read [rightToLeft] — the same
/// motion in the opposite sense.
enum TurnableReadingDirection { leftToRight, rightToLeft }
