import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/audio/sound_manager.dart';
import 'package:mocktail/mocktail.dart';

/// [AudioPlayersSoundManager] testato con player finti, iniettati con la
/// factory: cosi' si verifica il pool round-robin, il kill switch e
/// l'inghiottimento delle eccezioni (regola d'oro 2) senza toccare
/// l'audio vero.
class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  setUpAll(() {
    registerFallbackValue(AssetSource('sounds/tap_pop.wav'));
  });

  late List<_MockAudioPlayer> players;

  AudioPlayersSoundManager buildManager({int poolSize = 3}) {
    players = List<_MockAudioPlayer>.generate(poolSize, (_) {
      final _MockAudioPlayer player = _MockAudioPlayer();
      when(() => player.stop()).thenAnswer((_) async {});
      when(() => player.play(any())).thenAnswer((_) async {});
      when(() => player.setPlaybackRate(any())).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      return player;
    });
    int next = 0;
    return AudioPlayersSoundManager(
      poolSize: poolSize,
      playerFactory: () => players[next++],
    );
  }

  group('pool round-robin', () {
    test('ruota fra i player nell\'ordine di creazione', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 3);

      manager.play('a.wav');
      manager.play('b.wav');
      manager.play('c.wav');
      manager.play('d.wav'); // torna al primo player del pool
      await pumpEventQueue();

      verify(() => players[0].play(any())).called(2);
      verify(() => players[1].play(any())).called(1);
      verify(() => players[2].play(any())).called(1);
    });

    test('imposta il playback rate solo se diverso da 1.0', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 1);

      manager.play('a.wav');
      await pumpEventQueue();
      verifyNever(() => players[0].setPlaybackRate(any()));

      manager.play('a.wav', rate: 1.4);
      await pumpEventQueue();
      verify(() => players[0].setPlaybackRate(1.4)).called(1);
    });
  });

  group('enabled', () {
    test('a false ferma tutti i player del pool', () {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 3);

      manager.enabled = false;

      for (final _MockAudioPlayer player in players) {
        verify(() => player.stop()).called(1);
      }
    });

    test('a false impedisce nuovi play', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 2);
      manager.enabled = false;

      manager.play('a.wav');
      await pumpEventQueue();

      for (final _MockAudioPlayer player in players) {
        verifyNever(() => player.play(any()));
      }
    });

    test('a true si torna a suonare', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 1);
      manager.enabled = false;
      manager.enabled = true;

      manager.play('a.wav');
      await pumpEventQueue();

      verify(() => players[0].play(any())).called(1);
    });
  });

  group('robustezza (regola d\'oro 2)', () {
    test('un\'eccezione da stop() durante play non risale', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 1);
      when(() => players[0].stop()).thenThrow(Exception('cassa scollegata'));

      manager.play('a.wav');
      await pumpEventQueue();
      // Se l'eccezione fosse risalita, pumpEventQueue l'avrebbe fatta
      // esplodere come errore di test non gestito: arrivare qui basta.
    });

    test('un\'eccezione da play() non risale', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 1);
      when(() => players[0].play(any())).thenThrow(Exception('decoder offeso'));

      manager.play('a.wav');
      await pumpEventQueue();
    });

    test('un\'eccezione da stop() dentro stopAll() non risale', () {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 2);
      when(() => players[0].stop()).thenThrow(Exception('offeso'));

      expect(manager.stopAll, returnsNormally);
    });

    test('un\'eccezione da dispose() non risale', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 2);
      when(() => players[0].dispose()).thenThrow(Exception('offeso'));

      await expectLater(manager.dispose(), completes);
      verify(() => players[1].dispose()).called(1);
    });

    test('dopo dispose() play() non fa piu nulla', () async {
      final AudioPlayersSoundManager manager = buildManager(poolSize: 1);
      await manager.dispose();

      manager.play('a.wav');
      await pumpEventQueue();

      verifyNever(() => players[0].play(any()));
    });
  });
}
