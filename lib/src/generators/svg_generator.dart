// StringBuffer.writeln returns void. Cascading void calls is valid Dart but
// makes the code harder to read. This is a known false positive.
// ignore_for_file: cascade_invocations, prefer_adjacent_string_concatenation

import '../models/svg_document.dart';
import '../models/svg_element.dart';
import '../models/svg_style.dart';
import '../parsers/svg/svg_path_bounds.dart';
import 'accessor_param.dart';
import 'naming.dart';

/// Generates a self-contained Dart `StatelessWidget` + `CustomPainter` from
/// a parsed [SvgDocument].
class SvgGenerator {
  SvgGenerator(this.document, this.sourcePath);

  static final RegExp _identifierWord = RegExp(r'[A-Z]+(?=[A-Z][a-z]|[0-9]|$)|[A-Z]?[a-z]+|[0-9]+');

  final SvgDocument document;
  final String sourcePath;
  final Map<SvgElement, String> _geometryFields = {};
  final Map<SvgGroup, String> _maskedPatternFields = {};
  late final Map<SvgElement, SvgMatrix> _patternTransforms = _buildPatternTransforms();

  /// Whether generated widgets decode embedded PNG patterns.
  bool get requiresEmbeddedImages => document.patterns.isNotEmpty;

  /// Whether generated matrix fields require Dart typed data.
  bool get requiresTypedData =>
      requiresEmbeddedImages ||
      _containsMatrix(document.children) ||
      document.clipPaths.values.any((clip) => _containsMatrix(clip.children));

  bool _containsMatrix(List<SvgElement> elements) => elements.any(
    (element) =>
        (element.transform?.any((op) => op is SvgMatrix) ?? false) ||
        (element is SvgGroup && _containsMatrix(element.children)),
  );

  /// Whether the compiled shadows use Flutter image filters.
  bool get requiresImageFilter => document.dropShadows.isNotEmpty;

  String _matrixLiteral(List<SvgTransformOp> transforms) {
    final matrix = SvgMatrix.compose(transforms);
    return 'Float64List.fromList([${matrix.storage.map((value) => value == 0 ? '0.0' : value.toString()).join(', ')}])';
  }

  void _emitTransformFields(StringBuffer b, List<SvgElement> elements, Map<SvgElement, String> fields) {
    for (final element in elements) {
      final transforms = element.transform;
      if (transforms != null && transforms.any((op) => op is SvgMatrix)) {
        final name = '_transform${fields.length}';
        fields[element] = name;
        b.writeln('  static final Float64List $name = ${_matrixLiteral(transforms)};');
      }
      if (element is SvgGroup) _emitTransformFields(b, element.children, fields);
    }
  }

  /// Returns the constructor parameters of the generated SVG widget.
  ///
  /// Used by `NamespaceAssembler` to emit matching accessor methods.
  List<AccessorParam> get params => _paramsFor(_buildColorPlan().colors);

  List<AccessorParam> _paramsFor(List<_ColorEntry> colors) {
    final result = <AccessorParam>[
      const AccessorParam(name: 'key', type: 'Key?'),
      const AccessorParam(name: 'width', type: 'double?', documentation: 'Width in logical pixels.'),
      const AccessorParam(name: 'height', type: 'double?', documentation: 'Height in logical pixels.'),
      const AccessorParam(
        name: 'maintainAspectRatio',
        type: 'bool',
        defaultValue: 'true',
        documentation:
            'When true (default), keeps the native aspect ratio using the larger '
            'requested value as the reference. When false, both dimensions are applied as-is and '
            'the asset may distort.',
      ),
    ];
    for (final color in colors) {
      final sourceDescription = color.sourceId == null
          ? 'Color ${color.name.substring('color'.length)}'
          : 'Color from SVG id `${color.sourceId}`';
      result.add(
        AccessorParam(
          name: color.name,
          type: 'Color?',
          documentation: '$sourceDescription — defaults to ${_colorToHex(color.r, color.g, color.b, color.a)}.',
        ),
      );
    }
    return result;
  }

  /// Generates the widget class (and painter) source fragment (no header/imports).
  ///
  /// The returned string is not Dart-formatted — the caller (`NamespaceAssembler`)
  /// formats the combined file.
  String generateWidgetClass() {
    final b = StringBuffer();
    _geometryFields.clear();
    _maskedPatternFields.clear();
    final colorPlan = _buildColorPlan();
    _writeWidgetClass(b, colorPlan.colors);
    _writePainterClass(b, colorPlan);
    return b.toString();
  }

  String get widgetClassName => '_${Naming.widgetClassName(sourcePath)}';

  /// The PascalCase name without the private `_` prefix — used for inner classes.
  String get _baseName => Naming.widgetClassName(sourcePath);

  // ── Color extraction ──

  ({List<_ColorEntry> colors, Map<SvgElement, ({int? fill, int? stroke})> colorsByElement}) _buildColorPlan() {
    final colors = <_ColorEntry>[];
    final colorIndexByScopeAndValue = <(String?, String), int>{};
    final colorsByElement = <SvgElement, ({int? fill, int? stroke})>{};

    int? add((double, double, double, double)? color, String? sourceId) {
      if (color == null) return null;
      final key = (sourceId, _colorKey(color));
      final existing = colorIndexByScopeAndValue[key];
      if (existing != null) return existing;
      final index = colors.length;
      final (r, g, b, a) = color;
      colors.add(_ColorEntry(name: '', sourceId: sourceId, r: r, g: g, b: b, a: a));
      colorIndexByScopeAndValue[key] = index;
      return index;
    }

    void walk(List<SvgElement> elements, String? ancestorGroupId) {
      for (final element in elements) {
        if (element case SvgGroup(:final children)) {
          walk(children, element.id ?? ancestorGroupId);
          continue;
        }
        final sourceId = element.id ?? ancestorGroupId;
        colorsByElement[element] = (
          fill: add(element.style.fillColor, sourceId),
          stroke: add(element.style.strokeColor, sourceId),
        );
      }
    }

    walk(document.children, null);

    final countBySourceId = <String, int>{};
    for (final color in colors) {
      final sourceId = color.sourceId;
      if (sourceId != null) countBySourceId.update(sourceId, (count) => count + 1, ifAbsent: () => 1);
    }
    final ordinalBySourceId = <String, int>{};
    final usedNames = {'key', 'width', 'height', 'maintainAspectRatio'};
    var anonymousOrdinal = 0;
    final namedColors = <_ColorEntry>[];
    for (final color in colors) {
      final sourceId = color.sourceId;
      String proposedName;
      if (sourceId == null) {
        anonymousOrdinal++;
        proposedName = 'color$anonymousOrdinal';
      } else {
        final ordinal = ordinalBySourceId.update(sourceId, (value) => value + 1, ifAbsent: () => 1);
        final base = _semanticColorBase(sourceId);
        proposedName = countBySourceId[sourceId] == 1 ? base : '$base$ordinal';
      }
      var name = proposedName;
      var suffix = 2;
      while (!usedNames.add(name)) {
        name = '$proposedName$suffix';
        suffix++;
      }
      namedColors.add(color.withName(name));
    }
    return (colors: namedColors, colorsByElement: colorsByElement);
  }

  String _semanticColorBase(String id) {
    final words = _identifierWord.allMatches(id).map((match) => match.group(0)!).toList();
    if (words.isEmpty || RegExp('^[0-9]').hasMatch(words.first)) {
      return 'svgIdColor';
    }
    final identifier =
        words.first.toLowerCase() +
        words.skip(1).map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}').join();
    return identifier.toLowerCase().endsWith('color') ? identifier : '${identifier}Color';
  }

  // ── Widget class ──

  void _writeWidgetClass(StringBuffer b, List<_ColorEntry> colors) {
    final name = widgetClassName;
    b.writeln('/// A dotdart-generated SVG widget from `$sourcePath`.');
    b.writeln('///');
    b.writeln('/// Renders a ${document.viewBox.width}×${document.viewBox.height} SVG');
    b.writeln(
      '/// on a viewBox of ${document.viewBox.minX} ${document.viewBox.minY} '
      '${document.viewBox.width} ${document.viewBox.height}.',
    );
    b.writeln('/// No flutter_svg runtime dependency — drawn entirely via [CustomPainter].');
    b.writeln('class $name extends StatelessWidget with _DotdartSvgSizing {');
    b.writeln('  const $name({');
    final widgetParams = _paramsFor(colors);
    for (final param in widgetParams) {
      b.writeln('    ${param.constructorInitializer},');
    }

    b.writeln('  });');
    b.writeln();
    b.writeln('  static const double _svgWidth = ${_fmt(document.nativeWidth)};');
    b.writeln('  static const double _svgHeight = ${_fmt(document.nativeHeight)};');
    b.writeln('  static const double _viewBoxMinX = ${_fmt(document.viewBox.minX)};');
    b.writeln('  static const double _viewBoxMinY = ${_fmt(document.viewBox.minY)};');
    b.writeln('  static const double _viewBoxWidth = ${_fmt(document.viewBox.width)};');
    b.writeln('  static const double _viewBoxHeight = ${_fmt(document.viewBox.height)};');
    b.writeln();
    for (final param in widgetParams) {
      final fieldDeclaration = param.fieldDeclaration;
      if (fieldDeclaration == null) continue;
      b.write(fieldDeclaration);
      b.writeln();
    }

    b.writeln('  @override');
    b.writeln('  double? get svgWidgetWidth => width;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  double? get svgWidgetHeight => height;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  bool get svgMaintainAspectRatio => maintainAspectRatio;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  double get svgNativeWidth => $name._svgWidth;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  double get svgNativeHeight => $name._svgHeight;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  double get svgViewBoxWidth => $name._viewBoxWidth;');
    b.writeln();
    b.writeln('  @override');
    b.writeln('  double get svgViewBoxHeight => $name._viewBoxHeight;');
    b.writeln();

    b.writeln('  @override');
    b.writeln('  Widget buildPainter({required double width, required double height}) {');
    final painterName = _baseName;
    if (requiresEmbeddedImages) {
      b.writeln('    return Builder(builder: (context) {');
      b.writeln('      final ratio = MediaQuery.devicePixelRatioOf(context);');
      b.writeln('      return _DotdartSvgImages(patterns: _${painterName}Painter._patternDefinitions, providers: [');
      var index = 0;
      for (final entry in document.patterns.entries) {
        final pattern = entry.value;
        final twoAxis = _patternNeedsTwoAxisSizing(entry.key);
        final width = twoAxis
            ? '_${painterName}Painter._decodeWidth$index(scaleX: width / _viewBoxWidth, scaleY: height / _viewBoxHeight)'
            : 'width / _viewBoxWidth * _${painterName}Painter._decodeWidth$index';
        final height = twoAxis
            ? '_${painterName}Painter._decodeHeight$index(scaleX: width / _viewBoxWidth, scaleY: height / _viewBoxHeight)'
            : 'height / _viewBoxHeight * _${painterName}Painter._decodeHeight$index';
        b.writeln(
          '        ResizeImage(_${painterName}Painter._image$index, width: math.min(${pattern.pixelWidth}, math.max(1, ($width * ratio).ceil())), height: math.min(${pattern.pixelHeight}, math.max(1, ($height * ratio).ceil()))),',
        );
        index++;
      }
      b.writeln('      ], builder: (images) => SizedBox.fromSize(');
    } else {
      b.writeln('    return SizedBox.fromSize(');
    }
    b.writeln('      size: Size(width, height),');
    b.writeln('      child: RepaintBoundary(');
    b.writeln('        child: CustomPaint(');
    if (colors.isNotEmpty || requiresEmbeddedImages) {
      b.writeln('          painter: _$painterName' + 'Painter(');
      for (final color in colors) {
        final hex = _colorToHex(color.r, color.g, color.b, color.a);
        b.writeln('            ${color.name}: ${color.name} ?? const Color($hex),');
      }
      if (requiresEmbeddedImages) b.writeln('            images: images,');
      b.writeln('          ),');
    } else {
      b.writeln('          painter: _$painterName' + 'Painter(),');
    }
    b.writeln('          size: Size(width, height),');
    b.writeln('        ),');
    b.writeln('      ),');
    b.writeln(requiresEmbeddedImages ? '    ));});' : '    );');
    b.writeln('  }');
    b.writeln('}');
    b.writeln();
  }

  // ── Painter class ──

  void _writePainterClass(
    StringBuffer b,
    ({List<_ColorEntry> colors, Map<SvgElement, ({int? fill, int? stroke})> colorsByElement}) colorPlan,
  ) {
    final name = _baseName;
    final colors = colorPlan.colors;

    b.writeln('class _$name' + 'Painter extends CustomPainter {');
    if (colors.isNotEmpty || requiresEmbeddedImages) {
      b.writeln('  _$name' + 'Painter({');
      if (requiresEmbeddedImages) b.writeln('    required this.images,');
      for (final color in colors) {
        b.writeln('    required this.${color.name},');
      }
      b.writeln('  });');
    } else {
      b.writeln('  _$name' + 'Painter();');
    }
    b.writeln();

    for (final color in colors) {
      b.writeln('  final Color ${color.name};');
    }
    if (requiresEmbeddedImages) b.writeln('  final List<_DotdartSvgDecodedImage?> images;');
    if (colors.isNotEmpty) b.writeln();
    if (_usesFill(document.children)) {
      b.writeln('  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;');
    }
    if (_usesStroke(document.children)) {
      b.writeln('  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;');
    }
    b.writeln();

    _emitShadowFields(b);

    // ── Geometry emission (walk, emit static fields) ──

    final transformFields = <SvgElement, String>{};
    _emitTransformFields(b, document.children, transformFields);

    var pathIdx = 0;
    var rrectIdx = 0;
    var ellipseRectIdx = 0;
    var lineIdx = 0;
    var polyIdx = 0;
    final geometryFieldByElement = _geometryFields;

    void emitGeometry(List<SvgElement> elements) {
      for (final element in elements) {
        switch (element) {
          case final SvgPath element:
            final SvgPath(:commands, :style) = element;
            _emitPathField(b, pathIdx, commands, style.fillRule);
            geometryFieldByElement[element] = '__path$pathIdx';
            pathIdx++;
          case final SvgRect element:
            final SvgRect(:x, :y, :width, :height, :rx, :ry) = element;
            _emitRectField(b, rrectIdx, x, y, width, height, rx, ry);
            geometryFieldByElement[element] = rx > 0 || ry > 0 ? '_rrect$rrectIdx' : '_rect$rrectIdx';
            rrectIdx++;
          case final SvgCircle element:
            final SvgCircle(:cx, :cy, :r) = element;
            b.writeln(
              '  static final Rect _ellipseRect$ellipseRectIdx = Rect.fromCircle(center: const Offset(${_fmt(cx)}, ${_fmt(cy)}), radius: ${_fmt(r)});',
            );
            b.writeln();
            geometryFieldByElement[element] = '_ellipseRect$ellipseRectIdx';
            ellipseRectIdx++;
          case final SvgEllipse element:
            final SvgEllipse(:cx, :cy, :rx, :ry) = element;
            b.writeln(
              '  static final Rect _ellipseRect$ellipseRectIdx = Rect.fromCenter(center: const Offset(${_fmt(cx)}, ${_fmt(cy)}), width: ${_fmt(rx * 2)}, height: ${_fmt(ry * 2)});',
            );
            b.writeln();
            geometryFieldByElement[element] = '_ellipseRect$ellipseRectIdx';
            ellipseRectIdx++;
          case final SvgLine l:
            _emitLineField(b, lineIdx, l);
            geometryFieldByElement[l] = '__linePath$lineIdx';
            lineIdx++;
          case final SvgPolyline element:
            final SvgPolyline(:points) = element;
            _emitPolyPathField(b, polyIdx, points, false);
            geometryFieldByElement[element] = '__polyPath$polyIdx';
            polyIdx++;
          case final SvgPolygon element:
            final SvgPolygon(:points) = element;
            _emitPolyPathField(b, polyIdx, points, true);
            geometryFieldByElement[element] = '__polyPath$polyIdx';
            polyIdx++;
          case SvgGroup(:final children):
            emitGeometry(children); // recurse — groups don't have their own geometry
        }
      }
    }

    emitGeometry(document.children);

    // ── Clip path geometry emission ──

    var clipIdx = 0;
    final clipPathFieldNames = <String, String>{};
    for (final entry in document.clipPaths.entries) {
      final fieldName = '__clip$clipIdx';
      clipPathFieldNames[entry.key] = fieldName;
      _emitClipPathField(b, clipIdx, entry.value);
      clipIdx++;
    }

    _emitMaskedPatternFields(b, document.children, clipPathFieldNames);
    _emitPaintServerFields(b);

    // ── Paint method ──

    final widgetName = widgetClassName;
    b.writeln('  @override');
    b.writeln('  void paint(Canvas canvas, Size size) {');
    b.writeln('    final scaleX = size.width / $widgetName._viewBoxWidth;');
    b.writeln('    final scaleY = size.height / $widgetName._viewBoxHeight;');
    b.writeln('    canvas');
    b.writeln('      ..save()');
    b.writeln('      ..scale(scaleX, scaleY)');
    b.writeln('      ..translate(-$widgetName._viewBoxMinX, -$widgetName._viewBoxMinY);');
    b.writeln();

    _emitDrawCalls(
      b,
      document.children,
      colors,
      colorPlan.colorsByElement,
      geometryFieldByElement,
      clipPathFieldNames,
      transformFields,
    );

    b.writeln('    canvas.restore();');
    b.writeln('  }');
    b.writeln();

    // ── shouldRepaint ──

    b.writeln('  @override');
    b.writeln('  bool shouldRepaint(covariant _$name' + 'Painter oldDelegate) {');
    if (colors.isNotEmpty || requiresEmbeddedImages) {
      b.writeln('    return');
      if (requiresEmbeddedImages) {
        b.writeln('        !identical(images, oldDelegate.images) ${colors.isEmpty ? '' : '||'}');
      }
      for (var i = 0; i < colors.length; i++) {
        final color = colors[i];
        if (i > 0) b.writeln('        ||');
        b.writeln('        oldDelegate.${color.name} != ${color.name}');
      }
      b.writeln(';');
    } else {
      b.writeln('    return false;');
    }
    b.writeln('  }');
    b.writeln();
    b.writeln('}');
    b.writeln();
  }

  // ── Draw call emission ──

  void _emitDrawCalls(
    StringBuffer b,
    List<SvgElement> elements,
    List<_ColorEntry> colors,
    Map<SvgElement, ({int? fill, int? stroke})> colorsByElement,
    Map<SvgElement, String> geometryFieldByElement,
    Map<String, String> clipPathFieldNames,
    Map<SvgElement, String> transformFields,
  ) {
    for (final element in elements) {
      switch (element) {
        case SvgGroup(:final children):
          _emitScopedDraw(
            b,
            element,
            () => _emitDrawCalls(
              b,
              children,
              colors,
              colorsByElement,
              geometryFieldByElement,
              clipPathFieldNames,
              transformFields,
            ),
            clipPathFieldNames,
            transformFields,
          );
        case SvgPath(:final style):
          _emitScopedDraw(
            b,
            element,
            () => _emitPathDraw(b, style, geometryFieldByElement[element]!, colors, colorsByElement[element]!),
            clipPathFieldNames,
            transformFields,
          );
        case SvgRect(:final style, :final rx, :final ry):
          _emitScopedDraw(
            b,
            element,
            () => _emitRectDraw(
              b,
              style,
              geometryFieldByElement[element]!,
              colors,
              colorsByElement[element]!,
              rx > 0 || ry > 0,
            ),
            clipPathFieldNames,
            transformFields,
          );
        case SvgCircle(:final style):
        case SvgEllipse(:final style):
          _emitScopedDraw(
            b,
            element,
            () => _emitEllipseDraw(b, style, geometryFieldByElement[element]!, colors, colorsByElement[element]!),
            clipPathFieldNames,
            transformFields,
          );
        case SvgLine(:final style):
          _emitScopedDraw(
            b,
            element,
            () => _emitLineDraw(b, style, geometryFieldByElement[element]!, colors, colorsByElement[element]!),
            clipPathFieldNames,
            transformFields,
          );
        case SvgPolyline(:final style):
        case SvgPolygon(:final style):
          _emitScopedDraw(
            b,
            element,
            () => _emitPolyDraw(b, style, geometryFieldByElement[element]!, colors, colorsByElement[element]!),
            clipPathFieldNames,
            transformFields,
          );
      }
    }
  }

  void _emitScopedDraw(
    StringBuffer b,
    SvgElement element,
    void Function() emitDraw,
    Map<String, String> clipPathFieldNames,
    Map<SvgElement, String> transformFields,
  ) {
    final transform = element.transform;
    final hasTransform = transform != null && transform.isNotEmpty;
    final clipField = clipPathFieldNames[element.style.clipPathId];
    final hasClip = clipField != null;
    final maskField = clipPathFieldNames[element.style.maskId];
    final maskedPatternField = element is SvgGroup ? _maskedPatternFields[element] : null;
    final hasScope =
        hasTransform || hasClip || element.style.filterId != null || (maskField != null && maskedPatternField == null);
    if (hasScope) b.writeln('    canvas.save();');
    final matrixField = transformFields[element];
    if (matrixField != null) {
      b.writeln('    canvas.transform($matrixField);');
    } else {
      _emitCanvasTransforms(b, transform ?? []);
    }
    if (hasClip) {
      b.writeln('    canvas.clipPath($clipField);');
    }
    if (maskedPatternField != null) {
      final child = (element as SvgGroup).children.single;
      final index = document.patterns.keys.toList().indexOf(child.style.fillServerId!);
      final opacity = _fmt(child.style.fillOpacity * child.style.opacity);
      b.writeln(
        '    if (images[$index]?.shaderPaint(${_patternField(index: index, element: child)}) case final maskedPaint?) {',
      );
      b.writeln(
        '      canvas.drawPath($maskedPatternField, maskedPaint..color = const Color.from(alpha: $opacity, red: 1, green: 1, blue: 1));',
      );
      b.writeln('    } else {');
      if (!hasScope) b.writeln('      canvas.save();');
    }
    if (maskField != null) {
      final region = document.maskRegions[element.style.maskId]!;
      b.writeln(
        '    canvas.clipRect(const Rect.fromLTWH(${_literal(region.$1)}, ${_literal(region.$2)}, ${_literal(region.$3)}, ${_literal(region.$4)}));',
      );
      b.writeln('    canvas.clipPath($maskField);');
    }
    final serverId = element.style.fillServerId;
    if (serverId != null && element is! SvgGroup && element.style.opacity > 0 && element.style.fillOpacity > 0) {
      _emitServerDraw(b, element, serverId);
    }
    final filterId = element.style.filterId;
    if (filterId != null) {
      _emitShadow(b, filterId, emitDraw);
    } else {
      emitDraw();
    }
    if (maskedPatternField != null) {
      if (!hasScope) b.writeln('      canvas.restore();');
      b.writeln('    }');
    }
    if (hasScope) b.writeln('    canvas.restore();');
  }

  SvgElement? _maskedPatternChild(SvgGroup group) {
    if (group.style.maskId == null || group.style.filterId != null || group.children.length != 1) return null;
    final child = group.children.single;
    if (child is! SvgPath && child is! SvgRect) return null;
    if ((child.transform?.isNotEmpty ?? false) ||
        child.style.clipPathId != null ||
        child.style.filterId != null ||
        child.style.maskId != null ||
        child.style.strokeColor != null ||
        !document.patterns.containsKey(child.style.fillServerId) ||
        child.style.fillOpacity <= 0 ||
        child.style.opacity <= 0) {
      return null;
    }
    return child;
  }

  void _emitMaskedPatternFields(StringBuffer b, List<SvgElement> elements, Map<String, String> clipFields) {
    for (final element in elements) {
      if (element is! SvgGroup) continue;
      final child = _maskedPatternChild(element);
      final mask = element.style.maskId;
      final clip = clipFields[mask];
      final region = document.maskRegions[mask];
      if (child != null && clip != null && region != null) {
        final field = '_maskedPattern${_maskedPatternFields.length}';
        _maskedPatternFields[element] = field;
        final target = switch (child) {
          SvgPath() => _geometryFields[child]!,
          SvgRect(:final rx, :final ry) =>
            '(Path()..${rx > 0 || ry > 0 ? 'addRRect' : 'addRect'}(${_geometryFields[child]}))',
          SvgCircle() ||
          SvgEllipse() ||
          SvgLine() ||
          SvgPolyline() ||
          SvgPolygon() ||
          SvgGroup() => throw StateError('Unsupported masked pattern geometry.'),
        };
        b.writeln(
          '  static final Path $field = Path.combine(PathOperation.intersect, Path.combine(PathOperation.intersect, $clip, $target), Path()..addRect(const Rect.fromLTWH(${_literal(region.$1)}, ${_literal(region.$2)}, ${_literal(region.$3)}, ${_literal(region.$4)})));',
        );
      }
      _emitMaskedPatternFields(b, element.children, clipFields);
    }
  }

  void _emitShadowFields(StringBuffer b) {
    var index = 0;
    for (final shadow in document.dropShadows.values) {
      final (r, g, blue, a) = shadow.color;
      b.writeln(
        '  static const Rect _shadowBounds$index = Rect.fromLTWH('
        '${shadow.x}, ${shadow.y}, ${shadow.width}, ${shadow.height});',
      );
      b.writeln(
        '  final Paint _shadowColor$index = Paint()..colorFilter = '
        'const ColorFilter.matrix([0, 0, 0, 0, ${r * 255}, '
        '0, 0, 0, 0, ${g * 255}, 0, 0, 0, 0, ${blue * 255}, '
        '0, 0, 0, $a, 0]);',
      );
      b.writeln(
        '  final Paint _shadowBlur$index = Paint()..imageFilter = '
        'ImageFilter.blur(sigmaX: ${shadow.sigma}, sigmaY: ${shadow.sigma}, tileMode: TileMode.decal);',
      );
      final alphaMatrix =
          '[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
          '0, 0, 0, 0, 0, 0, 0, 0, ${shadow.alphaScale}, 0]';
      b.writeln(
        '  final Paint _shadowAlpha$index = Paint()..colorFilter = '
        'const ColorFilter.matrix($alphaMatrix);',
      );
      b.writeln(
        '  final Paint _shadowOut$index = Paint() '
        '..blendMode = BlendMode.dstOut..colorFilter = const ColorFilter.matrix($alphaMatrix);',
      );
      index++;
    }
  }

  void _emitShadow(StringBuffer b, String id, void Function() emitDraw) {
    final index = document.dropShadows.keys.toList().indexOf(id);
    final shadow = document.dropShadows[id]!;
    final bounds = '_shadowBounds$index';
    // Bound all offscreen work to the declared filter region. The alpha layer
    // is needed before blur, and dstOut must not erase the surrounding canvas.
    b.writeln('    canvas.clipRect($bounds);');
    b.writeln('    canvas.saveLayer($bounds, _shadowColor$index);');
    b.writeln('    canvas.saveLayer($bounds, _shadowBlur$index);');
    b.writeln('    canvas.translate(${_fmt(shadow.dx)}, ${_fmt(shadow.dy)});');
    b.writeln('    canvas.clipRect($bounds);');
    b.writeln('    canvas.saveLayer($bounds, _shadowAlpha$index);');
    emitDraw();
    b.writeln('    canvas.restore();');
    b.writeln('    canvas.restore();');
    b.writeln('    canvas.saveLayer($bounds, _shadowOut$index);');
    emitDraw();
    b.writeln('    canvas.restore();');
    b.writeln('    canvas.restore();');
    emitDraw();
  }

  void _emitCanvasTransforms(StringBuffer b, List<SvgTransformOp> transforms) {
    for (final op in transforms) {
      switch (op) {
        case SvgMatrix():
          throw StateError('Matrix transforms must be emitted as cached fields.');
        case SvgTranslate(:final tx, :final ty):
          b.writeln('    canvas.translate(${_fmt(tx)}, ${_fmt(ty)});');
        case SvgScale(:final sx, :final sy):
          b.writeln('    canvas.scale(${_fmt(sx)}, ${_fmt(sy)});');
        case SvgRotate(:final angle, :final cx, :final cy):
          if (cx != null && cy != null) {
            b.writeln(
              '    canvas..translate(${_fmt(cx)}, ${_fmt(cy)})..rotate(${_fmt(angle)} * math.pi / 180)..translate(${_fmt(-cx)}, ${_fmt(-cy)});',
            );
          } else {
            b.writeln('    canvas.rotate(${_fmt(angle)} * math.pi / 180);');
          }
      }
    }
  }

  void _emitPathDraw(
    StringBuffer b,
    SvgStyle style,
    String fieldName,
    List<_ColorEntry> colors,
    ({int? fill, int? stroke}) colorIndices,
  ) {
    final hasFill = style.fillColor != null && style.fillOpacity > 0 && style.opacity > 0;
    final hasStroke = style.strokeColor != null && style.strokeOpacity > 0 && style.opacity > 0;
    if (!hasFill && !hasStroke) return;

    if (hasFill) {
      final opacity = _fmt(style.fillOpacity * style.opacity);
      b.writeln(
        '    canvas.drawPath($fieldName, ${_colorRef(colors[colorIndices.fill!].name, opacity, '_fillPaint')});',
      );
    }
    if (hasStroke) {
      final opacity = _fmt(style.strokeOpacity * style.opacity);
      final cap = _lineCap(style.strokeLineCap);
      final join = _lineJoin(style.strokeLineJoin);
      b.writeln(
        '    canvas.drawPath($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
      );
    }
  }

  void _emitRectDraw(
    StringBuffer b,
    SvgStyle style,
    String fieldName,
    List<_ColorEntry> colors,
    ({int? fill, int? stroke}) colorIndices,
    bool rounded,
  ) {
    final hasFill = style.fillColor != null && style.fillOpacity > 0 && style.opacity > 0;
    final hasStroke = style.strokeColor != null && style.strokeOpacity > 0 && style.opacity > 0;
    if (!hasFill && !hasStroke) return;

    if (hasFill) {
      final opacity = _fmt(style.fillOpacity * style.opacity);
      if (rounded) {
        b.writeln(
          '    canvas.drawRRect($fieldName, ${_colorRef(colors[colorIndices.fill!].name, opacity, '_fillPaint')});',
        );
      } else {
        b.writeln(
          '    canvas.drawRect($fieldName, ${_colorRef(colors[colorIndices.fill!].name, opacity, '_fillPaint')});',
        );
      }
    }
    if (hasStroke) {
      final opacity = _fmt(style.strokeOpacity * style.opacity);
      final cap = _lineCap(style.strokeLineCap);
      final join = _lineJoin(style.strokeLineJoin);
      if (rounded) {
        b.writeln(
          '    canvas.drawRRect($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
        );
      } else {
        b.writeln(
          '    canvas.drawRect($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
        );
      }
    }
  }

  void _emitEllipseDraw(
    StringBuffer b,
    SvgStyle style,
    String fieldName,
    List<_ColorEntry> colors,
    ({int? fill, int? stroke}) colorIndices,
  ) {
    final hasFill = style.fillColor != null && style.fillOpacity > 0 && style.opacity > 0;
    final hasStroke = style.strokeColor != null && style.strokeOpacity > 0 && style.opacity > 0;
    if (!hasFill && !hasStroke) return;

    if (hasFill) {
      final opacity = _fmt(style.fillOpacity * style.opacity);
      b.writeln(
        '    canvas.drawOval($fieldName, ${_colorRef(colors[colorIndices.fill!].name, opacity, '_fillPaint')});',
      );
    }
    if (hasStroke) {
      final opacity = _fmt(style.strokeOpacity * style.opacity);
      final cap = _lineCap(style.strokeLineCap);
      final join = _lineJoin(style.strokeLineJoin);
      b.writeln(
        '    canvas.drawOval($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
      );
    }
  }

  void _emitLineDraw(
    StringBuffer b,
    SvgStyle style,
    String fieldName,
    List<_ColorEntry> colors,
    ({int? fill, int? stroke}) colorIndices,
  ) {
    if (style.strokeColor == null || style.strokeOpacity <= 0 || style.opacity <= 0) return;
    final opacity = _fmt(style.strokeOpacity * style.opacity);
    final cap = _lineCap(style.strokeLineCap);
    final join = _lineJoin(style.strokeLineJoin);
    b.writeln(
      '    canvas.drawPath($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
    );
  }

  void _emitPolyDraw(
    StringBuffer b,
    SvgStyle style,
    String fieldName,
    List<_ColorEntry> colors,
    ({int? fill, int? stroke}) colorIndices,
  ) {
    final hasFill = style.fillColor != null && style.fillOpacity > 0 && style.opacity > 0;
    final hasStroke = style.strokeColor != null && style.strokeOpacity > 0 && style.opacity > 0;
    if (!hasFill && !hasStroke) return;

    if (hasFill) {
      final opacity = _fmt(style.fillOpacity * style.opacity);
      b.writeln(
        '    canvas.drawPath($fieldName, ${_colorRef(colors[colorIndices.fill!].name, opacity, '_fillPaint')});',
      );
    }
    if (hasStroke) {
      final opacity = _fmt(style.strokeOpacity * style.opacity);
      final cap = _lineCap(style.strokeLineCap);
      final join = _lineJoin(style.strokeLineJoin);
      b.writeln(
        '    canvas.drawPath($fieldName, ${_strokeColorRef(colors[colorIndices.stroke!].name, opacity, style.strokeWidth, cap, join)});',
      );
    }
  }

  // ── Field emission helpers ──

  void _emitPathField(StringBuffer b, int idx, List<SvgPathCommand> commands, SvgFillRule fillRule) {
    b.writeln('  static final Path __path$idx = Path()');
    if (fillRule == SvgFillRule.evenodd) {
      b.writeln('    ..fillType = PathFillType.evenOdd');
    }
    for (final cmd in commands) {
      switch (cmd) {
        case SvgMoveTo(:final x, :final y):
          b.writeln('    ..moveTo(${_fmt(x)}, ${_fmt(y)})');
        case SvgLineTo(:final x, :final y):
          b.writeln('    ..lineTo(${_fmt(x)}, ${_fmt(y)})');
        case SvgCubicTo(:final x1, :final y1, :final x2, :final y2, :final x, :final y):
          b.writeln('    ..cubicTo(${_fmt(x1)}, ${_fmt(y1)}, ${_fmt(x2)}, ${_fmt(y2)}, ${_fmt(x)}, ${_fmt(y)})');
        case SvgQuadTo(:final x1, :final y1, :final x, :final y):
          b.writeln('    ..quadraticBezierTo(${_fmt(x1)}, ${_fmt(y1)}, ${_fmt(x)}, ${_fmt(y)})');
        case SvgArcTo():
          b.writeln('    ..${_arcCall(cmd)}');
        case SvgClosePath():
          b.writeln('    ..close()');
      }
    }
    b.writeln('  ;');
    b.writeln();
  }

  void _emitRectField(StringBuffer b, int idx, double x, double y, double w, double h, double rx, double ry) {
    if (rx > 0 || ry > 0) {
      b.writeln('  static final RRect _rrect$idx = RRect.fromRectAndRadius(');
      b.writeln('    const Rect.fromLTWH(${_fmt(x)}, ${_fmt(y)}, ${_fmt(w)}, ${_fmt(h)}),');
      b.writeln('    const Radius.circular(${_fmt(rx > ry ? rx : ry)}),');
      b.writeln('  );');
    } else {
      b.writeln('  static const Rect _rect$idx =');
      b.writeln('      Rect.fromLTWH(${_fmt(x)}, ${_fmt(y)}, ${_fmt(w)}, ${_fmt(h)});');
    }
    b.writeln();
  }

  void _emitLineField(StringBuffer b, int idx, SvgLine line) {
    b.writeln('  static final Path __linePath$idx = Path()');
    b.writeln('    ..moveTo(${_fmt(line.x1)}, ${_fmt(line.y1)})');
    b.writeln('    ..lineTo(${_fmt(line.x2)}, ${_fmt(line.y2)})');
    b.writeln('  ;');
    b.writeln();
  }

  void _emitPolyPathField(StringBuffer b, int idx, List<(double, double)> points, bool close) {
    b.writeln('  static final Path __polyPath$idx = Path()');
    for (var i = 0; i < points.length; i++) {
      final (x, y) = points[i];
      if (i == 0) {
        b.writeln('    ..moveTo(${_fmt(x)}, ${_fmt(y)})');
      } else {
        b.writeln('    ..lineTo(${_fmt(x)}, ${_fmt(y)})');
      }
    }
    if (close) b.writeln('    ..close()');
    b.writeln('  ;');
    b.writeln();
  }

  // ── Clip path field emission ──

  void _emitClipPathField(StringBuffer b, int idx, SvgClipPath clipPath) {
    if (_hasTransforms(clipPath.children)) {
      b.writeln('  static final Path __clip$idx = _buildClip$idx();');
      b.writeln();
      b.writeln('  static Path _buildClip$idx() {');
      b.writeln('    final path = Path();');
      if (clipPath.clipRule == SvgFillRule.evenodd) {
        b.writeln('    path.fillType = PathFillType.evenOdd;');
      }
      _emitTransformedClipPathShapes(b, clipPath.children, const [], 0);
      b.writeln('    return path;');
      b.writeln('  }');
      b.writeln();
      return;
    }
    b.writeln('  static final Path __clip$idx = Path()');
    if (clipPath.clipRule == SvgFillRule.evenodd) {
      b.writeln('    ..fillType = PathFillType.evenOdd');
    }
    _emitClipPathShapes(b, clipPath.children);
    b.writeln('  ;');
    b.writeln();
  }

  bool _hasTransforms(List<SvgElement> elements) {
    for (final element in elements) {
      if (element.transform case final transform? when transform.isNotEmpty) return true;
      if (element case SvgGroup(:final children)) {
        if (_hasTransforms(children)) return true;
      }
    }
    return false;
  }

  int _emitTransformedClipPathShapes(
    StringBuffer b,
    List<SvgElement> shapes,
    List<SvgTransformOp> inheritedTransforms,
    int shapeIndex,
  ) {
    var nextShapeIndex = shapeIndex;
    for (final shape in shapes) {
      final transforms = [...inheritedTransforms, ...?shape.transform];
      if (shape case SvgGroup(:final children)) {
        nextShapeIndex = _emitTransformedClipPathShapes(b, children, transforms, nextShapeIndex);
        continue;
      }
      final localName = 'clipShape$nextShapeIndex';
      b.writeln('    final $localName = Path()');
      _emitClipPathShapes(b, [shape], cascadePrefix: '      ..', argumentIndent: '        ');
      b.writeln('    ;');
      b.writeln('    path.addPath(');
      b.writeln('      $localName,');
      b.writeln('      Offset.zero,');
      if (transforms.any((op) => op is SvgMatrix)) {
        b.writeln('      matrix4: ${_matrixLiteral(transforms)},');
      } else if (transforms.isNotEmpty) {
        b.writeln('      matrix4: (Matrix4.identity()');
        _emitMatrixTransforms(b, transforms);
        b.writeln('          ).storage,');
      }
      b.writeln('    );');
      nextShapeIndex++;
    }
    return nextShapeIndex;
  }

  void _emitMatrixTransforms(StringBuffer b, List<SvgTransformOp> transforms) {
    for (final transform in transforms) {
      switch (transform) {
        case SvgMatrix():
          throw StateError('Matrix transforms must be composed at build time.');
        case SvgTranslate(:final tx, :final ty):
          b.writeln('        ..translateByDouble(${_fmt(tx)}, ${_fmt(ty)}, 0, 1)');
        case SvgScale(:final sx, :final sy):
          b.writeln('        ..scaleByDouble(${_fmt(sx)}, ${_fmt(sy)}, 1, 1)');
        case SvgRotate(:final angle, :final cx, :final cy):
          if (cx != null && cy != null) {
            b.writeln('        ..translateByDouble(${_fmt(cx)}, ${_fmt(cy)}, 0, 1)');
            b.writeln('        ..rotateZ(${_fmt(angle)} * math.pi / 180)');
            b.writeln('        ..translateByDouble(${_fmt(-cx)}, ${_fmt(-cy)}, 0, 1)');
          } else {
            b.writeln('        ..rotateZ(${_fmt(angle)} * math.pi / 180)');
          }
      }
    }
  }

  void _emitClipPathShapes(
    StringBuffer b,
    List<SvgElement> shapes, {
    String cascadePrefix = '    ..',
    String argumentIndent = '      ',
  }) {
    for (final shape in shapes) {
      switch (shape) {
        case SvgPath(:final commands):
          for (final cmd in commands) {
            switch (cmd) {
              case SvgMoveTo(:final x, :final y):
                b.writeln('${cascadePrefix}moveTo(${_fmt(x)}, ${_fmt(y)})');
              case SvgLineTo(:final x, :final y):
                b.writeln('${cascadePrefix}lineTo(${_fmt(x)}, ${_fmt(y)})');
              case SvgCubicTo(:final x1, :final y1, :final x2, :final y2, :final x, :final y):
                b.writeln(
                  '${cascadePrefix}cubicTo(${_fmt(x1)}, ${_fmt(y1)}, ${_fmt(x2)}, ${_fmt(y2)}, ${_fmt(x)}, ${_fmt(y)})',
                );
              case SvgQuadTo(:final x1, :final y1, :final x, :final y):
                b.writeln('${cascadePrefix}quadraticBezierTo(${_fmt(x1)}, ${_fmt(y1)}, ${_fmt(x)}, ${_fmt(y)})');
              case SvgArcTo():
                b.writeln('$cascadePrefix${_arcCall(cmd)}');
              case SvgClosePath():
                b.writeln('${cascadePrefix}close()');
            }
          }
        case SvgRect(:final x, :final y, :final width, :final height, :final rx, :final ry):
          if (rx > 0 || ry > 0) {
            b.writeln('${cascadePrefix}addRRect(RRect.fromRectAndRadius(');
            b.writeln('$argumentIndent  const Rect.fromLTWH(${_fmt(x)}, ${_fmt(y)}, ${_fmt(width)}, ${_fmt(height)}),');
            b.writeln('$argumentIndent  const Radius.circular(${_fmt(rx > ry ? rx : ry)}),');
            b.writeln('$argumentIndent))');
          } else {
            b.writeln(
              '${cascadePrefix}addRect(const Rect.fromLTWH(${_fmt(x)}, ${_fmt(y)}, ${_fmt(width)}, ${_fmt(height)}))',
            );
          }
        case SvgCircle(:final cx, :final cy, :final r):
          b.writeln(
            '${cascadePrefix}addOval(Rect.fromCircle(center: const Offset(${_fmt(cx)}, ${_fmt(cy)}), radius: ${_fmt(r)}))',
          );
        case SvgEllipse(:final cx, :final cy, :final rx, :final ry):
          b.writeln(
            '${cascadePrefix}addOval(Rect.fromCenter(center: const Offset(${_fmt(cx)}, ${_fmt(cy)}), width: ${_fmt(rx * 2)}, height: ${_fmt(ry * 2)}))',
          );
        case SvgLine():
          break;
        case SvgPolyline(:final points):
          for (var i = 0; i < points.length; i++) {
            final (px, py) = points[i];
            if (i == 0) {
              b.writeln('${cascadePrefix}moveTo(${_fmt(px)}, ${_fmt(py)})');
            } else {
              b.writeln('${cascadePrefix}lineTo(${_fmt(px)}, ${_fmt(py)})');
            }
          }
        case SvgPolygon(:final points):
          for (var i = 0; i < points.length; i++) {
            final (px, py) = points[i];
            if (i == 0) {
              b.writeln('${cascadePrefix}moveTo(${_fmt(px)}, ${_fmt(py)})');
            } else {
              b.writeln('${cascadePrefix}lineTo(${_fmt(px)}, ${_fmt(py)})');
            }
          }
          b.writeln('${cascadePrefix}close()');
        case SvgGroup(:final children):
          _emitClipPathShapes(b, children, cascadePrefix: cascadePrefix, argumentIndent: argumentIndent);
      }
    }
  }

  String _literal(double value) =>
      value == value.roundToDouble() && value.abs() < 1e10 ? value.toInt().toString() : value.toString();

  String _patternField({required int index, required SvgElement element}) =>
      '_pattern${index}Geometry${_geometryFields.keys.toList().indexOf(element)}';

  String _alignmentLiteral({required double x, required double y}) {
    final name = switch ((x, y)) {
      (-1, -1) => 'topLeft',
      (0, -1) => 'topCenter',
      (1, -1) => 'topRight',
      (-1, 0) => 'centerLeft',
      (0, 0) => 'center',
      (1, 0) => 'centerRight',
      (-1, 1) => 'bottomLeft',
      (0, 1) => 'bottomCenter',
      (1, 1) => 'bottomRight',
      _ => null,
    };
    return name == null ? 'Alignment(${_literal(x)}, ${_literal(y)})' : 'Alignment.$name';
  }

  String _arcCall(SvgArcTo arc) =>
      'arcToPoint(const Offset(${_literal(arc.x)}, ${_literal(arc.y)}), radius: const Radius.elliptical(${_literal(arc.rx)}, ${_literal(arc.ry)}), rotation: ${_literal(arc.rotation)}, largeArc: ${arc.largeArc}, clockwise: ${arc.clockwise})';

  String _boundsExpression(SvgElement element, {bool exactPathBounds = false}) {
    if (exactPathBounds &&
        element is SvgPath &&
        element.commands.any((command) => command is SvgCubicTo || command is SvgQuadTo || command is SvgArcTo)) {
      final bounds = SvgPathBounds.calculate(element);
      return 'const Rect.fromLTWH(${_literal(bounds.left)}, ${_literal(bounds.top)}, ${_literal(bounds.width)}, ${_literal(bounds.height)})';
    }
    final field = _geometryFields[element]!;
    return switch (element) {
      SvgPath() || SvgPolygon() || SvgPolyline() || SvgLine() => '$field.getBounds()',
      SvgRect(:final rx, :final ry) => rx > 0 || ry > 0 ? '$field.outerRect' : field,
      SvgCircle() || SvgEllipse() => field,
      SvgGroup() => throw StateError('Groups do not own geometry.'),
    };
  }

  void _emitPaintServerFields(StringBuffer b) {
    var index = 0;
    for (final gradient in document.gradients.values) {
      final colors = gradient.colors
          .map((color) => 'Color(${_colorToHex(color.$1, color.$2, color.$3, color.$4)})')
          .join(', ');
      if (gradient.colors.length == 1 || (gradient.x1 == gradient.x2 && gradient.y1 == gradient.y2)) {
        final color = gradient.colors.last;
        b.writeln(
          '  static final Paint _gradient$index = Paint()..color = const Color(${_colorToHex(color.$1, color.$2, color.$3, color.$4)});',
        );
      } else {
        b.writeln(
          '  static final Paint _gradient$index = Paint()..shader = const LinearGradient(begin: ${_alignmentLiteral(x: gradient.x1, y: gradient.y1)}, end: ${_alignmentLiteral(x: gradient.x2, y: gradient.y2)}, colors: [$colors], stops: ${gradient.stops}).createShader(const Rect.fromLTRB(-1, -1, 1, 1));',
        );
      }
      index++;
    }
    index = 0;
    for (final entry in document.patterns.entries) {
      final pattern = entry.value;
      b.writeln('  static final MemoryImage _image$index = MemoryImage(Uint8List.fromList(${pattern.bytes}));');
      final usages = _geometryFields.keys.where((element) => element.style.fillServerId == entry.key).toList();
      final twoAxis = _patternNeedsTwoAxisSizing(entry.key);
      final widths = <String>[];
      final heights = <String>[];
      for (final element in usages) {
        final tileField = _patternField(index: index, element: element);
        b.writeln(
          '  static final $tileField = _DotdartSvgPattern(bounds: ${_boundsExpression(element, exactPathBounds: pattern.objectBoundingBox)}, objectBoundingBox: ${pattern.objectBoundingBox}, x: ${_literal(pattern.x)}, y: ${_literal(pattern.y)}, width: ${_literal(pattern.width)}, height: ${_literal(pattern.height)}, imageX: ${_literal(pattern.imageX)}, imageY: ${_literal(pattern.imageY)}, imageWidth: ${_literal(pattern.imageWidth)}, imageHeight: ${_literal(pattern.imageHeight)});',
        );
        final matrix = _patternTransforms[element]!;
        widths.add(
          twoAxis
              ? _patternAxisLength(extent: '$tileField.imageWidth', x: matrix.a, y: matrix.b)
              : '$tileField.imageWidth * ${_literal(matrix.a.abs())}',
        );
        heights.add(
          twoAxis
              ? _patternAxisLength(extent: '$tileField.imageHeight', x: matrix.c, y: matrix.d)
              : '$tileField.imageHeight * ${_literal(matrix.d.abs())}',
        );
      }
      final width = widths.isEmpty ? '1.0' : widths.reduce((a, b) => 'math.max($a, $b)');
      final height = heights.isEmpty ? '1.0' : heights.reduce((a, b) => 'math.max($a, $b)');
      if (twoAxis) {
        b.writeln('  static double _decodeWidth$index({required double scaleX, required double scaleY}) => $width;');
        b.writeln('  static double _decodeHeight$index({required double scaleX, required double scaleY}) => $height;');
      } else {
        b.writeln('  static final double _decodeWidth$index = $width;');
        b.writeln('  static final double _decodeHeight$index = $height;');
      }
      index++;
    }
    if (document.patterns.isNotEmpty) {
      b.writeln('  static final List<List<_DotdartSvgPattern>> _patternDefinitions = [');
      var patternIndex = 0;
      for (final id in document.patterns.keys) {
        final names = _geometryFields.keys
            .where((element) => element.style.fillServerId == id)
            .map((element) => _patternField(index: patternIndex, element: element));
        b.writeln('    [${names.join(', ')}],');
        patternIndex++;
      }
      b.writeln('  ];');
    }
    if (document.patterns.isNotEmpty) {
      b.writeln('  static final Paint _patternPaint = Paint()..filterQuality = FilterQuality.low;');
    }
  }

  Map<SvgElement, SvgMatrix> _buildPatternTransforms() {
    final result = <SvgElement, SvgMatrix>{};
    void visit(List<SvgElement> elements, SvgMatrix parent) {
      for (final element in elements) {
        final transforms = element.transform;
        final matrix = transforms == null || transforms.isEmpty ? parent : SvgMatrix.compose([parent, ...transforms]);
        if (element is SvgGroup) {
          visit(element.children, matrix);
        } else if (document.patterns.containsKey(element.style.fillServerId)) {
          result[element] = matrix;
        }
      }
    }

    visit(document.children, const SvgMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0));
    return result;
  }

  bool _patternNeedsTwoAxisSizing(String id) => _patternTransforms.entries.any(
    (entry) => entry.key.style.fillServerId == id && (entry.value.b != 0 || entry.value.c != 0),
  );

  String _patternAxisLength({required String extent, required double x, required double y}) {
    if (x == 0 && y == 0) return '0.0';
    if (y == 0) return '$extent * ${_literal(x.abs())} * scaleX';
    if (x == 0) return '$extent * ${_literal(y.abs())} * scaleY';
    final horizontal = x == 1 ? 'scaleX' : 'scaleX * ${_literal(x)}';
    final vertical = y == 1 ? 'scaleY' : 'scaleY * ${_literal(y)}';
    return '$extent * math.sqrt(($horizontal) * ($horizontal) + ($vertical) * ($vertical))';
  }

  void _emitServerDraw(StringBuffer b, SvgElement element, String id) {
    final field = _geometryFields[element]!;
    final opacity = _fmt(element.style.fillOpacity * element.style.opacity);
    if (document.gradients.containsKey(id)) {
      final index = document.gradients.keys.toList().indexOf(id);
      final paint = '(_gradient$index..color = const Color.from(alpha: $opacity, red: 1, green: 1, blue: 1))';
      final gradient = document.gradients[id]!;
      final actualPaint = gradient.colors.length == 1 || (gradient.x1 == gradient.x2 && gradient.y1 == gradient.y2)
          ? '(_gradient$index..color = const Color(${_colorToHex(gradient.colors.last.$1, gradient.colors.last.$2, gradient.colors.last.$3, gradient.colors.last.$4 * element.style.fillOpacity * element.style.opacity)}))'
          : paint;
      final method = switch (element) {
        SvgRect(:final rx, :final ry) => rx > 0 || ry > 0 ? 'drawRRect' : 'drawRect',
        SvgCircle() || SvgEllipse() => 'drawOval',
        SvgPath() || SvgPolygon() || SvgPolyline() || SvgLine() => 'drawPath',
        SvgGroup() => throw StateError('Groups do not own geometry.'),
      };
      b.writeln('    canvas.$method($field, $actualPaint);');
      return;
    }
    final index = document.patterns.keys.toList().indexOf(id);
    final drawMethod = switch (element) {
      SvgRect(:final rx, :final ry) => rx > 0 || ry > 0 ? 'drawRRect' : 'drawRect',
      SvgCircle() || SvgEllipse() => 'drawOval',
      SvgPath() || SvgPolygon() || SvgPolyline() || SvgLine() => 'drawPath',
      SvgGroup() => throw StateError('Groups do not own geometry.'),
    };
    b.writeln(
      '    if (images[$index]?.shaderPaint(${_patternField(index: index, element: element)}) case final patternPaint?) {',
    );
    b.writeln(
      '      canvas.$drawMethod($field, patternPaint..color = const Color.from(alpha: $opacity, red: 1, green: 1, blue: 1));',
    );
    b.writeln('    } else {');
    b.writeln('    canvas.save();');
    switch (element) {
      case SvgRect(:final rx, :final ry):
        b.writeln(rx > 0 || ry > 0 ? '    canvas.clipRRect($field);' : '    canvas.clipRect($field);');
      case SvgCircle():
      case SvgEllipse():
        // Cache the oval clip alongside the tile, never allocate it during paint.
        b.writeln('    canvas.clipPath(${_patternField(index: index, element: element)}.ovalClip);');
      case SvgPath():
      case SvgPolygon():
      case SvgPolyline():
      case SvgLine():
        b.writeln('    canvas.clipPath($field);');
      case SvgGroup():
        throw StateError('Groups do not own geometry.');
    }
    b.writeln(
      '    ${_patternField(index: index, element: element)}.paint(canvas, images[$index], _patternPaint..color = const Color.from(alpha: $opacity, red: 1, green: 1, blue: 1));',
    );
    b.writeln('    canvas.restore();');
    b.writeln('    }');
  }

  // ── Format helpers ──

  String _colorKey((double, double, double, double) color) {
    return '${color.$1},${color.$2},${color.$3},${color.$4}';
  }

  String _colorRef(String param, String opacity, String paintName) {
    if (opacity == '1') return '$paintName..color = $param';
    return '$paintName..color = _dotdartApplyOpacity($param, $opacity)';
  }

  String _strokeColorRef(String param, String opacity, double width, String cap, String join) {
    if (opacity == '1') {
      return '_strokePaint..color = $param..strokeWidth = ${_fmt(width)}..strokeCap = $cap..strokeJoin = $join';
    }
    return '_strokePaint..color = _dotdartApplyOpacity($param, $opacity)..strokeWidth = ${_fmt(width)}..strokeCap = $cap..strokeJoin = $join';
  }

  String _colorToHex(double r, double g, double b, double a) {
    final ri = (r * 255).round().clamp(0, 255);
    final gi = (g * 255).round().clamp(0, 255);
    final bi = (b * 255).round().clamp(0, 255);
    final ai = (a * 255).round().clamp(0, 255);
    return '0x${ai.toRadixString(16).padLeft(2, '0')}${ri.toRadixString(16).padLeft(2, '0')}${gi.toRadixString(16).padLeft(2, '0')}${bi.toRadixString(16).padLeft(2, '0')}';
  }

  String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e10) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _lineCap(SvgStrokeLineCap cap) {
    return switch (cap) {
      SvgStrokeLineCap.butt => 'StrokeCap.butt',
      SvgStrokeLineCap.round => 'StrokeCap.round',
      SvgStrokeLineCap.square => 'StrokeCap.square',
    };
  }

  String _lineJoin(SvgStrokeLineJoin join) {
    return switch (join) {
      SvgStrokeLineJoin.miter => 'StrokeJoin.miter',
      SvgStrokeLineJoin.round => 'StrokeJoin.round',
      SvgStrokeLineJoin.bevel => 'StrokeJoin.bevel',
    };
  }

  bool _usesFill(List<SvgElement> elements) {
    for (final element in elements) {
      if (element is SvgGroup) {
        if (_usesFill(element.children)) return true;
        continue;
      }
      if (element.style.fillColor != null) return true;
    }
    return false;
  }

  bool _usesStroke(List<SvgElement> elements) {
    for (final element in elements) {
      if (element is SvgGroup) {
        if (_usesStroke(element.children)) return true;
        continue;
      }
      if (element.style.strokeColor != null) return true;
    }
    return false;
  }
}

class _ColorEntry {
  const _ColorEntry({
    required this.name,
    required this.sourceId,
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  final String name;
  final String? sourceId;
  final double r;
  final double g;
  final double b;
  final double a;

  _ColorEntry withName(String name) {
    return _ColorEntry(name: name, sourceId: sourceId, r: r, g: g, b: b, a: a);
  }
}
