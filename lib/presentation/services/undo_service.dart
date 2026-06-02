import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UndoAction {
  final String label;
  final VoidCallback onUndo;

  UndoAction({required this.label, required this.onUndo});
}

final undoActionProvider = StateProvider<UndoAction?>((ref) => null);
