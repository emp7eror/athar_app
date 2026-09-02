# Level frames

Drop the level-frame artwork here using this naming convention:

```
frame_1.png   # The Preserver
frame_2.png   # The Constant
frame_3.png   # The Rememberer
frame_4.png   # The Devout
frame_5.png   # The Foremost in Good
```

The frame path is resolved entirely on-device — `LevelInfo.frame` (in
`lib/data/models/user_model.dart`) computes `assets/frames/frame_$level.png`
from the level id the backend reports; the backend itself has no notion of
Flutter asset paths. Every avatar in the app renders through `FramedAvatar`
(`lib/widgets/framed_avatar.dart`), so dropping the 5 PNGs in here — no code
changes — makes them appear everywhere at once: leaderboard, profile, friends
list, friend requests, the level-up popup, the achievement share card, and
the profile preview modal.

Until a file is present, `FramedAvatar` fails silently (no border rendered)
rather than crashing.

Recommended: square PNG, transparent center, ~512×512, designed as a ring/
border so the user's circular avatar photo shows through the middle.
