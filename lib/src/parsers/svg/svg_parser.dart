import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../models/svg_document.dart';
import '../../models/svg_drop_shadow.dart';
import '../../models/svg_element.dart';
import '../../models/svg_image_pattern.dart';
import '../../models/svg_linear_gradient.dart';
import '../../models/svg_radial_gradient.dart';
import '../../models/svg_style.dart';
import '../lottie_parser.dart' show DotdartUnsupportedFeatureException;
import 'svg_drop_shadow_parser.dart';
import 'svg_geometry_bounds.dart';
import 'svg_mini_xml.dart';
import 'svg_path_data.dart' show SvgPathData;
import 'svg_transform.dart' show SvgTransform;

/// Exception thrown when an SVG file is structurally invalid or malformed.
class DotdartInvalidSvgException implements FormatException {
  const DotdartInvalidSvgException(this.message);
  @override
  final String message;
  @override
  int? get offset => null;
  @override
  Object? get source => null;
  @override
  String toString() => 'DotdartInvalidSvgException: $message';
}

/// Result of parsing an SVG XML string.
class SvgParseResult {
  const SvgParseResult({required this.document, this.warnings = const []});
  final SvgDocument document;
  final List<String> warnings;
}

/// Parses SVG XML into a [SvgDocument] model.
///
/// Throws [DotdartUnsupportedFeatureException] for unsupported SVG features
/// (text, unsupported filters, etc.) and [DotdartInvalidSvgException] for
/// malformed SVG files.
class SvgParser {
  SvgParser._();
  final List<String> _warnings = [];
  final Map<String, SvgClipPath> _clipPaths = {};
  final Map<String, SvgDropShadow> _dropShadows = {};
  final Map<String, XElement> _definitions = {};
  final Set<XElement> _imageDefinitions = {};
  late final SvgViewBox _viewBox;
  final Map<String, SvgLinearGradient> _gradients = {};
  final Map<String, SvgRadialGradient> _radialGradients = {};
  final Map<String, SvgImagePattern> _patterns = {};
  final Map<String, (double, double, double, double)> _maskRegions = {};

  static SvgParseResult parse(String svgXml) {
    final parser = SvgParser._();
    return parser._parse(svgXml);
  }

  SvgParseResult _parse(String svgXml) {
    XElement root;
    try {
      root = XParser.parse(svgXml);
    } on FormatException catch (e) {
      throw DotdartInvalidSvgException('Failed to parse SVG XML: ${e.message}');
    }

    if (root.tag != 'svg') {
      throw const DotdartInvalidSvgException('Root element must be <svg>.');
    }
    _validateIds(root);
    _collectDefinitions(root);

    final viewBox = _viewBox = _parseViewBox(root);
    final width = _parseLength(root.attrs['width']);
    final height = _parseLength(root.attrs['height']);

    if (root.attrs.containsKey('filter')) {
      throw const DotdartUnsupportedFeatureException('Filters on the root SVG are not supported.');
    }
    final rootStyle = _resolveStyle(root, _defaultStyle);
    if (rootStyle.maskId != null) {
      throw const DotdartUnsupportedFeatureException('Masks on the root SVG are not supported.');
    }
    final children = _parseChildren(root, rootStyle);
    _validateClipPathRefs(children);
    _validatePaintFilters(children);
    _validateFilters(children, insideFilter: rootStyle.opacity != 1 || rootStyle.clipPathId != null);
    for (final clip in _clipPaths.values) {
      _validateFilters(clip.children, insideFilter: true);
    }

    final usedPaints = <String>{};
    _collectUsedPaints(children, usedPaints);
    _gradients.removeWhere((id, _) => !usedPaints.contains(id));
    _radialGradients.removeWhere((id, _) => !usedPaints.contains(id));
    _patterns.removeWhere((id, _) => !usedPaints.contains(id));
    return SvgParseResult(
      document: SvgDocument(
        viewBox: viewBox,
        width: width,
        height: height,
        children: children,
        clipPaths: Map.unmodifiable(_clipPaths),
        dropShadows: Map.unmodifiable(_dropShadows),
        gradients: Map.unmodifiable(_gradients),
        radialGradients: Map.unmodifiable(_radialGradients),
        patterns: Map.unmodifiable(_patterns),
        maskRegions: Map.unmodifiable(_maskRegions),
      ),
      warnings: List.unmodifiable(_warnings),
    );
  }

  SvgViewBox _parseViewBox(XElement svg) {
    final vb = svg.attrs['viewBox'];
    if (vb != null) {
      final parts = vb.trim().split(RegExp(r'[\s,]+'));
      if (parts.length >= 4) {
        final minX = double.tryParse(parts[0]) ?? 0;
        final minY = double.tryParse(parts[1]) ?? 0;
        final w = double.tryParse(parts[2]) ?? 0;
        final h = double.tryParse(parts[3]) ?? 0;
        if (w <= 0 || h <= 0) {
          throw const DotdartInvalidSvgException('viewBox must have positive width and height.');
        }
        return SvgViewBox(minX: minX, minY: minY, width: w, height: h);
      }
    }

    final w = _parseLength(svg.attrs['width']) ?? 300;
    final h = _parseLength(svg.attrs['height']) ?? 150;
    return SvgViewBox(minX: 0, minY: 0, width: w, height: h);
  }

  List<SvgElement> _parseChildren(XElement parent, [SvgStyle? inherited]) {
    final children = <SvgElement>[];
    for (final node in parent.children) {
      final element = _parseNode(node, inherited ?? _defaultStyle);
      if (element != null) children.add(element);
    }
    return children;
  }

  SvgElement? _parseNode(XElement element, SvgStyle inherited) {
    switch (element.tag) {
      case 'g':
        return _parseGroup(element, inherited);
      case 'path':
        return _parsePath(element, inherited);
      case 'rect':
        return _parseRect(element, inherited);
      case 'circle':
        return _parseCircle(element, inherited);
      case 'ellipse':
        return _parseEllipse(element, inherited);
      case 'line':
        return _parseLine(element, inherited);
      case 'polyline':
        return _parsePolyline(element, inherited);
      case 'polygon':
        return _parsePolygon(element, inherited);
      case 'defs':
        _parseDefs(element, inherited);
        return null;
      case 'clipPath':
        _parseClipPath(element, inherited);
        return null;
      case 'linearGradient':
        _parseGradient(element);
        return null;
      case 'radialGradient':
        _parseRadialGradient(element);
        return null;
      case 'use':
      case 'symbol':
        throw DotdartUnsupportedFeatureException(
          '<${element.tag}> references are not supported. Inline all shapes directly.',
        );
      case 'text':
      case 'tspan':
        throw const DotdartUnsupportedFeatureException('Text elements are not supported.');
      case 'image':
        if (_imageDefinitions.contains(element)) return null;
        throw const DotdartUnsupportedFeatureException('Embedded images are not supported.');
      case 'style':
        throw const DotdartUnsupportedFeatureException(
          'CSS <style> blocks are not supported. Use presentation attributes only.',
        );
      case 'filter':
        final id = element.attrs['id'];
        if (id == null) throw const DotdartInvalidSvgException('<filter> requires an id.');
        _dropShadows[id] = SvgDropShadowParser.parse(element);
        return null;
      case 'mask':
        _parseMask(element);
        return null;
      case 'pattern':
        _parsePattern(element);
        return null;
      case 'title':
      case 'desc':
      case 'metadata':
      case 'stop':
        return null;
      default:
        _warnings.add('Skipping unknown element "<${element.tag}>".');
        return null;
    }
  }

  SvgGroup _parseGroup(XElement element, SvgStyle inherited) {
    final style = _resolveStyle(element, inherited);
    final transform = _parseTransform(element);
    final children = _parseChildren(element, style);
    return SvgGroup(id: element.attrs['id'], style: style, transform: transform, children: children);
  }

  SvgPath _parsePath(XElement element, SvgStyle inherited) {
    final d = element.attrs['d'];
    if (d == null || d.trim().isEmpty) {
      throw const DotdartInvalidSvgException('<path> element is missing a "d" attribute.');
    }
    final commands = SvgPathData.parse(d);
    final style = _resolveStyle(element, inherited);
    return SvgPath(id: element.attrs['id'], style: style, transform: _parseTransform(element), commands: commands);
  }

  SvgRect _parseRect(XElement element, SvgStyle inherited) {
    final x = _parseLength(element.attrs['x']) ?? 0;
    final y = _parseLength(element.attrs['y']) ?? 0;
    final width = _parseLength(element.attrs['width']);
    final height = _parseLength(element.attrs['height']);
    if (width == null || height == null || width <= 0 || height <= 0) {
      throw const DotdartInvalidSvgException('<rect> requires positive width and height.');
    }
    final rx = _parseLength(element.attrs['rx']) ?? 0;
    final ry = _parseLength(element.attrs['ry']) ?? rx;
    final style = _resolveStyle(element, inherited);
    return SvgRect(
      id: element.attrs['id'],
      style: style,
      transform: _parseTransform(element),
      x: x,
      y: y,
      width: width,
      height: height,
      rx: rx,
      ry: ry,
    );
  }

  SvgCircle _parseCircle(XElement element, SvgStyle inherited) {
    final cx = _parseLength(element.attrs['cx']) ?? 0;
    final cy = _parseLength(element.attrs['cy']) ?? 0;
    final r = _parseLength(element.attrs['r']);
    if (r == null || r <= 0) throw const DotdartInvalidSvgException('<circle> requires positive r.');
    final style = _resolveStyle(element, inherited);
    return SvgCircle(id: element.attrs['id'], style: style, transform: _parseTransform(element), cx: cx, cy: cy, r: r);
  }

  SvgEllipse _parseEllipse(XElement element, SvgStyle inherited) {
    final cx = _parseLength(element.attrs['cx']) ?? 0;
    final cy = _parseLength(element.attrs['cy']) ?? 0;
    final rx = _parseLength(element.attrs['rx']);
    final ry = _parseLength(element.attrs['ry']);
    if (rx == null || ry == null || rx <= 0 || ry <= 0) {
      throw const DotdartInvalidSvgException('<ellipse> requires positive rx and ry.');
    }
    final style = _resolveStyle(element, inherited);
    return SvgEllipse(
      id: element.attrs['id'],
      style: style,
      transform: _parseTransform(element),
      cx: cx,
      cy: cy,
      rx: rx,
      ry: ry,
    );
  }

  SvgLine _parseLine(XElement element, SvgStyle inherited) {
    final x1 = _parseLength(element.attrs['x1']) ?? 0;
    final y1 = _parseLength(element.attrs['y1']) ?? 0;
    final x2 = _parseLength(element.attrs['x2']) ?? 0;
    final y2 = _parseLength(element.attrs['y2']) ?? 0;
    final lineStyle = SvgStyle(
      fillColor: null,
      strokeColor: inherited.strokeColor,
      strokeOpacity: inherited.strokeOpacity,
      strokeWidth: inherited.strokeWidth,
      strokeLineCap: inherited.strokeLineCap,
      strokeLineJoin: inherited.strokeLineJoin,
      fillRule: inherited.fillRule,
      opacity: inherited.opacity,
      fillOpacity: inherited.fillOpacity,
    );
    final style = _resolveStyle(element, lineStyle);
    return SvgLine(
      id: element.attrs['id'],
      style: style,
      transform: _parseTransform(element),
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
    );
  }

  SvgPolyline _parsePolyline(XElement element, SvgStyle inherited) {
    final points = _parsePoints(element.attrs['points']);
    if (points.isEmpty) throw const DotdartInvalidSvgException('<polyline> requires a "points" attribute.');
    final style = _resolveStyle(element, inherited);
    return SvgPolyline(id: element.attrs['id'], style: style, transform: _parseTransform(element), points: points);
  }

  SvgPolygon _parsePolygon(XElement element, SvgStyle inherited) {
    final points = _parsePoints(element.attrs['points']);
    if (points.isEmpty) throw const DotdartInvalidSvgException('<polygon> requires a "points" attribute.');
    final style = _resolveStyle(element, inherited);
    return SvgPolygon(id: element.attrs['id'], style: style, transform: _parseTransform(element), points: points);
  }

  void _validateMaskedContent(SvgElement element) {
    var target = element;
    while (target is SvgGroup) {
      if (target.children.length != 1) {
        throw const DotdartUnsupportedFeatureException(
          'Masked content must contain one filled shape without a stroke.',
        );
      }
      target = target.children.single;
    }
    if (target.style.strokeColor != null || (target.style.fillColor == null && target.style.fillServerId == null)) {
      throw const DotdartUnsupportedFeatureException('Masked content must contain one filled shape without a stroke.');
    }
  }

  void _validatePaintFilters(List<SvgElement> elements, {bool filtered = false}) {
    for (final element in elements) {
      if (element.style.maskId != null) _validateMaskedContent(element);
      final insideFilter = filtered || element.style.filterId != null;
      if (insideFilter && (element.style.fillServerId != null || element.style.maskId != null)) {
        throw const DotdartUnsupportedFeatureException(
          'Gradient fills, image patterns, and masks combined with drop shadows are not supported.',
        );
      }
      if (element is SvgGroup) {
        _validatePaintFilters(element.children, filtered: insideFilter);
        continue;
      }
      final pattern = _patterns[element.style.fillServerId];
      if (pattern != null) {
        final bounds = SvgGeometryBounds.of(element);
        if (![bounds.$1, bounds.$2, bounds.$3, bounds.$4].every((value) => value.isFinite)) {
          throw const DotdartInvalidSvgException('Image pattern geometry must be finite.');
        }
        final width = pattern.objectBoundingBox ? 1.0 : bounds.$3 - bounds.$1;
        final height = pattern.objectBoundingBox ? 1.0 : bounds.$4 - bounds.$2;
        final columns = width / pattern.width;
        final rows = height / pattern.height;
        if (!columns.isFinite || !rows.isFinite || (columns.ceil() + 1) * (rows.ceil() + 1) > 4096) {
          throw const DotdartUnsupportedFeatureException(
            'SVG image pattern exceeds 4096 visible tiles. Use a larger tile.',
          );
        }
      }
    }
  }

  void _collectUsedPaints(List<SvgElement> elements, Set<String> ids) {
    for (final element in elements) {
      if (element is SvgGroup) {
        _collectUsedPaints(element.children, ids);
      } else if (element.style.fillServerId case final id?) {
        ids.add(id);
      }
    }
  }

  void _collectDefinitions(XElement element, {bool insideDefs = false}) {
    if (element.attrs['id'] case final id?) _definitions[id] = element;
    if (insideDefs && element.tag == 'image') _imageDefinitions.add(element);
    for (final child in element.children) {
      _collectDefinitions(child, insideDefs: insideDefs || element.tag == 'defs');
    }
  }

  double _number(String? raw, {required double fallback}) {
    if (raw == null) return fallback;
    final value = raw.endsWith('%')
        ? (double.tryParse(raw.substring(0, raw.length - 1)) ?? double.nan) / 100
        : double.tryParse(raw);
    if (value == null || !value.isFinite) throw DotdartInvalidSvgException('Expected a finite SVG number: "$raw".');
    return value;
  }

  void _checkAttributes(XElement element, Set<String> allowed) {
    for (final name in element.attrs.keys) {
      if (!allowed.contains(name)) {
        throw DotdartUnsupportedFeatureException('Unsupported attribute "$name" on <${element.tag}>.');
      }
    }
  }

  String _definitionId(XElement element) {
    final id = element.attrs['id'];
    if (id == null) throw DotdartInvalidSvgException('<${element.tag}> requires an id.');
    return id;
  }

  String? _localRef(String? raw) {
    if (raw == null || raw.trim() == 'none') return null;
    final match = RegExp(r'^url\(#([^)]+)\)$').firstMatch(raw.trim());
    if (match == null) throw const DotdartUnsupportedFeatureException('SVG references must use url(#id).');
    return match.group(1)!;
  }

  String? _paintServerRef(String raw) {
    if (!raw.trim().startsWith('url(')) return null;
    final id = _localRef(raw)!;
    final definition = _definitions[id];
    if (definition == null) throw DotdartInvalidSvgException('SVG paint "$id" was not found.');
    switch (definition.tag) {
      case 'linearGradient':
        _parseGradient(definition);
      case 'radialGradient':
        _parseRadialGradient(definition);
      case 'pattern':
        _parsePattern(definition);
      default:
        throw DotdartUnsupportedFeatureException('Unsupported SVG paint <${definition.tag}>.');
    }
    return id;
  }

  void _parseGradient(XElement element) {
    final id = _definitionId(element);
    if (_gradients.containsKey(id)) return;
    _checkAttributes(element, {'id', 'x1', 'y1', 'x2', 'y2', 'gradientUnits', 'spreadMethod'});
    if (element.attrs['gradientUnits'] != 'userSpaceOnUse' || (element.attrs['spreadMethod'] ?? 'pad') != 'pad') {
      throw const DotdartUnsupportedFeatureException(
        'Linear gradients require gradientUnits="userSpaceOnUse" and spreadMethod="pad".',
      );
    }
    // Percentages in user space depend on the viewport, which this subset does not resolve.
    if (['x1', 'y1', 'x2', 'y2'].any((key) => element.attrs[key]?.contains('%') ?? false)) {
      throw const DotdartUnsupportedFeatureException('Linear gradient coordinates must use numbers, not percentages.');
    }
    final (:colors, :stops) = _parseGradientStops(element);
    _gradients[id] = SvgLinearGradient(
      x1: _number(element.attrs['x1'], fallback: 0),
      y1: _number(element.attrs['y1'], fallback: 0),
      x2: _number(element.attrs['x2'], fallback: _viewBox.width),
      y2: _number(element.attrs['y2'], fallback: 0),
      colors: colors,
      stops: stops,
    );
  }

  void _parseRadialGradient(XElement element) {
    final id = _definitionId(element);
    if (_radialGradients.containsKey(id)) return;
    _checkAttributes(element, {
      'id',
      'cx',
      'cy',
      'r',
      'fx',
      'fy',
      'fr',
      'gradientUnits',
      'spreadMethod',
      'gradientTransform',
    });
    if (element.attrs['gradientUnits'] != 'userSpaceOnUse' || (element.attrs['spreadMethod'] ?? 'pad') != 'pad') {
      throw const DotdartUnsupportedFeatureException(
        'Radial gradients require gradientUnits="userSpaceOnUse" and spreadMethod="pad".',
      );
    }
    if (['cx', 'cy', 'r'].any((key) => !element.attrs.containsKey(key)) ||
        ['cx', 'cy', 'r', 'fx', 'fy', 'fr'].any((key) => element.attrs[key]?.contains('%') ?? false)) {
      throw const DotdartUnsupportedFeatureException(
        'Radial gradients require explicit numeric cx, cy, and r coordinates; percentages are not supported.',
      );
    }
    final cx = _number(element.attrs['cx'], fallback: 0);
    final cy = _number(element.attrs['cy'], fallback: 0);
    final radius = _number(element.attrs['r'], fallback: 0);
    if (radius < 0) throw const DotdartInvalidSvgException('Radial gradient radius must not be negative.');
    if (_number(element.attrs['fx'], fallback: cx) != cx ||
        _number(element.attrs['fy'], fallback: cy) != cy ||
        _number(element.attrs['fr'], fallback: 0) != 0) {
      throw const DotdartUnsupportedFeatureException(
        'Radial gradients require a focal point at cx/cy and a zero focal radius.',
      );
    }
    SvgMatrix? transform;
    if (element.attrs['gradientTransform'] case final source?) {
      try {
        final matrix = SvgMatrix.compose(SvgTransform.parse(source));
        final determinant = matrix.a * matrix.d - matrix.b * matrix.c;
        if (!determinant.isFinite || determinant == 0) {
          throw const FormatException('Radial gradient transforms must be finite and invertible.');
        }
        if (matrix.a != 1 || matrix.b != 0 || matrix.c != 0 || matrix.d != 1 || matrix.e != 0 || matrix.f != 0) {
          transform = matrix;
        }
      } on FormatException catch (error) {
        throw DotdartInvalidSvgException('Invalid radial gradient transform: ${error.message}');
      }
    }
    final (:colors, :stops) = _parseGradientStops(element);
    _radialGradients[id] = SvgRadialGradient(
      cx: cx,
      cy: cy,
      radius: radius,
      colors: colors,
      stops: stops,
      transform: transform,
    );
  }

  ({List<(double, double, double, double)> colors, List<double> stops}) _parseGradientStops(XElement element) {
    final colors = <(double, double, double, double)>[];
    final stops = <double>[];
    for (final stop in element.children) {
      if (stop.tag != 'stop') {
        throw const DotdartUnsupportedFeatureException('SVG gradients may only contain stops.');
      }
      _checkAttributes(stop, {'offset', 'stop-color', 'stop-opacity'});
      final color = _parseColor(stop.attrs['stop-color'] ?? 'black');
      final rgba = color is _ConcreteColor
          ? color.value
          : color is _NoneColor
          ? (0.0, 0.0, 0.0, 0.0)
          : null;
      if (rgba == null) throw const DotdartUnsupportedFeatureException('Unsupported SVG gradient stop color.');
      final offset = _number(stop.attrs['offset'], fallback: 0).clamp(0.0, 1.0);
      stops.add(stops.isEmpty || offset >= stops.last ? offset : stops.last);
      colors.add((
        rgba.$1,
        rgba.$2,
        rgba.$3,
        rgba.$4 * _number(stop.attrs['stop-opacity'], fallback: 1).clamp(0.0, 1.0),
      ));
    }
    if (stops.isEmpty) throw const DotdartInvalidSvgException('SVG gradients require at least one stop.');
    return (colors: List.unmodifiable(colors), stops: List.unmodifiable(stops));
  }

  void _parsePattern(XElement element) {
    final id = _definitionId(element);
    if (_patterns.containsKey(id)) return;
    _checkAttributes(element, {'id', 'x', 'y', 'width', 'height', 'patternUnits', 'patternContentUnits'});
    final units = element.attrs['patternUnits'] ?? 'objectBoundingBox';
    final contentUnits = element.attrs['patternContentUnits'] ?? 'userSpaceOnUse';
    if (units != contentUnits ||
        (units != 'userSpaceOnUse' && units != 'objectBoundingBox') ||
        element.children.length != 1) {
      throw const DotdartUnsupportedFeatureException(
        'PNG patterns require matching patternUnits and patternContentUnits and one image or image reference.',
      );
    }
    var image = element.children.single;
    var matrix = const SvgMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0);
    if (image.tag == 'use') {
      _checkAttributes(image, {'href', 'transform'});
      final href = image.attrs['href'];
      if (href == null || !href.startsWith('#') || _definitions[href.substring(1)]?.tag != 'image') {
        throw const DotdartUnsupportedFeatureException('Pattern use must reference a local embedded image.');
      }
      matrix = SvgMatrix.compose(_parseTransform(image) ?? []);
      image = _definitions[href.substring(1)]!;
    }
    if (image.tag != 'image' || matrix.b != 0 || matrix.c != 0 || matrix.a <= 0 || matrix.d <= 0) {
      throw const DotdartUnsupportedFeatureException('PNG patterns support positive scale and translation only.');
    }
    _checkAttributes(image, {'id', 'href', 'x', 'y', 'width', 'height', 'preserveAspectRatio'});
    if (image.attrs['preserveAspectRatio'] != 'none') {
      throw const DotdartUnsupportedFeatureException('Pattern images require preserveAspectRatio="none".');
    }
    final href = image.attrs['href'] ?? '';
    if (href.length > 32 * 1024 * 1024) {
      throw const DotdartInvalidSvgException('Embedded PNG data must not exceed 32 MB.');
    }
    if (!href.startsWith('data:image/png;base64,')) {
      throw const DotdartUnsupportedFeatureException('Pattern images must be embedded base64 PNGs.');
    }
    Uint8List bytes;
    img.Image? decoded;
    try {
      bytes = base64Decode(href.substring('data:image/png;base64,'.length));
      final decoder = img.PngDecoder();
      final info = decoder.startDecode(bytes);
      if (info == null || info.width * info.height > 16777216 || info.numFrames != 1) {
        throw const FormatException('Expected a static PNG of at most 16 megapixels.');
      }
      decoded = decoder.decodeFrame(0);
    } on Object catch (error) {
      throw DotdartInvalidSvgException('Invalid embedded PNG: $error');
    }
    if (decoded == null) throw const DotdartInvalidSvgException('Invalid embedded PNG.');
    if (units == 'userSpaceOnUse' &&
        [...element.attrs.values, ...image.attrs.values].any((value) => value.contains('%'))) {
      throw const DotdartUnsupportedFeatureException('User-space pattern dimensions must use numbers.');
    }
    final width = _number(element.attrs['width'], fallback: 0);
    final height = _number(element.attrs['height'], fallback: 0);
    final imageWidth = _number(image.attrs['width'], fallback: 0) * matrix.a;
    final imageHeight = _number(image.attrs['height'], fallback: 0) * matrix.d;
    if (width <= 0 ||
        height <= 0 ||
        imageWidth <= 0 ||
        imageHeight <= 0 ||
        !imageWidth.isFinite ||
        !imageHeight.isFinite) {
      throw const DotdartInvalidSvgException('Pattern and image dimensions must be positive.');
    }
    _patterns[id] = SvgImagePattern(
      bytes: List.unmodifiable(bytes),
      pixelWidth: decoded.width,
      pixelHeight: decoded.height,
      x: _number(element.attrs['x'], fallback: 0),
      y: _number(element.attrs['y'], fallback: 0),
      width: width,
      height: height,
      imageX: _number(image.attrs['x'], fallback: 0) * matrix.a + matrix.e,
      imageY: _number(image.attrs['y'], fallback: 0) * matrix.d + matrix.f,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      objectBoundingBox: units == 'objectBoundingBox',
    );
  }

  String? _maskRef(String? raw) {
    final id = _localRef(raw);
    if (id == null) return null;
    final mask = _definitions[id];
    if (mask == null || mask.tag != 'mask') throw DotdartInvalidSvgException('SVG mask "$id" was not found.');
    _parseMask(mask);
    return id;
  }

  void _parseMask(XElement element) {
    final id = _definitionId(element);
    if (_maskRegions.containsKey(id)) return;
    _checkAttributes(element, {
      'id',
      'x',
      'y',
      'width',
      'height',
      'maskUnits',
      'maskContentUnits',
      'style',
      'mask-type',
    });
    if (element.attrs['maskUnits'] != 'userSpaceOnUse' ||
        (element.attrs['maskContentUnits'] ?? 'userSpaceOnUse') != 'userSpaceOnUse' ||
        !['luminance', 'alpha'].contains(element.attrs['mask-type'] ?? 'luminance') ||
        (element.attrs['style'] != null &&
            element.attrs['style']!.replaceAll(' ', '').replaceAll(';', '') != 'mask-type:luminance') ||
        element.children.length != 1 ||
        element.children.single.tag != 'path') {
      throw const DotdartUnsupportedFeatureException('Masks support one opaque white path in user space only.');
    }
    if (element.attrs.values.any((value) => value.contains('%'))) {
      throw const DotdartUnsupportedFeatureException('Mask regions must use numeric user coordinates.');
    }
    _checkAttributes(element.children.single, {
      'id',
      'd',
      'fill',
      'fill-rule',
      'clip-rule',
      'transform',
      'fill-opacity',
      'opacity',
      'stroke',
    });
    final path = _parsePath(element.children.single, _defaultStyle);
    if (path.style.fillColor != (1.0, 1.0, 1.0, 1.0) ||
        path.style.fillOpacity != 1 ||
        path.style.opacity != 1 ||
        path.style.strokeColor != null ||
        path.style.fillServerId != null ||
        path.style.filterId != null ||
        path.style.clipPathId != null ||
        path.style.maskId != null) {
      throw const DotdartUnsupportedFeatureException('Masks support one opaque white path only.');
    }
    final width = _number(element.attrs['width'], fallback: 0);
    final height = _number(element.attrs['height'], fallback: 0);
    if (width <= 0 || height <= 0) throw const DotdartInvalidSvgException('Mask dimensions must be positive.');
    _maskRegions[id] = (
      _number(element.attrs['x'], fallback: 0),
      _number(element.attrs['y'], fallback: 0),
      width,
      height,
    );
    _clipPaths[id] = SvgClipPath(id: id, children: [path], clipRule: path.style.fillRule);
  }

  void _validateIds(XElement root) {
    final ids = <String>{};

    void visit(XElement element) {
      final id = element.attrs['id'];
      if (id != null) {
        if (id.isEmpty) {
          throw const DotdartInvalidSvgException('SVG id must not be empty.');
        }
        if (!_isValidXmlName(id)) {
          throw DotdartInvalidSvgException('Invalid SVG id "$id". IDs must be valid XML names.');
        }
        if (!ids.add(id)) {
          throw DotdartInvalidSvgException('Duplicate SVG id "$id". IDs must be unique.');
        }
      }
      element.children.forEach(visit);
    }

    visit(root);
  }

  bool _isValidXmlName(String value) {
    final runes = value.runes.toList();
    if (runes.isEmpty || !_isXmlNameStartCharacter(runes.first)) return false;
    for (final rune in runes.skip(1)) {
      if (!_isXmlNameCharacter(rune)) return false;
    }
    return true;
  }

  bool _isXmlNameStartCharacter(int rune) {
    return rune == 0x3A ||
        rune == 0x5F ||
        (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0xC0 && rune <= 0xD6) ||
        (rune >= 0xD8 && rune <= 0xF6) ||
        (rune >= 0xF8 && rune <= 0x2FF) ||
        (rune >= 0x370 && rune <= 0x37D) ||
        (rune >= 0x37F && rune <= 0x1FFF) ||
        (rune >= 0x200C && rune <= 0x200D) ||
        (rune >= 0x2070 && rune <= 0x218F) ||
        (rune >= 0x2C00 && rune <= 0x2FEF) ||
        (rune >= 0x3001 && rune <= 0xD7FF) ||
        (rune >= 0xF900 && rune <= 0xFDCF) ||
        (rune >= 0xFDF0 && rune <= 0xFFFD) ||
        (rune >= 0x10000 && rune <= 0xEFFFF);
  }

  bool _isXmlNameCharacter(int rune) {
    return _isXmlNameStartCharacter(rune) ||
        rune == 0x2D ||
        rune == 0x2E ||
        rune == 0xB7 ||
        (rune >= 0x30 && rune <= 0x39) ||
        (rune >= 0x300 && rune <= 0x36F) ||
        (rune >= 0x203F && rune <= 0x2040);
  }

  static const _defaultStyle = SvgStyle(
    fillColor: (0, 0, 0, 1),
    fillOpacity: 1,
    fillRule: SvgFillRule.nonzero,
    strokeColor: null,
    strokeOpacity: 1,
    strokeWidth: 1,
    strokeLineCap: SvgStrokeLineCap.butt,
    strokeLineJoin: SvgStrokeLineJoin.miter,
    opacity: 1,
  );

  SvgStyle _resolveStyle(XElement element, SvgStyle inherited) {
    final fillRaw = element.attrs['fill'];
    final fillServerId = fillRaw == null ? inherited.fillServerId : _paintServerRef(fillRaw);
    final fillColor = fillRaw != null ? (fillServerId == null ? _parseColor(fillRaw) : _noneColor) : _inheritColor;
    if (element.attrs['stroke']?.trim().startsWith('url(') ?? false) {
      throw const DotdartUnsupportedFeatureException('Gradient and pattern strokes are not supported.');
    }
    final strokeRaw = element.attrs['stroke'];
    final strokeColor = strokeRaw != null ? _parseColor(strokeRaw) : _inheritColor;

    return SvgStyle(
      fillColor: fillColor is _ConcreteColor
          ? fillColor.value
          : fillColor is _NoneColor
          ? null
          : inherited.fillColor,
      fillOpacity: _parseOptionalOpacity(element.attrs['fill-opacity']) ?? inherited.fillOpacity,
      fillRule: _parseFillRule(element.attrs['fill-rule']) ?? inherited.fillRule,
      strokeColor: strokeColor is _ConcreteColor
          ? strokeColor.value
          : strokeColor is _NoneColor
          ? null
          : inherited.strokeColor,
      strokeOpacity: _parseOptionalOpacity(element.attrs['stroke-opacity']) ?? inherited.strokeOpacity,
      strokeWidth: _parseStrokeWidth(element) ?? inherited.strokeWidth,
      strokeLineCap: _parseLineCap(element.attrs['stroke-linecap']) ?? inherited.strokeLineCap,
      strokeLineJoin: _parseLineJoin(element.attrs['stroke-linejoin']) ?? inherited.strokeLineJoin,
      opacity: _parseOptionalOpacity(element.attrs['opacity']) ?? inherited.opacity,
      clipPathId: _parseClipPathRef(element.attrs['clip-path']),
      filterId: _parseFilterRef(element.attrs['filter']),
      fillServerId: fillServerId,
      maskId: _maskRef(element.attrs['mask']),
    );
  }

  // ── Color parsing ──

  _ColorValue _parseColor(String? raw) {
    if (raw == null) return _inheritColor;
    final trimmed = raw.trim();
    if (trimmed == 'none' || trimmed == 'transparent') return _noneColor;
    if (trimmed == 'currentColor') return const _ConcreteColor((0, 0, 0, 1));
    final named = _namedColor(trimmed);
    if (named != null) return _ConcreteColor(named);
    if (trimmed.startsWith('#')) return _parseHexColor(trimmed);
    if (trimmed.startsWith('rgb')) return _parseRgbColor(trimmed);
    if (trimmed.startsWith('url(')) throw const DotdartUnsupportedFeatureException('Unsupported SVG paint reference.');
    return _inheritColor;
  }

  _ColorValue _parseHexColor(String raw) {
    final hex = raw.substring(1);
    if (hex.length == 3) {
      final r = int.parse(hex[0] + hex[0], radix: 16);
      final g = int.parse(hex[1] + hex[1], radix: 16);
      final b = int.parse(hex[2] + hex[2], radix: 16);
      return _ConcreteColor(_toColor(r, g, b, 255));
    }
    if (hex.length == 4) {
      final r = int.parse(hex[0] + hex[0], radix: 16);
      final g = int.parse(hex[1] + hex[1], radix: 16);
      final b = int.parse(hex[2] + hex[2], radix: 16);
      final a = int.parse(hex[3] + hex[3], radix: 16);
      return _ConcreteColor(_toColor(r, g, b, a));
    }
    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return _ConcreteColor(_toColor(r, g, b, 255));
    }
    if (hex.length == 8) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      final a = int.parse(hex.substring(6, 8), radix: 16);
      return _ConcreteColor(_toColor(r, g, b, a));
    }
    return _inheritColor;
  }

  _ColorValue _parseRgbColor(String raw) {
    final inner = raw.substring(raw.indexOf('(') + 1, raw.lastIndexOf(')')).trim();
    final parts = inner.split(RegExp(r'[\s,]+'));
    if (parts.length < 3) return _ConcreteColor(_toColor(0, 0, 0, 255));
    int parseComponent(String s) {
      if (s.endsWith('%')) return ((double.parse(s.substring(0, s.length - 1)) / 100) * 255).round().clamp(0, 255);
      return int.tryParse(s) ?? 0;
    }

    final r = parseComponent(parts[0]);
    final g = parseComponent(parts[1]);
    final b = parseComponent(parts[2]);
    var a = 255;
    if (parts.length > 3) {
      final alphaStr = parts[3];
      if (alphaStr.endsWith('%')) {
        a = ((double.parse(alphaStr.substring(0, alphaStr.length - 1)) / 100) * 255).round().clamp(0, 255);
      } else {
        a = (double.parse(alphaStr) * 255).round().clamp(0, 255);
      }
    }
    return _ConcreteColor(_toColor(r, g, b, a));
  }

  (double, double, double, double) _toColor(int r, int g, int b, int a) => (r / 255, g / 255, b / 255, a / 255);

  (double, double, double, double)? _namedColor(String name) => _namedColors[name.toLowerCase()];

  static const _namedColors = <String, (double, double, double, double)>{
    'black': (0, 0, 0, 1),
    'white': (1, 1, 1, 1),
    'red': (1, 0, 0, 1),
    'green': (0, 0.50196078, 0, 1),
    'blue': (0, 0, 1, 1),
    'yellow': (1, 1, 0, 1),
    'gray': (0.50196078, 0.50196078, 0.50196078, 1),
    'grey': (0.50196078, 0.50196078, 0.50196078, 1),
    'silver': (0.75294118, 0.75294118, 0.75294118, 1),
    'maroon': (0.50196078, 0, 0, 1),
    'purple': (0.50196078, 0, 0.50196078, 1),
    'fuchsia': (1, 0, 1, 1),
    'lime': (0, 1, 0, 1),
    'olive': (0.50196078, 0.50196078, 0, 1),
    'navy': (0, 0, 0.50196078, 1),
    'teal': (0, 0.50196078, 0.50196078, 1),
    'aqua': (0, 1, 1, 1),
    'orange': (1, 0.64705882, 0, 1),
    'pink': (1, 0.75294118, 0.79607843, 1),
  };

  double? _parseOptionalOpacity(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.endsWith('%')) {
      final value = double.tryParse(trimmed.substring(0, trimmed.length - 1))?.clamp(0, 100) ?? 0;
      return value / 100;
    }
    return double.tryParse(trimmed)?.clamp(0, 1);
  }

  SvgFillRule? _parseFillRule(String? raw) {
    if (raw == null) return null;
    return switch (raw.trim()) {
      'evenodd' => SvgFillRule.evenodd,
      _ => SvgFillRule.nonzero,
    };
  }

  SvgStrokeLineCap? _parseLineCap(String? raw) {
    if (raw == null) return null;
    return switch (raw.trim()) {
      'round' => SvgStrokeLineCap.round,
      'square' => SvgStrokeLineCap.square,
      _ => SvgStrokeLineCap.butt,
    };
  }

  SvgStrokeLineJoin? _parseLineJoin(String? raw) {
    if (raw == null) return null;
    return switch (raw.trim()) {
      'round' => SvgStrokeLineJoin.round,
      'bevel' => SvgStrokeLineJoin.bevel,
      _ => SvgStrokeLineJoin.miter,
    };
  }

  double? _parseStrokeWidth(XElement element) {
    final raw = element.attrs['stroke-width'];
    if (raw == null) return null;
    return _parseLength(raw) ?? double.tryParse(raw.trim());
  }

  List<SvgTransformOp>? _parseTransform(XElement element) {
    final raw = element.attrs['transform'];
    if (raw == null || raw.trim().isEmpty) return null;
    return SvgTransform.parse(raw);
  }

  double? _parseLength(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    final match = RegExp(r'^([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)').firstMatch(trimmed);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  List<(double, double)> _parsePoints(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    final tokens = raw.trim().split(RegExp(r'[\s,]+'));
    final points = <(double, double)>[];
    for (var i = 0; i + 1 < tokens.length; i += 2) {
      final x = double.tryParse(tokens[i]);
      final y = double.tryParse(tokens[i + 1]);
      if (x != null && y != null) points.add((x, y));
    }
    return points;
  }

  // ── Clip path support ──

  void _parseDefs(XElement element, SvgStyle inherited) {
    for (final child in element.children) {
      _parseNode(child, inherited);
    }
  }

  void _parseClipPath(XElement element, SvgStyle inherited) {
    final id = element.attrs['id'];
    if (id == null || id.isEmpty) {
      throw const DotdartInvalidSvgException('<clipPath> requires a non-empty "id" attribute.');
    }
    final clipRule = _parseFillRule(element.attrs['clip-rule']) ?? SvgFillRule.nonzero;
    final children = <SvgElement>[];
    for (final child in element.children) {
      final parsed = _parseNode(child, inherited);
      if (parsed != null) children.add(parsed);
    }
    if (children.isEmpty) {
      throw DotdartInvalidSvgException('<clipPath id="$id"> must contain at least one shape.');
    }
    _clipPaths[id] = SvgClipPath(id: id, children: children, clipRule: clipRule);
  }

  String? _parseFilterRef(String? raw) {
    if (raw == null || raw.trim() == 'none') return null;
    final match = RegExp(r'^url\(#([^)]+)\)$').firstMatch(raw.trim());
    if (match == null) {
      throw const DotdartUnsupportedFeatureException('SVG filters must reference a local filter with url(#id).');
    }
    return match.group(1);
  }

  void _validateFilters(List<SvgElement> elements, {bool insideFilter = false}) {
    for (final element in elements) {
      final ref = element.style.filterId;
      if (ref != null) {
        if (!_dropShadows.containsKey(ref)) {
          throw DotdartInvalidSvgException('Filter reference "$ref" not found.');
        }
        if (insideFilter || element.style.opacity != 1 || element.style.clipPathId != null) {
          throw const DotdartUnsupportedFeatureException(
            'Nested filters, filters inside clip paths, and clipping or opacity on filtered elements or their ancestors are not supported.',
          );
        }
      }
      if (element is SvgGroup) {
        _validateFilters(
          element.children,
          insideFilter: insideFilter || ref != null || element.style.clipPathId != null || element.style.opacity != 1,
        );
      }
    }
  }

  String? _parseClipPathRef(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'url\(#([^)]+)\)').firstMatch(raw.trim());
    return match?.group(1);
  }

  void _validateClipPathRefs(List<SvgElement> elements) {
    for (final element in elements) {
      final ref = element.style.clipPathId;
      if (ref != null && !_clipPaths.containsKey(ref)) {
        _warnings.add('clip-path reference "$ref" not found; clipping will be ignored.');
      }
      if (element is SvgGroup) _validateClipPathRefs(element.children);
    }
  }
}

/// Internal tri-state color value used during style resolution.
sealed class _ColorValue {
  const _ColorValue();
}

/// Explicitly set to `"none"` — no paint.
final class _NoneColor extends _ColorValue {
  const _NoneColor();
}

/// A concrete RGBA color value.
final class _ConcreteColor extends _ColorValue {
  const _ConcreteColor(this.value);
  final (double, double, double, double) value;
}

/// Not specified — inherit from parent.
final class _InheritColor extends _ColorValue {
  const _InheritColor();
}

const _noneColor = _NoneColor();
const _inheritColor = _InheritColor();
