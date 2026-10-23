import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {
  // Inter is bundled in assets/google_fonts, so never hit the network for it
  // (fonts silently fell back to regular weight on devices without access).
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: RecruiterApp()));
}
