# Level frames — redesign spec

Ten level frames built from **metal + tintable enamel**. The metal (bronze →
silver → gold) carries the rank and never changes colour; the enamel is drawn
in greyscale and tinted at runtime with the active theme preset's `vivid`
colour, so one set of artwork matches every theme.

---

## 1. Ladder

| # | Title (m / f) | English | Metal | Silhouette idea |
|---|---|---|---|---|
| 1 | المحافظ / المحافِظة | The Preserver | Bronze | Plain ring, one engraved line |
| 2 | المواظب / المواظبة | The Constant | Bronze | Ring of small 8-point stars |
| 3 | الصابر / الصابرة | The Patient | Silver | Plain ring, double rim |
| 4 | الذاكر / الذاكرة | The Rememberer | Silver | Band of 8-point stars on enamel |
| 5 | الشاكر / الشاكرة | The Grateful | Silver | Interlaced geometric band (girih) |
| 6 | الخاشع / الخاشعة | The Humble | Gold | Star band on enamel, thicker ring |
| 7 | القانت / القانتة | The Devout | Gold | Raised girih, scalloped **outer** edge |
| 8 | المحسن / المحسنة | The Excellent | Gold | Girih + 4 star medallions (N/E/S/W) |
| 9 | السابق بالخيرات / السابقة بالخيرات | The Foremost in Good | Gold | Medallions + crown cluster at top |
| 10 | المقرَّب / المقرَّبة | The Near | Gold + pearl inlay | Crown + pointed-arch (mihrab) crest, light rays |

Each step changes something that survives at 40 px: the **metal**, the
**outline shape**, or a **big ornament**. Fine pattern is a bonus, never the
only difference.

---

## 2. Geometry (non-negotiable)

`FramedAvatar` draws the frame box at `1.28 ×` the avatar diameter, so on a
512 px canvas the photo is a circle of **radius 200 px** centred at (256, 256).

Work on a **1024 × 1024 master** and export at 512. Values below are for the
1024 master (halve them for 512):

| Measure | 1024 master | 512 export |
|---|---|---|
| Centre | (512, 512) | (256, 256) |
| Photo radius | 400 | 200 |
| **Frame inner edge** (overlap hides the photo's antialiased edge) | **392** | **196** |
| Ring outer edge, levels 1–5 | 470 – 480 | 235 – 240 |
| Ring outer edge, levels 6–10 | 480 – 496 | 240 – 248 |
| Ornaments (medallions, crown, crest) may reach | ≤ 508 | ≤ 254 |

Rules:
- The inner edge is a **perfect circle** at every level. Nothing — scallops,
  medallion points, crown — may cross inside r = 392.
- Ornaments grow **outward** only. Crown/crest at the top must stay inside
  the canvas, so the ring band may thin slightly under the crown.
- Centre and background fully transparent.
- Draw the inner and outer circles as **vector masks** during clean-up; never
  trust the generator's circle.

---

## 3. Layers and files

Per level, three PNGs (RGBA, 512 × 512, sRGB):

| File | Contents | Used by |
|---|---|---|
| `frame_N_metal.png` | Metal only. Transparent wherever enamel sits. Full colour, shading, highlights. | New app — top layer |
| `frame_N_enamel.png` | Enamel only, **greyscale**. Opaque where enamel sits, transparent elsewhere. | New app — bottom layer, tinted |
| `frame_N.png` | Flat composite: enamel tinted with Athar Green `#0F6B4B` + metal on top. | Old app builds, `frame_url` from backend, share cards, fallback |

Keeping `frame_N.png` as a complete frame means nothing breaks for builds that
don't know about layers.

### Enamel greyscale rules
The app will tint with a multiply-style blend (`BlendMode.modulate` /
`srcATop` colour filter), so grey value = how much of the theme colour shows.
- Base enamel: **75 – 90 % luminance** (light grey, not white).
- Shading/recesses: down to **45 %**. Never below 35 % — it turns muddy black on dark themes.
- Highlights: up to **100 %** for a glossy sheen; keep them soft.
- No colour in this layer at all.
- Slightly overlap the metal (2 – 3 px under the metal edges) so no seam shows when tinted.

### Metal palettes

| Metal | Shadow | Mid | Highlight | Halo colour (for the glow later) |
|---|---|---|---|---|
| Bronze | `#5E3A1A` | `#9C6634` | `#E0A86B` | `#B87A45` |
| Silver | `#5F666D` | `#A8AFB6` | `#F2F4F6` | `#C9D1D8` |
| Gold | `#7A5A17` | `#C8A95B` (app gold) | `#F7E3A1` | `#C8A95B` |
| Pearl (L10) | `#B9B3A6` | `#ECE6DA` | `#FFFFFF` | — |

Metals must read clearly on **both** a light (`#F7F5EF`) and a dark
(`#121614`) background — keep a thin darker outline on the outermost edge.

---

## 4. Production workflow

Generators can't output clean separate layers, so:

1. **Generate** each frame with the enamel in a flat **key colour: vivid
   magenta `#FF00FF`**. It is far from bronze, silver and gold, so it selects
   cleanly. Background and centre: flat pure white.
2. **Upscale/clean** to 1024 master.
3. **Fix symmetry**: if the pattern is 8-fold, keep the best 1/8 wedge (or 1/4
   for levels 8–10) and rotate-repeat it. Crown/crest: mirror left half.
4. **Mask geometry**: apply the vector inner circle (r 392) and outer
   silhouette; delete everything inside the hole.
5. **Split**: select magenta (colour range, fuzziness ~40) → move to the enamel
   layer → desaturate → levels to fit the 45 – 100 % range. Remaining pixels
   are the metal layer; fill any magenta fringes with neighbouring metal.
6. **Composite** `frame_N.png` with enamel tinted `#0F6B4B`.
7. **Export** all three at 512. Run through TinyPNG/oxipng; target ≤ 250 KB each.

### Acceptance checklist
- [ ] Inner hole exactly r 196 @512, round, nothing intrudes.
- [ ] At **40 px** levels 1–10 are tellable apart (print a strip of all ten at 40 px).
- [ ] Tinted with each preset's `vivid` — `#0F6B4B`, `#0B6A4F`, `#2E5AA3`, `#855726`, `#8A2D3A`, `#3D5366` — still looks good.
- [ ] Works on light and dark backgrounds.
- [ ] No magenta fringe left anywhere.
- [ ] Bronze levels look **honourable**, not cheap — level 1 is still a reward.

---

## 5. Prompts

Each prompt below is complete and self-contained — paste as is. Same seed
across levels if your tool allows, for a consistent rendering style.

**Negative prompt (use for all):**
```
text, letters, calligraphy, numbers, watermark, logo, signature, human figure, face, animals, photo in the centre, anything inside the central circle, background scenery, perspective tilt, 3/4 view, cropped edges, asymmetric, blurry, noisy, jpeg artifacts, extra rings inside the hole, green, blue, red enamel, colored background
```

### Level 1 — The Preserver (bronze, plain)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of polished warm bronze with soft studio lighting from the top-left, subtle bevel on inner and outer edges. A single thin inset channel running around the middle of the ring is filled with flat vivid magenta (#FF00FF) glossy enamel. One fine engraved line follows the outer rim. Minimal, elegant, Islamic-inspired restraint. Ring band thin: about 18% of the radius. Clean game UI asset, high detail, sharp edges, 1024x1024.
```

### Level 2 — The Constant (bronze, small stars)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of polished warm bronze with soft top-left studio lighting and beveled rims. The band is filled with flat vivid magenta (#FF00FF) glossy enamel, and on it sit 24 small evenly spaced raised bronze 8-pointed Islamic stars (khatam) in a single row. Thin bronze rims on both edges. Islamic geometric style, refined and simple. Ring band about 20% of the radius. Clean game UI asset, symmetrical, sharp, 1024x1024.
```

### Level 3 — The Patient (silver, double rim)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of bright polished sterling silver with cool soft top-left studio lighting. Two raised silver rims, inner and outer, with a wide band of flat vivid magenta (#FF00FF) glossy enamel between them. A delicate engraved arabesque vine line runs along each silver rim. Calm, clean, Islamic-inspired elegance. Ring band about 20% of the radius. Clean game UI asset, symmetrical, sharp, 1024x1024.
```

### Level 4 — The Rememberer (silver, star band)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of polished sterling silver with soft top-left studio lighting and beveled rims. The band is flat vivid magenta (#FF00FF) glossy enamel decorated with 20 evenly spaced raised silver 8-pointed Islamic stars, each star outlined and slightly domed, linked to its neighbours by a thin silver line. Double silver rims on both edges. Islamic geometric art, balanced and rhythmic. Ring band about 22% of the radius. Clean game UI asset, symmetrical, sharp, 1024x1024.
```

### Level 5 — The Grateful (silver, girih)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of polished sterling silver with soft top-left studio lighting. The band contains a continuous interlaced Islamic geometric girih lattice in raised silver strapwork, with all the gaps between the straps filled with flat vivid magenta (#FF00FF) glossy enamel. Small 8-pointed stars form at the lattice intersections. Fine beaded silver border on both edges. Intricate yet readable, 16-fold radial symmetry. Ring band about 22% of the radius. Clean game UI asset, sharp, 1024x1024.
```

### Level 6 — The Humble (gold, star band)
```
A circular avatar frame ring, perfectly round, viewed straight on, centered on a flat pure white background, the large central circle is empty flat pure white. Ring made of rich polished gold (#C8A95B tone) with warm soft top-left studio lighting and deep bevels, noticeably thicker than a simple ring. The band is flat vivid magenta (#FF00FF) glossy enamel with 16 large raised gold 8-pointed Islamic stars, each with a small domed gold centre, evenly spaced. Heavy double gold rims with a fine engraved line. Luxurious, dignified, Islamic geometric style. Ring band about 25% of the radius. Clean game UI asset, symmetrical, sharp, 1024x1024.
```

### Level 7 — The Devout (gold, scalloped outer edge)
```
A circular avatar frame, viewed straight on, centered on a flat pure white background, the large central circle is perfectly round and empty flat pure white. Frame made of rich polished gold with warm top-left studio lighting. The inner edge is a perfect smooth circle; the OUTER edge is scalloped with 16 pointed Islamic arch lobes. The band holds a raised, deeply sculpted gold interlaced girih lattice with all the gaps filled with flat vivid magenta (#FF00FF) glossy enamel. Strong depth and shadow between strapwork layers. Ornate Islamic metalwork, 16-fold radial symmetry. Ring band about 26% of the radius. Clean game UI asset, sharp, 1024x1024.
```

### Level 8 — The Excellent (gold, four medallions)
```
A circular avatar frame, viewed straight on, centered on a flat pure white background, the large central circle is perfectly round and empty flat pure white. Frame made of rich polished gold with warm top-left studio lighting. The band is a raised gold interlaced Islamic girih lattice with gaps filled with flat vivid magenta (#FF00FF) glossy enamel. At the top, bottom, left and right, four large gold 8-pointed star medallions sit on the band and project OUTWARD beyond the outer rim (never inward into the central circle); each medallion has a magenta enamel centre and a domed gold boss. Beaded gold rims. Majestic Islamic metalwork, 4-fold symmetry. Clean game UI asset, sharp, 1024x1024.
```

### Level 9 — The Foremost in Good (gold, crown)
```
A circular avatar frame, viewed straight on, centered on a flat pure white background, the large central circle is perfectly round and empty flat pure white. Frame made of rich polished gold with warm top-left studio lighting and strong highlights. The band is a raised gold interlaced Islamic girih lattice with gaps filled with flat vivid magenta (#FF00FF) glossy enamel. At the top, a crown cluster of three gold 8-pointed star medallions (the centre one largest) rises OUTWARD above the ring; smaller star medallions at the left, right and bottom also project outward. Each medallion has a magenta enamel centre. Nothing intrudes into the central circle. Regal, celebratory Islamic metalwork, mirror-symmetrical left to right. Clean game UI asset, sharp, 1024x1024.
```

### Level 10 — The Near (gold + pearl, mihrab crest)
```
A circular avatar frame, viewed straight on, centered on a flat pure white background, the large central circle is perfectly round and empty flat pure white. Frame made of radiant polished gold with warm top-left studio lighting and brilliant highlights, inlaid with a row of small lustrous white pearls along the outer rim. The band is a finely sculpted, multi-layered gold interlaced Islamic girih lattice with gaps filled with flat vivid magenta (#FF00FF) glossy enamel. At the top, a tall pointed Islamic arch (mihrab) crest in gold rises OUTWARD above the ring, with a large 8-pointed star at its centre on magenta enamel, flanked by two smaller star medallions; small star medallions at left, right and bottom project outward. Subtle golden light rays fan out behind the crest only. Nothing intrudes into the central circle. The most precious and luminous frame of the set, mirror-symmetrical left to right. Clean game UI asset, sharp, 1024x1024.
```

---

## 6. Code hooks this spec assumes (for later — not done yet)

- `_Frame` stacks `frame_N_enamel.png` (colour-filtered with the theme's
  `vivid`) under `frame_N_metal.png`; falls back to `frame_N.png` when layers
  are missing.
- `FramedAvatar._haloSteps` becomes 10, and the halo colour follows the metal
  (bronze / silver / gold) instead of always gold.
- Backend: `LevelService::TIERS` + `LevelSeeder` get the 10 tiers;
  `frame_url` points at `frame_N.png` (flat composite) for older builds.
