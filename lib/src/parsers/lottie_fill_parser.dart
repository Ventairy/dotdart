part of 'lottie_parser.dart';

/// Normalizes independently positioned opacity and RGB stops before emission.
abstract final class _LottieFillParser {
  static LottieFill parse(Map<String, dynamic> raw, {required String path}) {
    final gradient = raw['ty'] == 'gf';
    final data = gradient ? LottieParser._requiredMap(raw['g'], path: '$path.g') : null;
    final count = data?['p'];
    if (gradient && (count is! int || count < 2)) {
      throw DotdartUnsupportedFeatureException('$path.g.p must specify at least two gradient colors.');
    }
    final colorPath = gradient ? '$path.g.k' : '$path.c';
    final property = LottieParser._requiredMap(gradient ? data!['k'] : raw['c'], path: colorPath);
    final animated = property['a'] == 1;
    final keys = animated ? LottieParser._optionalList(property['k'], path: '$colorPath.k') : const <Object?>[];
    if (animated && keys.isEmpty) throw DotdartInvalidLottieException('Missing keyframes at $colorPath.k.');
    final poses = <LottiePalettePose>[];
    final times = <LottieScalarKeyframe>[];
    List<double>? layout;
    List<double>? rgbPositions;
    List<double>? opacityPositions;
    List<int> colors(Object? value, String location) {
      final values = LottieParser._numberList(value, path: location);
      if (values.any((v) => !v.isFinite || v < 0 || v > 1)) {
        throw DotdartInvalidLottieException('Expected color and stop values from 0 to 1 at $location.');
      }
      if (!gradient) {
        if (values.length != 3 && values.length != 4) {
          throw DotdartInvalidLottieException('Expected RGB or RGBA at $location.');
        }
        return [_argb(values[0], values[1], values[2], values.length == 4 ? values[3] : 1)];
      }
      final palette = _gradient(values, count as int, location);
      if (rgbPositions != null &&
          (!_sameStops(rgbPositions!, palette.rgb) || !_sameStops(opacityPositions!, palette.alpha))) {
        throw DotdartUnsupportedFeatureException('$location animates gradient stop positions.');
      }
      rgbPositions = palette.rgb;
      opacityPositions = palette.alpha;
      layout = palette.stops;
      return palette.colors;
    }

    if (animated) {
      List<int>? previousEnd;
      for (var i = 0; i < keys.length; i++) {
        final location = '$colorPath.k[$i]';
        final key = LottieParser._requiredMap(keys[i], path: location);
        final time = key['t'];
        if (time is! num || !time.isFinite || (i > 0 && time <= times.last.time)) {
          throw DotdartInvalidLottieException('Expected increasing keyframe times at $location.t.');
        }
        final start = key['s'] == null && i == keys.length - 1 && previousEnd != null
            ? previousEnd
            : colors(key['s'], '$location.s');
        previousEnd = key['e'] == null ? null : colors(key['e'], '$location.e');
        poses.add((start: start, end: previousEnd ?? const []));
        final next = i + 1 < keys.length
            ? LottieParser._requiredMap(keys[i + 1], path: '$colorPath.k[${i + 1}]')
            : null;
        final outgoing = key['o'] as Map<String, dynamic>?;
        final incoming = LottieParser._incomingEasingFor(keyframe: key, nextKeyframe: next);
        for (final handle in [outgoing, incoming]) {
          for (final axis in ['x', 'y']) {
            final components = handle?[axis];
            if (components is List && components.toSet().length > 1) {
              throw DotdartUnsupportedFeatureException(
                '$location uses different easing for individual color channels.',
              );
            }
          }
        }
        times.add(
          LottieScalarKeyframe(
            time: time.toDouble(),
            start: i.toDouble(),
            outX: LottieParser._extractEasingValue(outgoing, 'x', 0),
            outY: LottieParser._extractEasingValue(outgoing, 'y', 0),
            inX: LottieParser._extractEasingValue(incoming, 'x', 0),
            inY: LottieParser._extractEasingValue(incoming, 'y', 0),
            hold: key['h'] == 1,
          ),
        );
      }
    } else {
      poses.add((start: colors(property['k'], '$colorPath.k'), end: const []));
    }
    final geometry = gradient ? _geometry(raw, path) : null;
    final first = poses.first.start.first;
    return LottieFill(
      colorR: ((first >> 16) & 255) / 255,
      colorG: ((first >> 8) & 255) / 255,
      colorB: (first & 255) / 255,
      colorA: (first >> 24) / 255,
      opacity: LottieParser._staticPropertyValue(raw['o'], path: '$path.o', fallback: 100),
      fillRule: raw['r'] as int? ?? 1,
      palette: LottieFillPalette(
        poses: poses,
        timing: LottieAnimatedScalar(animated: times.length > 1, keyframes: times),
        stops: layout ?? const [],
        geometry: geometry,
      ),
    );
  }

  static LottieGradientGeometry _geometry(Map<String, dynamic> raw, String path) {
    if (raw['t'] != 1 && raw['t'] != 2) {
      throw DotdartUnsupportedFeatureException('$path.t uses an unknown gradient type.');
    }
    if (raw['t'] == 2 &&
        raw['h'] != null &&
        LottieParser._staticPropertyValue(raw['h'], path: '$path.h', fallback: 0) != 0) {
      throw DotdartUnsupportedFeatureException('$path.h uses an off-center radial gradient.');
    }
    List<double> point(String key) {
      final p = LottieParser._requiredMap(raw[key], path: '$path.$key');
      if (p['a'] == 1) throw DotdartUnsupportedFeatureException('$path.$key animates a gradient endpoint.');
      final xy = LottieParser._numberList(p['k'], path: '$path.$key.k');
      if (xy.length < 2 || xy.any((n) => !n.isFinite)) {
        throw DotdartInvalidLottieException('Expected a point at $path.$key.');
      }
      return xy;
    }

    final start = point('s');
    final end = point('e');
    if (start[0] == end[0] && start[1] == end[1]) {
      throw DotdartUnsupportedFeatureException('$path has coincident gradient endpoints.');
    }
    return (x: start[0], y: start[1], endX: end[0], endY: end[1], radial: raw['t'] == 2);
  }

  static ({List<double> stops, List<int> colors, List<double> rgb, List<double> alpha}) _gradient(
    List<double> values,
    int count,
    String path,
  ) {
    final offset = 4 * count;
    if (count > values.length ~/ 4 || (values.length - offset).isOdd) {
      throw DotdartInvalidLottieException('Invalid gradient stop data at $path.');
    }
    final rgb = [for (var i = 0; i < offset; i += 4) values[i]];
    final alpha = [for (var i = offset; i < values.length; i += 2) values[i]];
    for (final positions in [rgb, alpha]) {
      for (var i = 1; i < positions.length; i++) {
        if (positions[i] <= positions[i - 1]) {
          throw DotdartUnsupportedFeatureException('$path requires strictly increasing gradient stops.');
        }
      }
    }
    final stops = {...rgb, ...alpha}.toList()..sort();
    double sample(List<double> positions, int right, double stop, int base, int stride) {
      if (right == positions.length) return values[base + (right - 1) * stride];
      final upper = values[base + right * stride];
      if (right == 0 || positions[right] == stop) return upper;
      final lower = values[base + (right - 1) * stride];
      final fraction = (stop - positions[right - 1]) / (positions[right] - positions[right - 1]);
      return lower + (upper - lower) * fraction;
    }

    final colors = <int>[];
    var rgbIndex = 0;
    var opacityIndex = 0;
    for (final stop in stops) {
      while (rgbIndex < rgb.length && rgb[rgbIndex] < stop) {
        rgbIndex++;
      }
      while (opacityIndex < alpha.length && alpha[opacityIndex] < stop) {
        opacityIndex++;
      }
      colors.add(
        _argb(
          sample(rgb, rgbIndex, stop, 1, 4),
          sample(rgb, rgbIndex, stop, 2, 4),
          sample(rgb, rgbIndex, stop, 3, 4),
          alpha.isEmpty ? 1 : sample(alpha, opacityIndex, stop, offset + 1, 2),
        ),
      );
    }
    return (stops: stops, colors: colors, rgb: rgb, alpha: alpha);
  }

  static bool _sameStops(List<double> a, List<double> b) =>
      a.length == b.length && a.indexed.every((e) => e.$2 == b[e.$1]);
  static int _argb(double r, double g, double b, double a) =>
      (a * 255).round() << 24 | (r * 255).round() << 16 | (g * 255).round() << 8 | (b * 255).round();
}
