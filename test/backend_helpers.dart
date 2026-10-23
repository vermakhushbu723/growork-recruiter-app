import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:subkamyaab_recruiter_app/core/network/api_client.dart';

/// These tests run against the real backend (`npm run dev` in
/// growork-backend, seeded with `npm run seed`).
const demoEmail = 'ananya@demo.subkamyaab.com';
const demoPassword = 'Demo@123';

/// Lets tests make real HTTP calls to the local backend. (The test binding
/// blocks HTTP, and tests report Android, whose default is the emulator
/// address.) Override with `--dart-define=TEST_API=...`.
void allowRealHttp() {
  HttpOverrides.global = null;
  api.setBaseUrl(
    const String.fromEnvironment(
      'TEST_API',
      defaultValue: 'http://localhost:5080/api/v1',
    ),
  );
}

/// Logs in as the seeded demo recruiter and stores the token.
Future<void> loginDemo() async {
  final d = jMap(
    await api.post('/auth/login', {
      'app': kApp,
      'email': demoEmail,
      'password': demoPassword,
    }),
  );
  await api.setToken(jStr(d['token']));
}

/// Loads the bundled Inter weights so text is measured like on a device
/// (the default test font draws every glyph as a wide square).
Future<void> loadInter() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final loader = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(
      File('assets/google_fonts/Inter-$w.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
    );
  }
  await loader.load();
}
