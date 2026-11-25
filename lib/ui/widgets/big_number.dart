/// Il numerone: l'unico protagonista della schermata.
///
/// Sa fare tre cose e nient'altro:
/// - disporre le cifre in slot a larghezza fissa, perché i font brush non
///   hanno cifre tabular e il numero ballerebbe a ogni cifra che cambia;
/// - stare dentro allo schermo, col totale sempre a sei cifre;
/// - applicare a ogni cifra la trasformazione dell'effetto in corso, presa
///   dal catalogo.
///
/// Non conosce nessun effetto per nome: aggiungerne uno non si tocca questo
/// file (ANIMATIONS_SPEC → regola 5).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../state/effect_triggers.dart';
import '../effects/boobs_digits.dart';
import '../effects/effect_catalog.dart';
import 'rolling_digit.dart';

/// Le cifre da disegnare per [total]: sempre [kCounterDigits], con gli zeri
/// davanti. Oltre quella larghezza il numero si allunga da sé.
String _digitsOf(int total) => total.toString().padLeft(kCounterDigits, '0');

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

  /// Posa + espansione delle tette fino ai bordi dello schermo (v3): parte
  /// quando il morph è concluso, e alla fine la scena si chiude da sola.
  late final AnimationController _blowUp = AnimationController(
    vsync: this,
    duration: kBoobsBlowUpDuration,
  );

  /// La scena di QUESTA coppia è conclusa: le cifre sono tornate normali
  /// anche se il totale resta sugli 8 adiacenti (es. fermo su 88).
  bool _blownUp = false;

  /// Il roll delle cifre. Uno solo per tutto il numero: le cifre cambiano
  /// tutte nello stesso istante, e quelle che non cambiano si disegnano ferme.
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: kDigitRollDuration,
    value: 1, // a riposo: nessun roll in corso
  );

  /// Il numero da cui si sta rollando.
  String _previousDigits = '';

  /// Il contatore stava salendo. Guida il verso del roll.
  bool _rollingUp = true;

  @override
  void initState() {
    super.initState();
    _previousDigits = _digitsOf(widget.total);
    // Montato a coppia già attiva (ricostruzione a scena in corso): la scena
    // non si rigioca, le cifre restano cifre.
    if (widget.boobsActive) _blownUp = true;
    _morph.addStatusListener(_onMorphStatus);
    _blowUp.addStatusListener(_onBlowUpStatus);
    _startEffect();
  }

  /// A morph concluso parte la posa e poi l'espansione, una volta sola per
  /// coppia formata.
  void _onMorphStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        widget.boobsActive &&
        !_blownUp) {
      _blowUp.forward(from: 0);
    }
  }

  void _onBlowUpStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Fine scena: il disegno è già sfumato a tutto schermo, le cifre sono
    // già tornate. Da qui in poi si disegnano cifre normali e basta.
    setState(() {
      _blownUp = true;
      _morph.value = 0;
    });
  }

  @override
  void didUpdateWidget(BigNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.total != oldWidget.total) {
      // Un tap può arrivare mentre il roll precedente è ancora in corso
      // (le combo sono fatte apposta): si riparte da quello che si vede
      // adesso, cioè dal numero vecchio, senza scatti.
      _previousDigits = _digitsOf(oldWidget.total);
      _rollingUp = widget.total > oldWidget.total;
      _roll.forward(from: 0);
    }
    if (widget.effect != oldWidget.effect) _startEffect();
    if (widget.boobsActive != oldWidget.boobsActive) {
      if (widget.boobsActive) {
        // Nuova coppia: la scena riparte da capo.
        _blownUp = false;
        _blowUp.value = 0;
        _morph.forward(from: 0);
      } else {
        // Coppia rotta a scena in corso: l'espansione si ferma e il morph
        // inverso sfuma il disegno, non uno stacco secco. A scena già
        // conclusa non c'è niente da sfumare.
        _blowUp.stop();
        if (!_blownUp) _morph.reverse();
      }
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
    _blowUp.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String digits = _digitsOf(widget.total);
    // Gli zeri davanti spostano a destra le cifre vere, quindi gli indici che
    // arrivano dal trigger (calcolati sul numero nudo) vanno traslati.
    final int pad = digits.length - widget.total.toString().length;
    // Le coppie si calcolano sul totale corrente; a scena conclusa
    // ([_blownUp]) le cifre restano cifre anche se la coppia è ancora lì.
    final Set<int> pairStarts = widget.boobsActive && !_blownUp
        ? adjacentEightPairs(widget.total).map((int i) => i + pad).toSet()
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

        // Le posizioni si contano dalle unità: passando da 99 a 100 le unità
        // restano unità, mentre allineando a sinistra la prima cifra
        // rollerebbe da 9 a 1.
        final List<({String previous, String current})> aligned = alignDigits(
          _previousDigits,
          digits,
        );

        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _effectAnimation,
            _morph,
            _blowUp,
            _roll,
          ]),
          builder: (BuildContext context, Widget? _) {
            final DigitTransform? transform = widget.effect == null
                ? null
                : digitTransforms[widget.effect];

            // Geometria dell'espansione a tutto schermo: la fila di slot è
            // centrata, quindi il posto di ogni coppia si ricava da indice e
            // larghezza di slot. Il disegno vola da lì al centro dello
            // schermo e scala fino a toccare i bordi.
            final double slotWidth = size * kDigitSlotRatio;
            final double rowLeft =
                (constraints.maxWidth - digits.length * slotWidth) / 2;
            final double blowScale = boobsBlowUpScale(
              Size(constraints.maxWidth, constraints.maxHeight),
              Size(slotWidth * 2, size),
            );

            final List<Widget> slots = <Widget>[];
            for (int i = 0; i < digits.length; i++) {
              // Una coppia di 8 occupa due slot con un disegno solo.
              if (pairStarts.contains(i)) {
                // Dal centro della coppia (gli slot i e i+1) al centro dello
                // schermo. La fila è già centrata in verticale.
                final double pairCenterX = rowLeft + (i + 1) * slotWidth;
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
                        blowUp: _blowUp.value,
                        blowUpScale: blowScale,
                        blowUpShift: Offset(
                          constraints.maxWidth / 2 - pairCenterX,
                          0,
                        ),
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
                _wrap(
                  transform,
                  i,
                  digits.length,
                  SizedBox(
                    width: size * kDigitSlotRatio,
                    child: RollingDigit(
                      previous: aligned[i].previous,
                      current: aligned[i].current,
                      progress: _roll.value,
                      rollingUp: _rollingUp,
                      height: size,
                      builder: (String digit) => _digitGlyph(digit, size),
                    ),
                  ),
                ),
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

  Widget _digitSlot(String digit, double size) =>
      SizedBox(width: size * kDigitSlotRatio, child: _digitGlyph(digit, size));

  Widget _digitGlyph(String digit, double size) {
    return SizedBox(
      width: size * kDigitSlotRatio,
      child: Text(
        digit,
        textAlign: TextAlign.center,
        style: TextStyle(
          // Il font delle SOLE cifre (v2, DECISIONS → 05): Passion One.
          // Creepster resta la voce dei testi celebrativi e dello STRIKE!.
          fontFamily: kCounterFont,
          fontWeight: FontWeight.w700,
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
