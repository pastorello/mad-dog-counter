import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';

/// I nomi dei file sono il contratto tra il pacchetto suoni e il codice
/// (assets/sounds/README.md). Se qualcuno rinomina un WAV, questo test lo
/// prende prima che il pub resti muto.
void main() {
  test('ogni costante kSfx punta a un file che esiste davvero', () {
    for (final String sfx in kAllSfx) {
      expect(
        File('assets/$sfx').existsSync(),
        isTrue,
        reason: 'manca assets/$sfx',
      );
    }
  });

  test('non ci sono WAV in assets/sounds/ che il codice ignora', () {
    final List<String> onDisk =
        Directory('assets/sounds')
            .listSync()
            .whereType<File>()
            .map((File f) => 'sounds/${f.uri.pathSegments.last}')
            .where((String p) => p.endsWith('.wav'))
            .toList()
          ..sort();
    expect(onDisk, kAllSfx.toList()..sort());
  });
}
