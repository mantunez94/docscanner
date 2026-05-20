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
  Uint8List? _imageBytes;
  DocumentFilter _selectedFilter = DocumentFilter.grayscale;
  final _controller = ImagePerspectiveCropController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Adjust & Confirm')),
      body: ImagePerspectiveCrop(
        image: _imageBytes!,
        controller: _controller,
        onCompleted: (result) {
          if (result.status == PerspectiveCropStatus.complete && result.bytes != null) {
            final decoded = img.decodeImage(result.bytes!);
            if (decoded != null) {
              final processed = DocumentProcessor.applyFilter(decoded, _selectedFilter);
              final out = Uint8List.fromList(img.encodeJpg(processed, quality: 90));
              if (mounted) Navigator.pop(context, out);
            }
          } else if (result.status == PerspectiveCropStatus.error) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result.errorMessage}')),
            );
          }
        },
        builders: ImagePerspectiveCropBuilders(
          bottomBarWithControllerBuilder: (ctx, controller, close, _, complete) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterBar(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: Row(
                    children: [
                      Expanded(child: close),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, 'retake'),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: complete),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: DocumentFilter.values.map((f) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_filterLabel(f)),
                selected: f == _selectedFilter,
                onSelected: (_) => setState(() => _selectedFilter = f),
              ),
            );
          }).toList(),
        ),
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
