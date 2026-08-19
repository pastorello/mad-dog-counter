/// L'overlay della combo: moltiplicatore, testo celebrativo e i timbri di
/// Ciommo che spuntano dai lati.
///
/// Non entra nella coda effetti: è una proprietà del display, attiva finché la
/// combo è viva (ANIMATIONS_SPEC → regola 3).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

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

  @override
  void didUpdateWidget(ComboOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo.isActive) _visible = widget.combo;
  }

  @override
  void initState() {
    super.initState();
    if (widget.combo.isActive) _visible = widget.combo;
  }

  @override
  Widget build(BuildContext context) {
    final ComboState combo = _visible;

    // A combo mai iniziata non c'è niente da tenere in scena, nemmeno
    // invisibile.
    if (!combo.isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.combo.isActive ? 1 : 0,
        duration: kComboFadeDuration,
        curve: Curves.easeOut,
        child: Stack(
          children: <Widget>[
            // Il glow che scalda l'ambiente attorno al numero: più la combo
            // sale, più è denso.
            Positioned.fill(child: _ComboGlow(combo: combo)),

            for (int i = 0; i < combo.ciommoStamps; i++)
              _CiommoStamp(index: i, key: ValueKey<int>(i)),

            Positioned(
              top: 40,
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

/// Alone caldo dietro il numerone, tanto più intenso quanto sale la combo.
class _ComboGlow extends StatelessWidget {
  const _ComboGlow({required this.combo});

  final ComboState combo;

  @override
  Widget build(BuildContext context) {
    final double intensity = math.min(1, combo.count / kComboThresholds.last);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.7,
          colors: <Color>[
            kCelebrationGold.withValues(alpha: 0.22 * intensity),
            kPrimaryRed.withValues(alpha: 0.12 * intensity),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ),
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
          fontSize: 56,
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
      style: const TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 40,
        color: kPrimaryRed,
        shadows: <Shadow>[Shadow(color: kBackground, blurRadius: 10)],
      ),
    );
  }
}

/// Un timbro "Ciommo Approved" che arriva di schiaffo da un lato, con una
/// rotazione appena diversa a ogni posizione.
class _CiommoStamp extends StatelessWidget {
  const _CiommoStamp({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    // Posizioni alternate destra/sinistra, sfalsate in verticale. Le costanti
    // dipendono dall'indice, non dal caso: due build dello stesso stato
    // devono dare lo stesso risultato.
    final bool onLeft = index.isEven;
    final double top = 90.0 + (index ~/ 2) * 120.0;
    final double angle = (onLeft ? -1 : 1) * (0.12 + (index % 3) * 0.06);

    return Positioned(
      top: top,
      left: onLeft ? 24 : null,
      right: onLeft ? null : 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: kComboStampDuration,
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double t, Widget? child) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            // Lo schiaffo: arriva grande e si assesta.
            child: Transform.scale(scale: 1.6 - 0.6 * t, child: child),
          );
        },
        child: Transform.rotate(
          angle: angle,
          child: Image.asset(
            kImgCiommoApproved,
            height: 96,
            // L'asset e' line-art bianca: la tingiamo del rosso di brand.
            color: kPrimaryRed,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
