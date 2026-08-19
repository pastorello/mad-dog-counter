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
import 'widgets/dutch_flag_divider.dart';

class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  DateTime? _lastTap;

  /// Debounce contro i doppi tocchi hardware, senza penalizzare le combo.
  bool _debounced() {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastTap;
    if (last != null && now.difference(last) < kTapDebounce) return true;
    _lastTap = now;
    return false;
  }

  void _onIncrement() {
    if (_debounced()) return;
    HapticFeedback.lightImpact();
    ref.read(counterActionsProvider).increment();
  }

  void _onDecrement() {
    if (_debounced()) return;
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

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: <Widget>[
          // Il numerone sta sotto: le zone di tap ci passano sopra.
          Positioned.fill(
            child: Center(child: _BigNumber(total: total)),
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

          // TODO: pulsante panico (alto destro) — FUNCTIONAL_SPEC → Kill switch.
          // TODO: ingranaggio impostazioni (basso destro, pressione lunga 3 s).
          // TODO: overlay del motore effetti, sopra a tutto tranne il panico.
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

/// Il numerone: l'unico protagonista della schermata.
///
/// Le cifre stanno in slot a larghezza fissa perché i font brush non hanno
/// cifre tabular e il numero ballerebbe a ogni cambio (UX_UI_SPEC → Tipografia).
class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final String digits = total.toString();
    final double size = MediaQuery.sizeOf(context).height * 0.45;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final String digit in digits.split(''))
          SizedBox(
            width: size * 0.62, // slot a larghezza fissa
            child: Text(
              digit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: size,
                height: 1,
                color: kTextColor,
                shadows: const <Shadow>[
                  Shadow(color: kPrimaryRed, blurRadius: 24),
                  Shadow(color: kPrimaryRed, blurRadius: 48),
                ],
              ),
            ),
          ),
        // TODO: roll verticale della cifra che cambia (kDigitRollDuration).
      ],
    );
  }
}
