// The "My World" globe, drawn per pixel.
//
// Each pixel inside the disc is a point on a unit sphere, rotated back into
// world space by the camera's yaw and pitch, and looked up in a land mask
// built at runtime from assets/globe/continents.svg (reprojected from
// Robinson to longitude/latitude; see globe_land_raster.dart). Zoomed in, a
// second mask covers just the area in view at screen resolution, rendered
// from the same SVG, so coastlines stay sharp. Land is slate tinted with the
// app theme's colour; the sea is deep navy. Around it, a thin atmosphere
// glow; behind it, black space with a few faint stars. Pillars are painted on
// top in Dart, with the same projection (see GlobeCamera in
// my_world_globe.dart).
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
uniform sampler2D uLand;   // the whole world; red channel: 1 on land, 0 at sea
uniform sampler2D uDetail; // the area in view, sharper

out vec4 fragColor;

const float PI = 3.14159265359;

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

    // Atmosphere seen through the edge of the disc.
    float fresnel = pow(1.0 - v.z, 3.0);
    earth += uAccent * fresnel * 0.75;

    float edge = smoothstep(1.0, 1.0 - 1.5 * px, r);
    col = mix(col, earth, edge);
  }

  fragColor = vec4(col, 1.0);
}
