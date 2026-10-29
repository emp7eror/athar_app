// The "My World" globe, drawn per pixel.
//
// Each pixel inside the disc is a point on a unit sphere, rotated back into
// world space by the camera's yaw and pitch, and looked up in a land mask
// built at runtime from assets/globe/continents.svg (reprojected from
// Robinson to longitude/latitude; see globe_land_raster.dart). Zoomed in, a
// second mask covers just the area in view at screen resolution, rendered
// from the same SVG, so coastlines stay sharp. Land is slate tinted with the
// app theme's colour; the sea is deep navy. Around it, a thin atmosphere
// glow; behind it, black space with a few faint stars.
//
// Activity glows on the surface itself: each place is a soft gaussian of
// light by angle on the sphere (see HotspotStyle in my_world_hotspots.dart),
// so it follows the curvature and turns with the globe, and the far side
// simply has none. Spots add up and saturate softly into one lit region, and
// each breathes on its own slow cycle. At its middle each place has a bright
// centre: a small near-white point in a tight bloom, a few pixels across at
// any zoom.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;        // canvas size, logical px
uniform vec2 uCenter;      // globe centre on the canvas
uniform float uRadius;     // globe radius, px
uniform float uYaw;        // rotation about the polar axis, radians
uniform float uPitch;      // latitude facing the viewer, radians
uniform float uTime;       // seconds, for the stars' twinkle (0 when motion is reduced)
uniform vec3 uAccent;      // the app theme's brand colour, at full brightness
uniform vec4 uDetailRect;  // the detail mask's area in world uv: u0, v0, du, dv
uniform float uDetailOn;   // 1 when the detail mask is set
uniform vec4 uGlow;        // lit places, selected slot (-1 for none), spread, unused
uniform vec3 uGlowColor;   // the theme's brand colour at full brightness
uniform vec3 uGlowHighlight; // the theme's highlight (gold), for the selection
uniform vec4 uSpots[32];   // each place: unit vector, spread at world scale (radians)
uniform vec4 uSpotsB[32];  // each place: strength, breathing phase
uniform sampler2D uLand;   // the whole world; red channel: 1 on land, 0 at sea
uniform sampler2D uDetail; // the area in view, sharper

out vec4 fragColor;

const float PI = 3.14159265359;
const float BREATH = 4.2; // seconds a breath

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

vec3 space(vec2 frag) {
  vec3 col = vec3(0.0);

  // Sparse stars on a 3px grid.
  vec2 cell = floor(frag / 3.0);
  float h = hash(cell);
  if (h > 0.9965) {
    float twinkle = 0.65 + 0.35 * sin(uTime * (0.6 + h * 2.0) + h * 40.0);
    col += vec3(0.6, 0.66, 0.8) * (h - 0.9965) / 0.0035 * 0.6 * twinkle;
  }
  return col;
}

float land(vec2 uv) {
  if (uDetailOn > 0.5) {
    // Longitude wraps, so the area may straddle the date line.
    float lx = fract(uv.x - uDetailRect.x) / uDetailRect.z;
    float ly = (uv.y - uDetailRect.y) / uDetailRect.w;
    if (lx < 1.0 && ly >= 0.0 && ly <= 1.0) {
      return texture(uDetail, vec2(lx, ly)).r;
    }
  }
  return texture(uLand, vec2(fract(uv.x), clamp(uv.y, 0.0, 1.0))).r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - uCenter) / uRadius;
  float r = length(p);
  float px = 1.0 / uRadius; // one pixel in sphere units

  vec3 col = space(frag);

  // Atmosphere halo outside the disc.
  if (r > 1.0 - px) {
    float halo = exp(-(r - 1.0) * 9.0) * smoothstep(1.0 - px, 1.0 + px, r);
    col += uAccent * halo * 0.55;
  }

  if (r < 1.0) {
    vec3 v = vec3(p.x, -p.y, sqrt(1.0 - r * r));

    // Back into world space: inverse pitch, then inverse yaw.
    float cp = cos(uPitch);
    float sp = sin(uPitch);
    vec3 a = vec3(v.x, v.y * cp + v.z * sp, -v.y * sp + v.z * cp);
    float cy = cos(uYaw);
    float sy = sin(uYaw);
    vec3 w = vec3(a.x * cy - a.z * sy, a.y, a.x * sy + a.z * cy);

    float lat = asin(clamp(w.y, -1.0, 1.0));
    float lon = atan(w.x, w.z);
    vec2 uv = vec2(lon / (2.0 * PI) + 0.5, 0.5 - lat / PI);

    float m = land(uv);

    // Sea deep navy; land slate leaning towards the theme colour.
    vec3 sea = vec3(0.022, 0.040, 0.092);
    vec3 ground = mix(vec3(0.15, 0.17, 0.22), uAccent * 0.42, 0.32);
    vec3 earth = mix(sea, ground, m);

    // Soft key light from the upper left, and darker towards the limb.
    vec3 light = normalize(vec3(-0.45, 0.5, 0.75));
    float diffuse = 0.62 + 0.38 * max(dot(v, light), 0.0);
    earth *= diffuse * mix(0.55, 1.0, smoothstep(0.0, 0.6, v.z));

    // Activity: the sum of every lit place's glow at this point of the Earth.
    float glow = 0.0;
    float ring = 0.0;
    float centre = 0.0;
    float bloom = 0.0;
    int count = int(uGlow.x + 0.5);
    for (int i = 0; i < 32; i++) {
      if (i >= count) break;
      vec4 s = uSpots[i];
      vec4 b = uSpotsB[i];
      // 0..1 and back, smoothly: wider and a little brighter at the top.
      float breath = 0.5 - 0.5 * cos(2.0 * PI * uTime / BREATH + b.y);
      float sigma = s.w * uGlow.z * (1.0 + 0.14 * breath);
      // Squared chord between the two points: the angle squared, nearly.
      float d2 = 2.0 * max(0.0, 1.0 - dot(w, s.xyz));
      float sig2 = sigma * sigma;
      if (d2 > 18.0 * sig2) continue; // past three spreads: nothing to add
      float pulse = 0.85 + 0.15 * breath;
      float g = b.x * pulse * exp(-d2 / (2.0 * sig2));

      // The centre: a fraction of the glow, but never under ~2 px, so it
      // stays a crisp point however far in or out.
      float cs = max(0.07 * sigma, 2.2 * px);
      float c = b.x * (0.9 + 0.1 * breath) * exp(-d2 / (2.0 * cs * cs));
      float cb = 3.5 * cs;
      float bl = b.x * pulse * exp(-d2 / (2.0 * cb * cb));

      if (abs(float(i) - uGlow.y) < 0.5) {
        g *= 1.35;
        c *= 1.25;
        // A soft ring round the selected place.
        float d = sqrt(d2);
        float rr = (d - 1.15 * sigma) / (0.2 * sigma);
        ring = max(ring, exp(-rr * rr));
      }
      glow += g;
      centre += c;
      bloom += bl;
    }
    // Soft saturation: overlaps merge without seams, and the busiest
    // region can't burn out. Light is added, so the land shows through.
    float lit = 1.0 - exp(-1.4 * glow);
    // Fades as the surface turns away, rather than ending at the edge.
    float toward = smoothstep(0.0, 0.25, v.z);
    earth += uGlowColor * lit * 0.5 * toward;
    earth += mix(uGlowColor, vec3(1.0), 0.45) * lit * lit * 0.2 * toward;
    // The bright centre and the bloom close round it.
    earth += uGlowColor * min(bloom, 1.2) * 0.45 * toward;
    earth += mix(uGlowColor, vec3(1.0), 0.75) * min(centre, 1.3) * 0.95 * toward;
    earth += uGlowHighlight * ring * 0.3 * toward;

    // Atmosphere seen through the edge of the disc.
    float fresnel = pow(1.0 - v.z, 3.0);
    earth += uAccent * fresnel * 0.75;

    float edge = smoothstep(1.0, 1.0 - 1.5 * px, r);
    col = mix(col, earth, edge);
  }

  fragColor = vec4(col, 1.0);
}
