# Asset support

dotdart favors deterministic, efficient generated code over broad format
coverage. Unsupported features fail or produce an explicit build warning.

## SVG

Supported:

- `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, and
  `polygon`
- groups and inherited presentation attributes
- fill, stroke, opacity, fill rule, line cap, and line join
- `translate()`, `scale()`, `rotate()`, `matrix()`, `skewX()`, and `skewY()`
  transforms on groups, drawable shapes, and shapes inside clip paths
- `viewBox` offsets
- `defs`, `clipPath`, and `clip-path="url(#id)"`
- some exported drop shadows (see below)
- an optional UTF-8 byte order mark and standard leading XML declaration

Not supported:

- gradients, arbitrary filters, masks, patterns, text, or embedded images
- CSS `style` blocks
- `use` and `symbol`
- arc path commands
- CSS transforms and transforms on the root `svg` element

Matrix and skew calculations happen at build time. Generated painters reuse
cached matrix data. Transform numbers must be finite; skew angles at odd
multiples of 90 degrees are undefined and rejected.

Generated SVG accessors expose supported source colors as direct optional
parameters. A drawable's `id` is used first; an unnamed drawable uses its
nearest ancestor group `id`. The root `svg` ID does not own colors. IDs are
sanitized to lower camel case with `Color` appended once, so `inner_text`
becomes `innerTextColor`. A scope with multiple distinct colors receives
source-order suffixes such as `outlineColor1` and `outlineColor2`, with fills
collected before strokes. Equal RGBA values deduplicate only within one scope,
so identical colors under different IDs remain independently customizable.
Anonymous colors deduplicate separately and use `color1`, `color2`, and later
fallbacks.

SVG IDs must be non-empty, contain no whitespace, be valid standalone XML IDs,
and be unique across the document. If different valid IDs sanitize to the same
Dart name, the later parameter receives a deterministic numeric suffix. The
generated Dartdoc records the original SVG ID.

### SVG drop shadows

dotdart supports some SVG exports with a single shadow outside a shape or group.
It preserves the shadow's position, softness, color, and transparency. Support
depends on how your design tool saves the shadow, so two SVGs that look the same
may not both be supported.

Inner shadows, stacked shadows on the same artwork, and shadows combined with
group clipping or group transparency are not supported. If dotdart rejects a
shadow, simplify or remove the effect in your design tool and export again.
You can also export the artwork as a PNG or WebP to keep its appearance.

To change the shadow's color or transparency, edit the source asset and
regenerate it. Shape colors can still be changed through the generated widget's
color parameters.

Shadows take more work to draw. Check performance on your target devices when
displaying many large icons with shadows.

## Lottie

Supported:

- shape layers with groups, paths, rectangles, ellipses, fills, and strokes
- reusable precomposition layers, with sizes on their layers or assets
- nested shape groups with inherited fills and strokes and animated positions
- adjacent alpha and inverted-alpha mattes, where one layer's opacity reveals
  or hides the next layer
- parented layer transforms, including null controller layers
- static text layers, including point text and paragraph boxes
- static, non-inverted, fully opaque additive masks with zero expansion
- transforms, opacity, hold keyframes, and cubic Bézier easing
- one static or animated trim-path modifier per shape group, including start,
  end, offset, wraparound, default shape direction, and parallel or sequential
  multiple-shape modes
- timeline playback with one-time or continuous-loop modes, one-time playback
  delay, duration override, progress control, sizing, text replacement, and
  color overrides
- app lifecycle pause and resume behavior

Generated Lottie accessors clip painting to the source canvas by default,
matching normal Lottie-player behavior. Pass `clip: false` to allow layers to
paint beyond that boundary.

Automatic playback uses `LottiePlayback.once` by default and keeps the final
frame visible. Pass `playback: LottiePlayback.loop` to repeat continuously.
Manual `progress` continues to take precedence over automatic playback.

Generated text and color fields live on the asset's generated `overrides`
object and use the Lottie layer name when one is available. Named text fields
end in `Text`, unless the name already does. For example, layers named `Job
Title` and `Miami Artwork` produce `jobTitleText`, `jobTitleTextColor`, and
`miamiArtworkColor1`. Repeated text layer names receive numbered fields such as
`jobTitleText2` and `jobTitleText2Color`, so every layer remains independently
editable. Unnamed layers use `text1`, `color1`, and later fields.

Text is painted with Flutter's `TextPainter`. Register the font family named in
the Lottie file in the consuming app when exact font metrics matter; Flutter's
normal font fallback is used otherwise.

Not supported:

- image, audio, camera, or animated text layers
- expressions, effects, precomposition time remapping, animated, translucent,
  expanded, inverted, or non-additive masks, luminance mattes, non-adjacent
  matte references, chains of masked matte sources, gradients, or 3D layers
- animated group scale, rotation, anchor, or opacity; move geometric transforms
  to layers, or flatten or precompose groups that animate opacity
- trim paths spanning nested groups
- paint stacks that cross an animated nested-group position when flattening would
  duplicate or discard a fill or stroke, and parent strokes across animated,
  scaled nested geometry; flatten the affected groups before exporting
- partial group opacity across multiple draws or nested paint stacks that require
  atomic compositing; flatten or precompose the affected group before exporting
- multiple trim-path modifiers in one shape group
- trim paths combined with reversed shape direction

Unsupported layer and shape types that can be skipped safely produce build
warnings. Features that would change rendering semantics fail generation.

## Images and GIFs

Supported formats are PNG, JPEG, WebP, and GIF. Generated metadata includes
intrinsic dimensions, aspect ratio, animation status, dominant color, and a
thumbhash placeholder.

Each namespace containing an image or GIF also has a generated cache class.
Warm one decoded image before it is shown, then remove that same entry when it
is no longer needed:

```dart
await $ImagesCache.precacheProfile(context, width: 160);

final image = $Images.profile(width: 160);

final removed = await $ImagesCache.removeProfile(context, width: 160);
```

Widths and heights are logical pixels. Use the same values for precaching,
rendering, and removal so Flutter addresses the same decoded cache entry. If
only one dimension is supplied, dotdart derives the other from the image's
intrinsic aspect ratio. If neither is supplied, the generated widget's default
display size is used. Removal releases the reusable cache entry without
discarding an image that is still being displayed.

For images and GIFs generated in a dependency package, pass its name as
`package` to the generated image widget and to both cache methods. For example,
`$Images.profile(package: 'my_assets')` uses an image from `my_assets`. The
package must declare the asset under `flutter: assets:`. App-owned assets can
omit `package`.

AVIF and HEIC are intentionally unsupported because their availability and
decode behavior are not consistent across the low-end devices dotdart targets.

## Sizing

SVG and Lottie widgets preserve their native aspect ratio by default. When both
`width` and `height` are provided, the larger requested dimension is used as
the reference. Pass `maintainAspectRatio: false` only when intentional
distortion is acceptable.
