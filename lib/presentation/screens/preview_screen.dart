import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_perspective_crop/flutter_image_perspective_crop.dart';
import '../../core/document_processor.dart';
import '../../domain/entities/ocr_result.dart';
import '../providers/ocr_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  Uint8List? _originalBytes;
  Uint8List? _displayBytes;
  DocumentFilter _selectedFilter = DocumentFilter.grayscale;
  final _controller = ImagePerspectiveCropController();
  bool _ocrLoading = false;
  OcrResult? _ocrResult;

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

  Future<void> _runOcr() async {
    setState(() => _ocrLoading = true);
    try {
      final service = ref.read(ocrServiceProvider);
      final result = await service.recognizeImage(widget.imagePath);
      if (!mounted) return;
      setState(() {
        _ocrLoading = false;
        _ocrResult = result;
      });
      _showOcrResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocrLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR failed: $e')),
      );
    }
  }

  void _showOcrResult(OcrResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Extracted Text',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.blocks.length} text blocks found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        SelectableText(
                          result.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _copyToClipboard(result.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
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
      body: Stack(
        children: [
          ImagePerspectiveCrop(
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
                          onPressed: _ocrLoading ? null : _runOcr,
                          icon: _ocrLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.text_snippet, size: 18),
                          label: Text(
                            _ocrLoading ? 'OCR...' : 'OCR',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 4),
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
          if (_ocrResult != null)
            Positioned(
              top: 8,
              right: 8,
              child: ActionChip(
                avatar: const Icon(Icons.text_snippet, size: 16),
                label: Text('${_ocrResult!.blocks.length} blocks'),
                onPressed: () => _showOcrResult(_ocrResult!),
              ),
            ),
        ],
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
