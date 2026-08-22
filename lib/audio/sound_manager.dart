/// Riproduzione degli effetti sonori.
///
/// Regola d'oro 2: l'audio è fire-and-forget. Un file mancante, un decoder che
/// litiga o le casse staccate non devono MAI diventare un'eccezione che risale
/// fino al tap. Qui dentro si inghiotte tutto: al massimo il pub resta muto,
/// ma il conteggio non si ferma.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../config.dart';

/// Contratto del gestore audio, così i test non toccano il vero player.
abstract class SoundManager {
  /// Se false, [play] non fa nulla.
  bool get enabled;
  set enabled(bool value);

  /// Scalda la cache degli asset. Non solleva mai.
  Future<void> preload();

  /// Riproduce un suono. Non attende la fine e non solleva mai.
  ///
  /// [rate] serve al pitch crescente dei pop durante la combo: si riusa
  /// `tap_pop.wav` accelerandolo, invece di avere un file per livello.
  void play(String asset, {double rate = 1.0});

  /// Ferma tutto quello che sta suonando. Usato dal kill switch.
  void stopAll();

  Future<void> dispose();
}

/// Implementazione su `audioplayers`.
///
/// Usa un pool di player in round-robin: durante una combo i pop si
/// sovrappongono, e un player solo taglierebbe il suono precedente a ogni tap.
class AudioPlayersSoundManager implements SoundManager {
  AudioPlayersSoundManager({
    int poolSize = kSfxPoolSize,
    AudioPlayer Function() playerFactory = _defaultPlayer,
  }) : _players = List<AudioPlayer>.generate(poolSize, (_) => playerFactory());

  /// Player di default: gli si passa a mano solo nei test, per iniettare
  /// finti player senza toccare il pool round-robin sottostante.
  static AudioPlayer _defaultPlayer() =>
      AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);

  final List<AudioPlayer> _players;
  int _next = 0;
  bool _enabled = kSoundEnabledDefault;
  bool _disposed = false;

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) {
    _enabled = value;
    if (!value) stopAll();
  }

  @override
  Future<void> preload() async {
    try {
      await AudioCache.instance.loadAll(kAllSfx);
    } catch (_) {
      // Il precaricamento è un'ottimizzazione: se fallisce, i suoni si
      // caricheranno al primo uso (o non si sentiranno, e pazienza).
    }
  }

  @override
  void play(String asset, {double rate = 1.0}) {
    if (!_enabled || _disposed) return;
    final AudioPlayer player = _players[_next];
    _next = (_next + 1) % _players.length;
    unawaited(_playOn(player, asset, rate));
  }

  Future<void> _playOn(AudioPlayer player, String asset, double rate) async {
    try {
      await player.stop();
      // Sempre, anche a 1.0: il rate è uno stato del player, non del suono.
      // Saltarlo quando vale 1.0 lasciava appiccicato al player il pitch
      // dell'ultima combo, e il pop accelerato a 1.8x se lo ritrovava
      // addosso il suono successivo che finiva su quel player del pool —
      // i fuochi dei 100 suonavano stonati dopo una combo veloce.
      await player.setPlaybackRate(rate);
      await player.play(AssetSource(asset));
    } catch (_) {
      // Muto e avanti: vedi il commento in testa al file.
    }
  }

  @override
  void stopAll() {
    for (final AudioPlayer player in _players) {
      try {
        unawaited(player.stop().catchError((Object _) {}));
      } catch (_) {
        // stop() puo' anche lanciare in modo sincrono, prima di restituire
        // il Future su cui aggancia catchError: va inghiottito anche quello.
      }
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final AudioPlayer player in _players) {
      try {
        await player.dispose();
      } catch (_) {
        // idem
      }
    }
  }
}

/// Gestore che non suona nulla ma si comporta come gli altri.
///
/// Usato nei test e come rete di sicurezza se l'audio non si inizializza:
/// l'app deve contare lo stesso.
class SilentSoundManager implements SoundManager {
  @override
  bool enabled = kSoundEnabledDefault;

  @override
  Future<void> preload() async {}

  @override
  void play(String asset, {double rate = 1.0}) {}

  @override
  void stopAll() {}

  @override
  Future<void> dispose() async {}
}
