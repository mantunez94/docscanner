import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_perspective_crop/flutter_image_perspective_crop.dart';
import '../../core/document_processor.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? _originalBytes;
  Uint8List? _displayBytes;
  DocumentFilter _selectedFilter = DocumentFilter.grayscale;
  final _controller = ImagePerspectiveCropController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (!mounted) return;
    _originalBytes = bytes;
    _applyFilterToDisplay(bytes, _selectedFilter);
  }

  void _applyFilterToDisplay(Uint8List originalBytes, DocumentFilter filter) {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return;
    final processed = DocumentProcessor.applyFilter(decoded, filter);
    _displayBytes = Uint8List.fromList(img.encodeJpg(processed, quality: 92));
    setState(() {});
  }

  void _onFilterChanged(DocumentFilter filter) {
    if (_originalBytes == null || filter == _selectedFilter) return;
    _selectedFilter = filter;
    _applyFilterToDisplay(_originalBytes!, filter);
  }

  @override
  Widget build(BuildContext context) {
    if (_displayBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Adjust & Confirm')),
      body: ImagePerspectiveCrop(
        image: _displayBytes!,
        controller: _controller,
        style: ImagePerspectiveCropStyle(
          actionBarStyle: PerspectiveActionBarStyle(
            backgroundColor: const Color(0xBB000000),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            iconColor: Colors.white,
            iconSize: 28,
          ),
          lineStyle: PerspectiveLineStyle(
            color: const Color(0xFF00E5FF),
            strokeWidth: 2.5,
          ),
          handleStyle: PerspectiveHandleStyle(
            size: 26,
            fillColor: const Color(0xFF00E5FF),
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        ),
        onCompleted: (result) {
          if (result.status == PerspectiveCropStatus.complete && result.bytes != null) {
            Navigator.pop(context, result.bytes!);
          } else if (result.status == PerspectiveCropStatus.error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${result.errorMessage}')),
              );
            }
          }
        },
        builders: ImagePerspectiveCropBuilders(
          bottomBarWithControllerBuilder: (ctx, controller, close, switchBtn, complete) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterBar(),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(width: 40, child: close),
                    const SizedBox(width: 4),
                    SizedBox(width: 40, child: switchBtn),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'retake'),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Retake', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 40, child: complete),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: DocumentFilter.values.map((f) {
          final isSelected = f == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                _filterLabel(f),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF00E5FF),
              backgroundColor: Colors.white12,
              side: BorderSide(
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
                width: 1,
              ),
              onSelected: (_) => _onFilterChanged(f),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(DocumentFilter f) {
    return switch (f) {
      DocumentFilter.original => 'Original',
      DocumentFilter.grayscale => 'Grayscale',
      DocumentFilter.blackAndWhite => 'B&W',
      DocumentFilter.enhanced => 'Enhanced',
    };
  }
}
