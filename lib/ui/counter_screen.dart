/// La schermata unica dell'app.
///
/// Scheletro MVP: numerone, zone di tap, bandierina. Il motore effetti,
/// il pulsante panico e il pannello impostazioni arrivano dopo — le loro
/// posizioni nel layout sono già riservate qui.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../state/counter_provider.dart';
import '../state/effect_triggers.dart';
import '../state/effects_provider.dart';
import 'effects/combo_overlay.dart';
import 'effects/effect_catalog.dart';
import 'effects/idle_face.dart';
import 'settings_panel.dart';
import 'widgets/big_number.dart';
import 'widgets/dutch_flag_divider.dart';
import 'widgets/panic_button.dart';
import 'widgets/settings_gear.dart';

class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  DateTime? _lastTap;
  bool _settingsOpen = false;

  void _openSettings() {
    // Equivalente a un killAll() silenzioso: gli effetti in corso si fermano,
    // ma senza l'esplosione del pulsante panico.
    ref.read(effectsEngineProvider).killAll(silent: true);
    setState(() => _settingsOpen = true);
  }

  void _closeSettings() {
    // Il debounce riparte da qui: il primo tap dopo la chiusura non deve
    // essere scartato perche' "troppo vicino" a quello di tre minuti fa.
    _lastTap = null;
    setState(() => _settingsOpen = false);
  }

  /// Debounce contro i doppi tocchi hardware, senza penalizzare le combo.
  bool _debounced() {
    final DateTime now = ref.read(clockProvider)();
    final DateTime? last = _lastTap;
    if (last != null && now.difference(last) < kTapDebounce) return true;
    _lastTap = now;
    return false;
  }

  void _onIncrement() {
    if (_settingsOpen || _debounced()) return;
    HapticFeedback.lightImpact();
    ref.read(counterActionsProvider).increment();
  }

  void _onDecrement() {
    if (_settingsOpen || _debounced()) return;
    HapticFeedback.selectionClick();
    ref.read(counterActionsProvider).decrement();
  }

  @override
  Widget build(BuildContext context) {
    // Il totale è già in memoria all'avvio, quindi lo stream non passa mai da
    // uno stato di caricamento visibile. Il fallback esiste solo per sicurezza.
    final int total = ref
        .watch(counterTotalProvider)
        .maybeWhen(data: (int value) => value, orElse: () => kInitialCount);

    // Tiene vivo il controllo del backup finché la schermata è a video.
    ref.watch(backupWatcherProvider);

    final EffectsState effects = ref
        .watch(effectsStateProvider)
        .maybeWhen(
          data: (EffectsState value) => value,
          orElse: () => const EffectsState(),
        );

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: <Widget>[
          // Il numerone sta sotto: le zone di tap ci passano sopra.
          Positioned.fill(
            child: Center(
              child: BigNumber(
                total: total,
                effect: effects.current,
                boobsActive: effects.boobsActive,
              ),
            ),
          ),

          // Zone di tap invisibili, larghe tutto lo schermo in altezza.
          Positioned.fill(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: (kDecrementZoneWidthFraction * 100).round(),
                  child: _TapZone(
                    onTap: _onDecrement,
                    highlight: kAccentBlue,
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 24),
                        child: Icon(
                          Icons.chevron_left,
                          size: 48,
                          color: Color(0x33F0F0F0),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - kDecrementZoneWidthFraction) * 100).round(),
                  child: _TapZone(onTap: _onIncrement, highlight: kPrimaryRed),
                ),
              ],
            ),
          ),

          // Bandierina olandese: separatore firma del brand.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DutchFlagDivider(),
          ),

          // L'overlay della combo: sotto agli effetti in coda, sopra il
          // numerone.
          Positioned.fill(child: ComboOverlay(combo: effects.combo)),

          // La faccina annoiata: sopra il numerone, sotto agli effetti.
          if (effects.idleFaceVisible || effects.idleWaking)
            Positioned.fill(child: IdleFace(waking: effects.idleWaking)),

          // L'overlay a tutto schermo dell'effetto in scena, per gli effetti
          // che ne hanno uno. Quelli che trasformano solo le cifre agiscono
          // dentro al numerone.
          if (effects.current case final EffectKind kind)
            if (effectOverlays[kind] case final WidgetBuilder build)
              Positioned.fill(child: IgnorePointer(child: build(context))),

          // Il pulsante panico sta sopra le zone di tap: i suoi tocchi non
          // devono mai finire nel contatore.
          Positioned(
            top: 0,
            right: 0,
            child: PanicButton(
              onPressed: () => ref.read(effectsEngineProvider).killAll(),
            ),
          ),

          // L'esplosione copre tutto, pulsante panico compreso.
          if (effects.panicking) const Positioned.fill(child: PanicBlast()),

          // Ingranaggio impostazioni: angolo basso destro, lontano dal
          // pulsante panico quanto basta da non confonderli.
          Positioned(
            bottom: 0,
            right: 0,
            child: SettingsGear(onLongPress: _openSettings),
          ),

          // Il pannello copre tutto: mentre e' aperto non si conta.
          if (_settingsOpen)
            Positioned.fill(child: SettingsPanel(onClose: _closeSettings)),
        ],
      ),
    );
  }
}

/// Zona di tap invisibile che si illumina appena al tocco.
class _TapZone extends StatefulWidget {
  const _TapZone({required this.onTap, required this.highlight, this.child});

  final VoidCallback onTap;
  final Color highlight;
  final Widget? child;

  @override
  State<_TapZone> createState() => _TapZoneState();
}

class _TapZoneState extends State<_TapZone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: kTapPulseDuration,
        color: _pressed
            ? widget.highlight.withValues(alpha: 0.12)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
