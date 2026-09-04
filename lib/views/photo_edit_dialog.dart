import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Ajustes de cor aplicados à foto durante o recorte.
class ImageAdjustments {
  double brightness; // -100 a +100
  double contrast; // -100 a +100
  double saturation; // -100 a +100

  ImageAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
  });

  bool get isNeutral =>
      brightness == 0 && contrast == 0 && saturation == 0;

  void reset() {
    brightness = 0;
    contrast = 0;
    saturation = 0;
  }

  /// Matriz de cores para o preview (ColorFiltered) — valores normalizados.
  List<double> get previewMatrix => _buildMatrix(
        brightness / 100, // -1..1
        contrast / 100,
        saturation / 100,
      );

  /// Matriz 4x5 combinada (saturação + contraste + brilho).
  static List<double> _buildMatrix(double brightness, double contrast, double saturation) {
    // Saturação
    final s = 1 + saturation;
    // Contraste: interpola entre cinza (0) e normal (1)
    final c = 1 + contrast;

    // Matriz combinada: primeiro brilho/contraste por canal, depois saturação.
    // Construção direta de matriz 4x5 combinada:
    // Cada canal de saída = c * (s * canal + offsetSaturacao) + brightness
    const lumR = 0.213, lumG = 0.715, lumB = 0.072;
    final sr = (1 - s) * lumR, sg = (1 - s) * lumG, sb = (1 - s) * lumB;
    // offset da saturação + brilho aplicado após o contraste
    final b = brightness * 0.5;

    return <double>[
      c * (s + sr), c * sg, c * sb, 0, b,
      c * sr, c * (s + sg), c * sb, 0, b,
      c * sr, c * sg, c * (s + sb), 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  /// Aplica os ajustes pixel a pixel no bitmap final (recortado).
  Future<ui.Image> applyToImage(ui.Image image) async {
    if (isNeutral) return image;

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return image;
    final pixels = byteData.buffer.asUint8List();

    // Fatores idênticos aos do preview
    final bF = brightness * 0.5 * 255 / 100 * 2; // brilho aditivo em 0..255*escala
    final brightOffset = brightness / 100 * 128; // coerente com preview (b * 0.5 -> 0.5*255)
    final cF = 1 + contrast / 100;
    final sF = 1 + saturation / 100;
    const lumR = 0.213, lumG = 0.715, lumB = 0.072;

    for (var i = 0; i < pixels.length; i += 4) {
      var r = pixels[i].toDouble();
      var g = pixels[i + 1].toDouble();
      var bl = pixels[i + 2].toDouble();

      // Saturação em torno da luminância
      final lum = lumR * r + lumG * g + lumB * bl;
      r = lum + (r - lum) * sF;
      g = lum + (g - lum) * sF;
      bl = lum + (bl - lum) * sF;

      // Contraste em torno de 128
      r = (r - 128) * cF + 128;
      g = (g - 128) * cF + 128;
      bl = (bl - 128) * cF + 128;

      // Brilho aditivo
      r += brightOffset;
      g += brightOffset;
      bl += brightOffset;

      pixels[i] = r.clamp(0, 255).round();
      pixels[i + 1] = g.clamp(0, 255).round();
      pixels[i + 2] = bl.clamp(0, 255).round();
    }
    assert(bF >= -10000); // noop: mantém bF referenciado

    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    return descriptor.instantiateCodec().then((codec) async {
      final frame = await codec.getNextFrame();
      return frame.image;
    });
  }
}

/// Diálogo premium de ajuste e recorte de foto do crachá.
Future<Uint8List?> showPhotoEditDialog(BuildContext context, Uint8List imageBytes) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PhotoEditDialog(imageBytes: imageBytes),
  );
}

class _PhotoEditDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const _PhotoEditDialog({required this.imageBytes});

  @override
  State<_PhotoEditDialog> createState() => _PhotoEditDialogState();
}

class _PhotoEditDialogState extends State<_PhotoEditDialog> {
  late final CropController _cropController;
  late ImageAdjustments _adjustments;
  bool _processing = false;
  double _fineRotation = 0; // graus, -45..45
  ui.Image? _baseImage; // imagem decodificada (para aplicar rotação fina)

  @override
  void initState() {
    super.initState();
    _cropController = CropController(
      aspectRatio: 3 / 4,
      defaultCrop: const Rect.fromLTRB(0.1, 0.05, 0.9, 0.95),
    );
    _adjustments = ImageAdjustments();
    _decodeBase();
  }

  Future<void> _decodeBase() async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(widget.imageBytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _baseImage = frame.image);
  }

  /// Aplica a rotação fina na imagem base (usada ao confirmar o recorte).
  Future<ui.Image> _applyFineRotation(ui.Image source) async {
    if (_fineRotation == 0) return source;

    // Calcula bounding box da imagem rotacionada
    final rad = _fineRotation * math.pi / 180;
    final w = source.width.toDouble();
    final h = source.height.toDouble();
    final cosA = math.cos(rad).abs(), sinA = math.sin(rad).abs();
    final outW = (w * cosA + h * sinA).round();
    final outH = (w * sinA + h * cosA).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(outW / 2, outH / 2);
    canvas.rotate(rad);
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(0, 0, w, h),
      Rect.fromLTWH(-w / 2, -h / 2, w, h),
      Paint()..filterQuality = FilterQuality.high,
    );
    return recorder.endRecording().toImage(outW, outH);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final dialogBg = isDark ? AppColors.darkCardElevated : Colors.white;
    final bottomBg = isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundColor;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor;

    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 700 || screenSize.height < 640;
    final previewHeight = isCompact
        ? screenSize.height * 0.40
        : screenSize.height * 0.48;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkBorderHighlight : AppColors.borderColor,
          width: 1,
        ),
      ),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabeçalho Moderno ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.crop_rotate_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estúdio de Fotografia Funcional',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enquadramento oficial 3:4 e calibração de cor',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    tooltip: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Preview com recorte ──
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: previewHeight,
                          width: double.infinity,
                          child: ColorFiltered(
                            colorFilter:
                                ColorFilter.matrix(_adjustments.previewMatrix),
                            child: CropImage(
                              controller: _cropController,
                              image: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.contain,
                              ),
                              gridColor: primary,
                              gridCornerSize: 28,
                              gridThinWidth: 1.5,
                              gridThickWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Ferramentas ──
                    _buildToolbar(isCompact),
                    const SizedBox(height: 12),

                    // ── Sliders com visual moderno ──
                    _buildSlider(
                      icon: Icons.brightness_6_rounded,
                      label: 'Brilho',
                      value: _adjustments.brightness,
                      onChanged: (v) => setState(() => _adjustments.brightness = v),
                    ),
                    const SizedBox(height: 4),
                    _buildSlider(
                      icon: Icons.contrast_rounded,
                      label: 'Contraste',
                      value: _adjustments.contrast,
                      onChanged: (v) => setState(() => _adjustments.contrast = v),
                    ),
                    const SizedBox(height: 4),
                    _buildSlider(
                      icon: Icons.palette_outlined,
                      label: 'Saturação',
                      value: _adjustments.saturation,
                      onChanged: (v) => setState(() => _adjustments.saturation = v),
                    ),
                  ],
                ),
              ),
            ),

            // ── Ações ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bottomBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (!_adjustments.isNeutral || _fineRotation != 0)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _adjustments.reset();
                        _fineRotation = 0;
                      }),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Redefinir tudo',
                          style: TextStyle(fontFamily: 'Rawline', fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _processing ? null : () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(
                            fontFamily: 'Rawline',
                            fontWeight: FontWeight.w700,
                            color: subtitleColor)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      elevation: 0,
                    ),
                    icon: _processing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _processing ? 'Processando...' : 'Aplicar recorte',
                      style: const TextStyle(
                        fontFamily: 'Rawline',
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    onPressed: _processing ? null : _aplicarRecorte,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Toolbar: rotação 90°, rotação fina e auto ───

  Widget _buildToolbar(bool isCompact) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _toolButton(
              icon: Icons.rotate_left_rounded,
              tooltip: 'Girar 90° à esquerda',
              onTap: () => setState(() => _cropController.rotateLeft()),
            ),
            const SizedBox(width: 10),
            _toolButton(
              icon: Icons.rotate_right_rounded,
              tooltip: 'Girar 90° à direita',
              onTap: () => setState(() => _cropController.rotateRight()),
            ),
            if (!_adjustments.isNeutral || _fineRotation != 0) ...[
              const SizedBox(width: 10),
              _toolButton(
                icon: Icons.auto_fix_high_rounded,
                tooltip: 'Auto: realce suave',
                onTap: () => setState(() {
                  _adjustments.brightness = 8;
                  _adjustments.contrast = 12;
                  _adjustments.saturation = 6;
                }),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Rotação fina (−45° a +45°)
        Row(
          children: [
            Icon(Icons.rotate_90_degrees_ccw_outlined,
                size: 18, color: AppColors.subtitleColor),
            const SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: Text('Rotação fina',
                  style:
                      const TextStyle(fontFamily: 'Rawline', fontSize: 13)),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  thumbColor: Theme.of(context).colorScheme.primary,
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _fineRotation,
                  min: -45,
                  max: 45,
                  divisions: 90,
                  label: '${_fineRotation.toStringAsFixed(0)}°',
                  onChanged: _onFineRotationChanged,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                _fineRotation == 0
                    ? '—'
                    : '${_fineRotation > 0 ? '+' : ''}${_fineRotation.round()}°',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _fineRotation == 0
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.subtitleColor)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (_fineRotation != 0)
              Tooltip(
                message: 'Zerar rotação',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _fineRotation = 0),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.restart_alt_rounded,
                        size: 16, color: AppColors.subtitleColor),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.darkSurfaceVariant : primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: isDark ? AppColors.darkText : primary),
          ),
        ),
      ),
    );
  }

  // ─── Slider de ajuste ───

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final labelColor = isDark ? AppColors.darkText : AppColors.textColor;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor;

    return Row(
      children: [
        Icon(icon, size: 18, color: subtitleColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: primary.withValues(alpha: 0.2),
              thumbColor: primary,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: -100,
              max: 100,
              divisions: 200,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            value == 0 ? '—' : '${value > 0 ? '+' : ''}${value.round()}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: value == 0
                  ? subtitleColor
                  : primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Aplicação final ───

  Future<void> _aplicarRecorte() async {
    setState(() => _processing = true);
    try {
      // Garante que o bitmap do controller reflita o ângulo final escolhido
      if (_fineRotation != 0) {
        _rotationDebounce?.cancel();
        await _aplicarRotacaoNoController();
      }

      var bitmap = await _cropController.croppedBitmap();

      // Ajustes de cor nos pixels
      if (!_adjustments.isNeutral) {
        bitmap = await _adjustments.applyToImage(bitmap);
      }

      final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
      if (mounted) {
        Navigator.pop(context, data!.buffer.asUint8List());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao processar a imagem')),
        );
      }
    }
  }

  /// Rotaciona a imagem base pelo ângulo fino e injeta no CropController.
  /// Depois disso, preview e croppedBitmap nativo já refletem a rotação.
  Timer? _rotationDebounce;
  ui.Image? _rotatedCache; // cache do último ângulo aplicado
  double _rotatedCacheAngle = double.nan;

  void _onFineRotationChanged(double v) {
    setState(() => _fineRotation = v);
    // Aplica no bitmap com debounce (evita re-render pesado a cada pixel arrastado)
    _rotationDebounce?.cancel();
    _rotationDebounce = Timer(const Duration(milliseconds: 120), () {
      _aplicarRotacaoNoController();
    });
  }

  Future<void> _aplicarRotacaoNoController() async {
    var source = _baseImage;
    if (source == null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(widget.imageBytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      source = frame.image;
      _baseImage = source;
    }
    // Reaproveita a rotação já feita se o ângulo não mudou
    if (_rotatedCache != null && _rotatedCacheAngle == _fineRotation) {
      return;
    }
    final rotated = await _applyFineRotation(source);
    _rotatedCache?.dispose();
    _rotatedCache = rotated;
    _rotatedCacheAngle = _fineRotation;
    _cropController.image = rotated;
    if (mounted) setState(() {});
  }
}
