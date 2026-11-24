/// L'overlay della combo: moltiplicatore e testo celebrativo in alto al
/// centro, col bagliore che scalda tutto lo schermo.
///
/// Il timbro di Ciommo non vive più qui: dalla v2 è un modulo suo
/// (`ciommo_slam.dart`), un timbro unico gigante che piomba sul numerone a
/// ogni multiplo dell'intervallo.
///
/// Non entra nella coda effetti: è una proprietà del display, attiva finché la
/// combo è viva (ANIMATIONS_SPEC → regola 3).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../state/combo_machine.dart';

class ComboOverlay extends StatefulWidget {
  const ComboOverlay({super.key, required this.combo});

  final ComboState combo;

  @override
  State<ComboOverlay> createState() => _ComboOverlayState();
}

class _ComboOverlayState extends State<ComboOverlay> {
  /// L'ultimo stato attivo, tenuto in vita per la durata della dissolvenza.
  ///
  /// Senza questo la combo sparirebbe di scatto: nell'istante in cui finisce,
  /// il conteggio va a zero e non ci sarebbe più niente da sfumare. La spec
  /// chiede invece che «gli effetti sfumano dolcemente».
  ComboState _visible = ComboState.idle;

  /// Smonta l'overlay a dissolvenza conclusa: senza, bagliore e timbri
  /// restano nell'albero (a opacità/fuori schermo) fino alla fine della
  /// sessione, tenendo vive le immagini dei timbri per niente (P3
  /// dell'audit prestazioni).
  Timer? _dismissTimer;

  @override
  void didUpdateWidget(ComboOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo.isActive) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _visible = widget.combo;
    } else if (oldWidget.combo.isActive) {
      _scheduleDismiss();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.combo.isActive) _visible = widget.combo;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(kComboDismissDelay, () {
      if (mounted) setState(() => _visible = ComboState.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ComboState combo = _visible;

    // A combo mai iniziata non c'è niente da tenere in scena, nemmeno
    // invisibile.
    if (!combo.isActive) return const SizedBox.shrink();

    return IgnorePointer(
      // Glow e testi sfumano dolcemente a fine combo.
      child: AnimatedOpacity(
        opacity: widget.combo.isActive ? 1 : 0,
        duration: kComboFadeDuration,
        curve: Curves.easeOut,
        child: Stack(
          children: <Widget>[
            // Il glow che scalda l'ambiente attorno al numero: più la
            // combo sale, più è denso.
            Positioned.fill(child: _ComboGlow(combo: combo)),

            Positioned(
              top: kTopOverlayTop,
              left: 0,
              right: 0,
              child: Column(
                children: <Widget>[
                  _Multiplier(combo: combo),
                  if (combo.text case final String text) _ComboText(text: text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chiave del bagliore: serve ai test per verificare che copra tutto.
const Key kComboGlowKey = ValueKey<String>('combo-glow');

/// Alone caldo dietro il numerone, tanto più intenso quanto sale la combo.
///
/// Copre l'intero sfondo, angoli e zona -1 compresi: il bagliore è dello
/// schermo, non della sola area sotto il numerone.
class _ComboGlow extends StatelessWidget {
  const _ComboGlow({required this.combo});

  final ComboState combo;

  @override
  Widget build(BuildContext context) {
    final double intensity = math.min(1, combo.count / kComboThresholds.last);
    return DecoratedBox(
      key: kComboGlowKey,
      // Tinta piatta sotto: è quella che arriva dove il gradiente sfuma, cioè
      // agli angoli e sulla fascia sinistra.
      decoration: BoxDecoration(
        color: kPrimaryRed.withValues(alpha: kComboGlowBaseAlpha * intensity),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: kComboGlowRadius,
            colors: <Color>[
              kCelebrationGold.withValues(alpha: 0.22 * intensity),
              kPrimaryRed.withValues(alpha: 0.12 * intensity),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.45, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Il moltiplicatore che sale.
class _Multiplier extends StatelessWidget {
  const _Multiplier({required this.combo});

  final ComboState combo;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      // Uno scatto di scala a ogni tap: il moltiplicatore "pompa".
      scale: 1 + math.min(0.35, combo.count * 0.02),
      duration: kTapPulseDuration,
      curve: Curves.easeOut,
      child: Text(
        'x${combo.multiplier}',
        style: const TextStyle(
          fontFamily: kDisplayFont,
          fontSize: kComboMultiplierSize,
          height: 1,
          color: kCelebrationGold,
          shadows: <Shadow>[Shadow(color: kPrimaryRed, blurRadius: 18)],
        ),
      ),
    );
  }
}

/// Il testo celebrativo della soglia raggiunta.
class _ComboText extends StatelessWidget {
  const _ComboText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: ValueKey<String>(text),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: kDisplayFont,
        fontSize: kComboTextSize,
        height: 1,
        color: kPrimaryRed,
        shadows: <Shadow>[Shadow(color: kBackground, blurRadius: 10)],
      ),
    );
  }
}
