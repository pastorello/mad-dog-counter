/// Il numerone: l'unico protagonista della schermata.
///
/// Sa fare tre cose e nient'altro:
/// - disporre le cifre in slot a larghezza fissa, perché i font brush non
///   hanno cifre tabular e il numero ballerebbe a ogni cifra che cambia;
/// - stare dentro allo schermo, anche col totale a sei cifre;
/// - applicare a ogni cifra la trasformazione dell'effetto in corso, presa
///   dal catalogo.
///
/// Non conosce nessun effetto per nome: aggiungerne uno non si tocca questo
/// file (ANIMATIONS_SPEC → regola 5).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../state/effect_triggers.dart';
import '../effects/boobs_digits.dart';
import '../effects/effect_catalog.dart';

class BigNumber extends StatefulWidget {
  const BigNumber({
    super.key,
    required this.total,
    this.effect,
    this.boobsActive = false,
  });

  final int total;

  /// L'effetto in scena, se ne trasforma le cifre.
  final EffectKind? effect;

  /// Stato persistente delle coppie di 8 adiacenti.
  final bool boobsActive;

  @override
  State<BigNumber> createState() => _BigNumberState();
}

class _BigNumberState extends State<BigNumber> with TickerProviderStateMixin {
  late final AnimationController _effectAnimation = AnimationController(
    vsync: this,
  );
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: kBoobsMorphDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.boobsActive) _morph.value = 1;
    _startEffect();
  }

  @override
  void didUpdateWidget(BigNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effect != oldWidget.effect) _startEffect();
    if (widget.boobsActive != oldWidget.boobsActive) {
      // Il morph vale in entrambi i versi: le cifre tornano normali
      // sfumando, non di scatto.
      widget.boobsActive ? _morph.forward() : _morph.reverse();
    }
  }

  void _startEffect() {
    final EffectKind? effect = widget.effect;
    if (effect == null) {
      _effectAnimation.stop();
      _effectAnimation.value = 0;
      return;
    }
    _effectAnimation
      ..duration = durationOf(effect)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _effectAnimation.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String digits = widget.total.toString();
    // Le coppie si calcolano sul totale corrente; durante il morph inverso
    // il disegno resta al suo posto perché l'opacità scende, non la struttura.
    final Set<int> pairStarts = widget.boobsActive
        ? adjacentEightPairs(widget.total).toSet()
        : const <int>{};

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // La dimensione non può venire dalla sola altezza: il totale del pub è
        // a sei cifre, e sei slot da 0,45 dell'altezza sfondano la larghezza
        // anche sul tablet di produzione. Vince il vincolo più stretto.
        final double byHeight =
            constraints.maxHeight * kBigNumberHeightFraction;
        final double byWidth =
            constraints.maxWidth *
            kBigNumberWidthFraction /
            digits.length /
            kDigitSlotRatio;
        final double size = math.min(byHeight, byWidth);

        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_effectAnimation, _morph]),
          builder: (BuildContext context, Widget? _) {
            final DigitTransform? transform = widget.effect == null
                ? null
                : digitTransforms[widget.effect];

            final List<Widget> slots = <Widget>[];
            for (int i = 0; i < digits.length; i++) {
              // Una coppia di 8 occupa due slot con un disegno solo.
              if (pairStarts.contains(i)) {
                slots.add(
                  _wrap(
                    transform,
                    i,
                    digits.length,
                    SizedBox(
                      width: size * kDigitSlotRatio * 2,
                      child: BoobsDigits(
                        size: size,
                        morph: _morph.value,
                        fallback: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _digitSlot('8', size),
                            _digitSlot('8', size),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                i++; // la coppia consuma due cifre
                continue;
              }

              slots.add(
                _wrap(transform, i, digits.length, _digitSlot(digits[i], size)),
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: slots,
            );
          },
        );
      },
    );
  }

  Widget _wrap(
    DigitTransform? transform,
    int index,
    int digitCount,
    Widget child,
  ) {
    if (transform == null) return child;
    return transform(
      DigitContext(
        index: index,
        digitCount: digitCount,
        progress: _effectAnimation.value,
      ),
      child,
    );
  }

  Widget _digitSlot(String digit, double size) {
    return SizedBox(
      width: size * kDigitSlotRatio,
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
    );
  }
}
