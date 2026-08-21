import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/audio/sound_manager.dart';
import 'package:mad_dog_counter/bootstrap.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/backup_service.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'inizializzazione in [buildAppDependencies] e' la rete di sicurezza piu'
/// delicata dell'app: se sqflite, l'audio o la storage esterna non si
/// aprono, il contatore deve partire comunque (regola d'oro 2). Ogni passo
/// e' iniettabile apposta per esercitare quei fallback qui, senza toccare
/// `runApp()`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('log', () {
    test(
      'se sqflite non si apre, cade su NoopTapLog e si conta lo stesso',
      () async {
        final AppDependencies deps = await buildAppDependencies(
          openLog: () async => throw Exception('sqflite offeso'),
          createSounds: SilentSoundManager.new,
          resolveBackupDirectory: () async => null,
        );

        expect(deps.log, isA<NoopTapLog>());
        expect(deps.repository, isA<LocalCounterRepository>());
      },
    );

    test(
      "se sqflite si apre, il log aperto e' quello passato al repository",
      () async {
        const NoopTapLog fakeLog = NoopTapLog();
        final AppDependencies deps = await buildAppDependencies(
          openLog: () async => fakeLog,
          createSounds: SilentSoundManager.new,
          resolveBackupDirectory: () async => null,
        );

        expect(deps.log, same(fakeLog));
      },
    );
  });

  group('audio', () {
    test('se non si inizializza, cade su SilentSoundManager', () async {
      final AppDependencies deps = await buildAppDependencies(
        openLog: () async => const NoopTapLog(),
        createSounds: () => throw Exception('audio offeso'),
        resolveBackupDirectory: () async => null,
      );

      expect(deps.sounds, isA<SilentSoundManager>());
    });

    test(
      "se si inizializza, e' quello scelto ad avere enabled sincronizzato",
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          kPrefsSoundEnabled: false,
        });
        final SilentSoundManager fakeSounds = SilentSoundManager();
        final AppDependencies deps = await buildAppDependencies(
          openLog: () async => const NoopTapLog(),
          createSounds: () => fakeSounds,
          resolveBackupDirectory: () async => null,
        );

        expect(deps.sounds, same(fakeSounds));
        expect(deps.sounds.enabled, isFalse);
      },
    );
  });

  group('backup', () {
    test('se la storage esterna non c\'e\', il backup e\' assente', () async {
      final AppDependencies deps = await buildAppDependencies(
        openLog: () async => const NoopTapLog(),
        createSounds: SilentSoundManager.new,
        resolveBackupDirectory: () async => null,
      );

      expect(deps.backup, isNull);
    });

    test(
      'se risolvere la storage esterna solleva, il backup e\' assente',
      () async {
        final AppDependencies deps = await buildAppDependencies(
          openLog: () async => const NoopTapLog(),
          createSounds: SilentSoundManager.new,
          resolveBackupDirectory: () async => throw Exception('storage offesa'),
        );

        expect(deps.backup, isNull);
      },
    );

    test('percorso felice: il backup usa il totale e il giorno veri', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kPrefsCounterTotal: 239338,
      });
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'bootstrap_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final AppDependencies deps = await buildAppDependencies(
        openLog: () async => const NoopTapLog(),
        createSounds: SilentSoundManager.new,
        resolveBackupDirectory: () async => tempDir,
      );

      expect(deps.backup, isNotNull);
      await deps.backup!.backupIfNeeded();

      final String today = BackupService.dayKey(DateTime.now());
      final File file = File(
        '${tempDir.path}/$kBackupDirName/${BackupService.fileNameFor(today)}',
      );
      expect(file.existsSync(), isTrue);

      final Map<String, Object?> saved =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(saved[kPrefsCounterTotal], 239338);
    });
  });

  test("il repository parte gia' pronto a contare", () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kPrefsCounterTotal: 7,
    });

    final AppDependencies deps = await buildAppDependencies(
      openLog: () async => const NoopTapLog(),
      createSounds: SilentSoundManager.new,
      resolveBackupDirectory: () async => null,
    );

    expect(deps.repository.total, 7);
  });
}
