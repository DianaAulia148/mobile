import 'package:flutter/material.dart';

/// WARNA UTAMA
const Color ungu = Color(0xFF8A00C4);

/// THEME GLOBAL
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

/// NAMA PROFIL GLOBAL
final ValueNotifier<String> nameNotifier =
    ValueNotifier("Kholila Ristiana");
