import 'package:flutter/material.dart';

const _seed = Color(0xFF2E7D6B);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  useMaterial3: true,
);
