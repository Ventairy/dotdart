import '../../models/svg_drop_shadow.dart';
import '../lottie_parser.dart' show DotdartUnsupportedFeatureException;
import 'svg_mini_xml.dart';

/// Recognizes the single outer-shadow chain exported by vector editors.
///
/// This deliberately validates inputs and attributes rather than treating
/// arbitrary filter graphs as equivalent shadows.
class SvgDropShadowParser {
  SvgDropShadowParser._();

  static SvgDropShadow parse(XElement filter) {
    _attributes(filter, {
      'id',
      'x',
      'y',
      'width',
      'height',
      'filterUnits',
      'primitiveUnits',
      'color-interpolation-filters',
    });
    if (filter.attrs['filterUnits'] != 'userSpaceOnUse' ||
        (filter.attrs['primitiveUnits'] ?? 'userSpaceOnUse') != 'userSpaceOnUse' ||
        filter.attrs['color-interpolation-filters'] != 'sRGB') {
      _unsupported();
    }
    final nodes = filter.children;
    const tags = [
      'feFlood',
      'feColorMatrix',
      'feOffset',
      'feGaussianBlur',
      'feComposite',
      'feColorMatrix',
      'feBlend',
      'feBlend',
    ];
    if (nodes.length != tags.length) _unsupported();
    for (var i = 0; i < tags.length; i++) {
      if (nodes[i].tag != tags[i] || nodes[i].children.isNotEmpty) _unsupported();
    }
    _attributes(nodes[0], {'flood-opacity', 'result'});
    if (_number(nodes[0], 'flood-opacity') != 0) _unsupported();
    _attributes(nodes[1], {'in', 'type', 'values', 'result'});
    if (nodes[1].attrs['in'] != 'SourceAlpha') _unsupported();
    final alpha = _matrix(nodes[1]);
    for (var i = 0; i < 20; i++) {
      if (i != 18 && alpha[i] != 0) _unsupported();
    }
    if (alpha[18] < 0) _unsupported();
    _attributes(nodes[2], {'in', 'dx', 'dy', 'result'});
    _input(nodes[2], nodes[1]);
    _attributes(nodes[3], {'in', 'stdDeviation', 'result'});
    _input(nodes[3], nodes[2]);
    final sigma = _number(nodes[3], 'stdDeviation');
    if (sigma < 0) _unsupported();
    _attributes(nodes[4], {'in', 'in2', 'operator', 'result'});
    _input(nodes[4], nodes[3]);
    if (nodes[4].attrs['operator'] != 'out' || nodes[4].attrs['in2'] != _result(nodes[1])) _unsupported();
    _attributes(nodes[5], {'in', 'type', 'values', 'result'});
    _input(nodes[5], nodes[4]);
    final color = _matrix(nodes[5]);
    for (var i = 0; i < 20; i++) {
      if ({4, 9, 14, 18}.contains(i)) {
        if (color[i] < 0 || color[i] > 1) _unsupported();
      } else if (color[i] != 0) {
        _unsupported();
      }
    }
    _attributes(nodes[6], {'in', 'in2', 'mode', 'result'});
    _input(nodes[6], nodes[5]);
    if (nodes[6].attrs['mode'] != 'normal' || nodes[6].attrs['in2'] != _result(nodes[0])) _unsupported();
    _attributes(nodes[7], {'in', 'in2', 'mode', 'result'});
    if (nodes[7].attrs['mode'] != 'normal' ||
        nodes[7].attrs['in'] != 'SourceGraphic' ||
        nodes[7].attrs['in2'] != _result(nodes[6])) {
      _unsupported();
    }
    final results = <String>{};
    for (final node in nodes) {
      final result = node.attrs['result'];
      if (result != null &&
          (result.isEmpty || {'SourceGraphic', 'SourceAlpha'}.contains(result) || !results.add(result))) {
        _unsupported();
      }
    }
    final width = _number(filter, 'width');
    final height = _number(filter, 'height');
    if (width <= 0 ||
        height <= 0 ||
        !(_number(filter, 'x') + width).isFinite ||
        !(_number(filter, 'y') + height).isFinite) {
      _unsupported();
    }
    return SvgDropShadow(
      x: _number(filter, 'x'),
      y: _number(filter, 'y'),
      width: width,
      height: height,
      dx: _number(nodes[2], 'dx', fallback: 0),
      dy: _number(nodes[2], 'dy', fallback: 0),
      sigma: sigma,
      alphaScale: alpha[18],
      color: (color[4], color[9], color[14], color[18]),
    );
  }

  static void _attributes(XElement node, Set<String> allowed) {
    if (node.attrs.keys.any((key) => !allowed.contains(key))) _unsupported();
  }

  static double _number(XElement node, String name, {double? fallback}) {
    final raw = node.attrs[name];
    final value = raw == null ? fallback : double.tryParse(raw);
    if (value == null || !value.isFinite) _unsupported();
    return value;
  }

  static List<double> _matrix(XElement node) {
    if (node.attrs['type'] != 'matrix') _unsupported();
    final parts = (node.attrs['values'] ?? '').trim().split(RegExp(r'[\s,]+'));
    final values = parts.map(double.tryParse).toList();
    if (values.length != 20 || values.any((value) => value == null || !value.isFinite)) _unsupported();
    return values.cast<double>();
  }

  static String _result(XElement node) {
    final result = node.attrs['result'];
    if (result == null || result.isEmpty) _unsupported();
    return result;
  }

  static void _input(XElement node, XElement previous) {
    final input = node.attrs['in'];
    if (input != null && input != _result(previous)) _unsupported();
  }

  static Never _unsupported() => throw const DotdartUnsupportedFeatureException(
    'Unsupported SVG filter. Only the single exported outer drop-shadow chain '
    '(flood, alpha matrix, offset, blur, out composite, color matrix, two normal blends) '
    'with an explicit userSpaceOnUse region and sRGB colors is supported.',
  );
}
