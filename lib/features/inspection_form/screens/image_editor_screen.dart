import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

enum EditorTool { none, blur, watermark }

class BlurRegion {
  Rect rect;
  final UniqueKey id;
  BlurRegion(this.rect) : id = UniqueKey();
}

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;
  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  final List<BlurRegion> _blurRegions = [];
  Rect? _watermarkRect;

  bool _isSaving = false;
  int? _activeItemIndex;
  Size _imageDisplaySize = Size.zero;

  void _calculateImageSize(BoxConstraints constraints, ui.Image originalImage) {
    double imageWidth = originalImage.width.toDouble();
    double imageHeight = originalImage.height.toDouble();
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;

    double imageAspectRatio = imageWidth / imageHeight;
    double screenAspectRatio = screenWidth / screenHeight;

    double finalWidth, finalHeight;
    if (imageAspectRatio > screenAspectRatio) {
      finalWidth = screenWidth;
      finalHeight = screenWidth / imageAspectRatio;
    } else {
      finalHeight = screenHeight;
      finalWidth = screenHeight * imageAspectRatio;
    }

    Size newSize = Size(finalWidth, finalHeight);
    if (_imageDisplaySize != newSize) {
      Future.microtask(() => setState(() => _imageDisplaySize = newSize));
    }
  }

  Future<void> _saveEditedImage() async {
    if (_isSaving || _imageDisplaySize == Size.zero) return;

    setState(() {
      _isSaving = true;
      _activeItemIndex = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw "Capture boundary not found";

      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw "Failed to serialize image";

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          "${tempDir.path}/OTOBIX_EDITED_${DateTime.now().millisecondsSinceEpoch}.png";

      await File(filePath).writeAsBytes(buffer);
      if (mounted) Navigator.of(context).pop(filePath);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Get.snackbar(
          "Error",
          "Save failed",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              "Edit Photo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveEditedImage,
                child: const Text(
                  "DONE",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FutureBuilder<ui.Image>(
                      future: _loadOriginalImage(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        _calculateImageSize(constraints, snapshot.data!);

                        return GestureDetector(
                          onTap: () => setState(() => _activeItemIndex = null),
                          child: Center(
                            child: RepaintBoundary(
                              key: _boundaryKey,
                              child: Container(
                                width: _imageDisplaySize.width,
                                height: _imageDisplaySize.height,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: FileImage(File(widget.imagePath)),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Blur Layers
                                    for (
                                      int i = 0;
                                      i < _blurRegions.length;
                                      i++
                                    )
                                      _EditableBox(
                                        rect: _blurRegions[i].rect,
                                        isActive: _activeItemIndex == i,
                                        onTap:
                                            () => setState(() {
                                              _activeItemIndex = i;
                                            }),
                                        onUpdate:
                                            (r) => setState(
                                              () => _blurRegions[i].rect = r,
                                            ),
                                        onDelete:
                                            () => setState(() {
                                              _blurRegions.removeAt(i);
                                              _activeItemIndex = null;
                                            }),
                                        child: ClipRect(
                                          child: BackdropFilter(
                                            filter: ui.ImageFilter.blur(
                                              sigmaX: 25,
                                              sigmaY: 25,
                                            ),
                                            child: Container(
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Watermark
                                    if (_watermarkRect != null)
                                      _EditableBox(
                                        rect: _watermarkRect!,
                                        isActive: _activeItemIndex == -1,
                                        onTap:
                                            () => setState(() {
                                              _activeItemIndex = -1;
                                            }),
                                        onUpdate:
                                            (r) => setState(
                                              () => _watermarkRect = r,
                                            ),
                                        onDelete:
                                            () => setState(() {
                                              _watermarkRect = null;
                                              _activeItemIndex = null;
                                            }),
                                        child: Image.asset(
                                          'assets/images/Watermark/watermark.png',
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Text(
                                                  "OTOBIX",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildToolBar(),
            ],
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
      ],
    );
  }

  Future<ui.Image> _loadOriginalImage() async {
    final data = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: const Color(0xFF1E1E1E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(EditorTool.blur, Icons.blur_on, "Add Blur"),
          _toolBtn(EditorTool.watermark, Icons.branding_watermark, "Watermark"),
          _toolBtn(
            EditorTool.none,
            Icons.layers_clear,
            "Clear All",
            isClear: true,
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(
    EditorTool tool,
    IconData icon,
    String label, {
    bool isClear = false,
  }) {
    return InkWell(
      onTap: () {
        if (isClear)
          setState(() {
            _blurRegions.clear();
            _watermarkRect = null;
            _activeItemIndex = null;
          });
        else {
          setState(() {
            if (tool == EditorTool.blur) {
              final center = Offset(
                _imageDisplaySize.width / 2,
                _imageDisplaySize.height / 2,
              );
              _blurRegions.add(
                BlurRegion(
                  Rect.fromCenter(center: center, width: 100, height: 100),
                ),
              );
              _activeItemIndex = _blurRegions.length - 1;
            } else if (tool == EditorTool.watermark) {
              final center = Offset(
                _imageDisplaySize.width / 2,
                _imageDisplaySize.height / 2,
              );
              _watermarkRect = Rect.fromCenter(
                center: center,
                width: 160,
                height: 60,
              );
              _activeItemIndex = -1;
            }
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EditableBox extends StatelessWidget {
  final Rect rect;
  final bool isActive;
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(Rect) onUpdate;

  const _EditableBox({
    required this.rect,
    required this.isActive,
    required this.child,
    required this.onTap,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect.inflate(isActive ? 25 : 0),
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: isActive ? (d) => onUpdate(rect.shift(d.delta)) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(isActive ? 25 : 0),
              child: Container(
                decoration:
                    isActive
                        ? BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                        )
                        : null,
                child: child,
              ),
            ),
            if (isActive) ...[
              Positioned(
                top: -15,
                left: -15,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              _handle(
                Alignment.topLeft,
                (d) => onUpdate(
                  Rect.fromLTRB(
                    rect.left + d.dx,
                    rect.top + d.dy,
                    rect.right,
                    rect.bottom,
                  ),
                ),
              ),
              _handle(
                Alignment.topRight,
                (d) => onUpdate(
                  Rect.fromLTRB(
                    rect.left,
                    rect.top + d.dy,
                    rect.right + d.dx,
                    rect.bottom,
                  ),
                ),
              ),
              _handle(
                Alignment.bottomLeft,
                (d) => onUpdate(
                  Rect.fromLTRB(
                    rect.left + d.dx,
                    rect.top,
                    rect.right,
                    rect.bottom + d.dy,
                  ),
                ),
              ),
              _handle(
                Alignment.bottomRight,
                (d) => onUpdate(
                  Rect.fromLTRB(
                    rect.left,
                    rect.top,
                    rect.right + d.dx,
                    rect.bottom + d.dy,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handle(Alignment align, Function(Offset) onDrag) {
    return Positioned(
      top: align.y == -1 ? 12 : null,
      bottom: align.y == 1 ? 12 : null,
      left: align.x == -1 ? 12 : null,
      right: align.x == 1 ? 12 : null,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d.delta),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}
