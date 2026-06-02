import 'dart:io';
import 'package:flutter/material.dart';

class CapturedPageStrip extends StatelessWidget {
  final List<String> capturedPages;
  final void Function(int index) onEditPage;
  final ScrollController scrollController;

  const CapturedPageStrip({
    super.key,
    required this.capturedPages,
    required this.onEditPage,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: '${capturedPages.length} pages captured',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                '${capturedPages.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: capturedPages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return Semantics(
                  label: 'Page ${index + 1} thumbnail',
                  child: GestureDetector(
                    onTap: () => onEditPage(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(capturedPages[index]),
                        width: 56,
                        height: 72,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
