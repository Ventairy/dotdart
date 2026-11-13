/// Emits the shared embedded-image loader and cached pattern geometry.
class SvgPatternEmitter {
  SvgPatternEmitter._();

  static String emit() => '''
class _DotdartSvgImages extends StatefulWidget {
  const _DotdartSvgImages({required this.providers, required this.patterns, required this.builder});

  final List<ImageProvider<Object>> providers;
  final List<List<_DotdartSvgPattern>> patterns;
  final Widget Function(List<_DotdartSvgDecodedImage?> images) builder;

  @override
  State<_DotdartSvgImages> createState() => _DotdartSvgImagesState();
}

class _DotdartSvgImagesState extends State<_DotdartSvgImages> {
  List<_DotdartSvgDecodedImage?> _images = [];
  List<({ImageProvider<Object> provider, ImageConfiguration configuration})?> _resolved = [];
  List<bool> _failed = [];
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageConfiguration? _configuration;
  bool _pumping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final configuration = createLocalImageConfiguration(context);
    if (configuration == _configuration) return;
    _configuration = configuration;
    _reload();
  }

  @override
  void didUpdateWidget(covariant _DotdartSvgImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers.length != widget.providers.length) {
      _reload();
      return;
    }
    for (var index = 0; index < widget.providers.length; index++) {
      if (oldWidget.providers[index] != widget.providers[index]) {
        _reload();
        return;
      }
    }
  }

  Object _source(ImageProvider<Object> provider) => provider is ResizeImage ? provider.imageProvider : provider;

  void _reload() {
    final previousImages = _images;
    final previousResolved = _resolved;
    _images = List.filled(widget.providers.length, null);
    _resolved = List.filled(widget.providers.length, null);
    _failed = List.filled(widget.providers.length, false);
    for (var index = 0; index < previousImages.length; index++) {
      final resolved = previousResolved[index];
      if (index < widget.providers.length && resolved != null &&
          _source(resolved.provider) == _source(widget.providers[index])) {
        _images[index] = previousImages[index];
        _resolved[index] = resolved;
      } else {
        previousImages[index]?.dispose();
      }
    }
    // Keep an active decode until it completes. The image cache may still be
    // decoding after a listener is removed; starting another resize here would
    // allow rapid size changes to create many concurrent decodes.
    _pump();
  }

  void _pump() {
    if (_pumping || !mounted || _configuration == null) return;
    _pumping = true;
    try {
      while (_stream == null) {
        int? next;
        for (var index = 0; index < widget.providers.length; index++) {
          final resolved = _resolved[index];
          if (!_failed[index] && (resolved == null || resolved.provider != widget.providers[index] ||
              resolved.configuration != _configuration)) {
            next = index;
            break;
          }
        }
        if (next == null) return;
        _load(next);
      }
    } finally {
      _pumping = false;
    }
  }

  void _load(int index) {
    final provider = widget.providers[index];
    final configuration = _configuration!;
    final stream = provider.resolve(configuration);
    late ImageStreamListener listener;
    listener = ImageStreamListener((image, synchronous) {
      stream.removeListener(listener);
      if (!mounted) {
        image.dispose();
        return;
      }
      _stream = null;
      _listener = null;
      if (index < widget.providers.length && _source(provider) == _source(widget.providers[index])) {
        _images[index]?.dispose();
        _images = [..._images]..[index] = _DotdartSvgDecodedImage(image, widget.patterns[index]);
        _resolved[index] = (provider: provider, configuration: configuration);
      } else {
        image.dispose();
      }
      if (!synchronous) setState(() {});
      _pump();
    }, onError: (error, stack) {
      stream.removeListener(listener);
      if (!mounted) return;
      _stream = null;
      _listener = null;
      if (index < widget.providers.length && provider == widget.providers[index] && configuration == _configuration) {
        _failed[index] = true;
        FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'dotdart generated SVG'));
      }
      _pump();
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
    for (final image in _images) {
      image?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_images);
}

class _DotdartSvgDecodedImage {
  _DotdartSvgDecodedImage(this.info, List<_DotdartSvgPattern> patterns)
      : source = Rect.fromLTWH(0, 0, info.image.width.toDouble(), info.image.height.toDouble()) {
    for (final pattern in patterns) {
      final rect = pattern.singleImage;
      if (rect == null) continue;
      final shader = ImageShader(info.image, TileMode.decal, TileMode.decal, Float64List.fromList([
        rect.width / info.image.width, 0, 0, 0,
        0, rect.height / info.image.height, 0, 0,
        0, 0, 1, 0,
        rect.left, rect.top, 0, 1,
      ]), filterQuality: FilterQuality.low);
      _shaders.add(shader);
      _shaderPaints[pattern] = Paint()..shader = shader;
    }
  }

  final ImageInfo info;
  final Rect source;
  final _shaders = <ImageShader>[];
  final _shaderPaints = <_DotdartSvgPattern, Paint>{};

  Paint? shaderPaint(_DotdartSvgPattern pattern) => _shaderPaints[pattern];

  void dispose() {
    for (final shader in _shaders) {
      shader.dispose();
    }
    info.dispose();
  }
}

class _DotdartSvgPattern {
  _DotdartSvgPattern({required Rect bounds, required bool objectBoundingBox,
      required double x, required double y, required double width, required double height,
      required double imageX, required double imageY, required double imageWidth, required double imageHeight}) : _bounds = bounds {
    final sx = objectBoundingBox ? bounds.width : 1.0;
    final sy = objectBoundingBox ? bounds.height : 1.0;
    final ox = objectBoundingBox ? bounds.left : 0.0;
    final oy = objectBoundingBox ? bounds.top : 0.0;
    this.imageWidth = imageWidth * sx;
    this.imageHeight = imageHeight * sy;
    if (bounds.isEmpty) return;
    final tileWidth = width * sx;
    final tileHeight = height * sy;
    final firstX = ((bounds.left - ox - x * sx) / tileWidth).floor();
    final lastX = ((bounds.right - ox - x * sx) / tileWidth).ceil();
    final firstY = ((bounds.top - oy - y * sy) / tileHeight).floor();
    final lastY = ((bounds.bottom - oy - y * sy) / tileHeight).ceil();
    if ((lastX - firstX) * (lastY - firstY) > 4096) {
      throw FlutterError('SVG image pattern exceeds 4096 visible tiles. Use a larger tile.');
    }
    for (var row = firstY; row < lastY; row++) {
      for (var column = firstX; column < lastX; column++) {
        final dx = ox + column * tileWidth;
        final dy = oy + row * tileHeight;
        final tile = Rect.fromLTWH(dx + x * sx, dy + y * sy, tileWidth, tileHeight);
        final image = Rect.fromLTWH(dx + (x + imageX) * sx, dy + (y + imageY) * sy, this.imageWidth, this.imageHeight);
        final contained = tile.left <= image.left && tile.top <= image.top &&
            tile.right >= image.right && tile.bottom >= image.bottom;
        _tiles.add((clip: contained ? null : tile, image: image));
      }
    }
  }

  Rect? get singleImage => _tiles.length == 1 && _tiles.single.clip == null ? _tiles.single.image : null;

  late final double imageWidth;
  late final double imageHeight;
  final Rect _bounds;
  late final Path ovalClip = Path()..addOval(_bounds);
  final _tiles = <({Rect? clip, Rect image})>[];

  void paint(Canvas canvas, _DotdartSvgDecodedImage? info, Paint paint) {
    if (info == null) return;
    final image = info.info.image;
    for (final rects in _tiles) {
      final clip = rects.clip;
      if (clip != null) {
        canvas.save();
        canvas.clipRect(clip, doAntiAlias: false);
      }
      canvas.drawImageRect(image, info.source, rects.image, paint);
      if (clip != null) canvas.restore();
    }
  }
}

''';
}
