/// L'overlay della combo: moltiplicatore e testo celebrativo in alto al
/// centro, e i timbri di Ciommo che salgono dal bordo basso ai due lati del
/// marchio House of Mad Dogs.
///
/// Non entra nella coda effetti: è una proprietà del display, attiva finché la
/// combo è viva (ANIMATIONS_SPEC → regola 3).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../state/combo_machine.dart';
import 'combo_rain.dart';

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
      child: Stack(
        children: <Widget>[
          // Glow e testi sfumano dolcemente a fine combo.
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: widget.combo.isActive ? 1 : 0,
              duration: kComboFadeDuration,
              curve: Curves.easeOut,
              child: Stack(
                children: <Widget>[
                  // Il glow che scalda l'ambiente attorno al numero: più la
                  // combo sale, più è denso.
                  Positioned.fill(child: _ComboGlow(combo: combo)),

                  // Pioggia di bicchierini sullo sfondo: sfuma insieme al
                  // glow, sotto al moltiplicatore e ai testi.
                  const Positioned.fill(child: ComboRain()),

                  Positioned(
                    top: kTopOverlayTop,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: <Widget>[
                        _Multiplier(combo: combo),
                        if (combo.text case final String text)
                          _ComboText(text: text),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // I timbri invece non sfumano: entrano dal basso e dal basso se ne
          // vanno. Per questo stanno fuori dalla dissolvenza.
          Positioned(
            left: 0,
            right: 0,
            bottom: kComboStampBottom,
            child: _CiommoRow(
              count: combo.ciommoStamps,
              visible: widget.combo.isActive,
            ),
          ),
        ],
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

/// La fila dei timbri lungo il bordo basso: si aprono a ventaglio ai due lati
/// del marchio HoMD, che sta al centro e non va mai coperto.
class _CiommoRow extends StatelessWidget {
  const _CiommoRow({required this.count, required this.visible});

  final int count;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    // Indici pari a sinistra, dispari a destra. A sinistra si stampano in
    // ordine inverso, così i timbri nuovi finiscono sempre verso l'esterno.
    final List<int> left = <int>[for (int i = 0; i < count; i += 2) i].reversed
        .toList();
    final List<int> right = <int>[for (int i = 1; i < count; i += 2) i];

    return FittedBox(
      // Rete di sicurezza: con cinque timbri su uno schermo stretto la fila
      // sforerebbe. Meglio rimpicciolire tutto che un overflow.
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final int i in left)
            _CiommoStamp(index: i, visible: visible, key: ValueKey<int>(i)),
          // La corsia del marchio: vuota di proposito.
          const SizedBox(width: kHomdMarkLane),
          for (final int i in right)
            _CiommoStamp(index: i, visible: visible, key: ValueKey<int>(i)),
        ],
      ),
    );
  }
}

/// Un timbro "Ciommo Approved": sale dal bordo basso, e quando la combo
/// finisce riscende da dove è arrivato.
class _CiommoStamp extends StatelessWidget {
  const _CiommoStamp({super.key, required this.index, required this.visible});

  final int index;

  /// La combo è ancora viva. A `false` il timbro se ne torna giù.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    // L'inclinazione dipende dall'indice, non dal caso: due build dello stesso
    // stato devono dare lo stesso risultato.
    final double angle = (index.isEven ? -1 : 1) * (0.06 + (index % 3) * 0.04);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: visible ? 1 : 0),
      duration: visible ? kComboStampDuration : kComboStampExitDuration,
      // In salita rimbalza appena; in discesa scivola via e basta.
      curve: visible ? Curves.easeOutBack : Curves.easeIn,
      builder: (BuildContext context, double t, Widget? child) {
        return Transform.translate(
          // A t=0 il timbro è tutto sotto il bordo dello schermo, a t=1 è al
          // suo posto. Lo Stack che lo contiene ritaglia: quello che scende
          // sotto il bordo sparisce da sé.
          offset: Offset(0, (1 - t) * (kComboStampHeight + kComboStampBottom)),
          child: child,
        );
      },
      child: Builder(
        builder: (BuildContext context) {
          // L'asset e' 924x1316: senza cacheHeight Flutter lo decodifica a
          // piena risoluzione (~4,9 MB in RAM) per poi disegnarlo alto
          // kComboStampHeight. In fisici, cosi' resta nitido anche sul
          // tablet ad alta densita' (P1 dell'audit prestazioni).
          final int cacheHeight =
              (kComboStampHeight * MediaQuery.devicePixelRatioOf(context))
                  .round();
          return Transform.rotate(
            angle: angle,
            child: Image.asset(
              kImgCiommoApproved,
              height: kComboStampHeight,
              cacheHeight: cacheHeight,
              // L'asset e' line-art bianca: la tingiamo del rosso di brand.
              color: kPrimaryRed,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                  const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
