import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final batchModeProvider = StateProvider<bool>((ref) => false);
final selectedIdsProvider = StateProvider<Set<String>>((ref) => {});
