import 'package:flutter/material.dart';

int responsiveCrossAxisCount(BuildContext context, {int small = 2, int medium = 3, int large = 4}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 840) return large;
  if (width >= 600) return medium;
  return small;
}
