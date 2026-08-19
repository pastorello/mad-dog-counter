/// Una cifra che rolla, stile slot machine verticale.
///
/// UX_UI_SPEC → Micro-interazioni: le cifre rollano invece di cambiare a
/// scatto. Rollano solo quelle che cambiano davvero: su 239338 → 239339 si
/// muovono le unità, le altre cinque restano ferme.
///
/// Il verso segue il conteggio: in salita la cifra nuova entra dal basso, in
/// discesa dall'alto. È un pezzo in più del feedback che distingue il −1 dal
/// +1 (FUNCTIONAL_SPEC → Interazioni base).
library;

import 'package:flutter/material.dart';

/// Come rendere una cifra alla dimensione data.
typedef DigitBuilder = Widget Function(String digit);

class RollingDigit extends StatelessWidget {
  const RollingDigit({
    super.key,
    required this.previous,
    required this.current,
    required this.progress,
    required this.rollingUp,
    required this.height,
    required this.builder,
  });

  /// La cifra da cui si viene. Stringa vuota se la cifra non c'era.
  final String previous;

  /// La cifra a cui si arriva.
  final String current;

  /// Avanzamento del roll, da 0 a 1.
  final double progress;

  /// Verso del roll: true quando il contatore sale.
  final bool rollingUp;

  /// Altezza della finestra dello slot.
  final double height;

  final DigitBuilder builder;

  @override
  Widget build(BuildContext context) {
    // Niente da rollare: la cifra è la stessa, o il roll è finito.
    if (previous == current || progress >= 1) {
      return builder(current);
    }

    final double t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final double direction = rollingUp ? 1 : -1;

    // La cifra vecchia esce, la nuova entra dalla parte opposta.
    final double outgoingDy = -direction * t * height;
    final double incomingDy = direction * (1 - t) * height;

    // Il taglio serve solo mentre si rolla: le cifre hanno un glow rosso che
    // deborda, e clippare sempre lo mangerebbe anche da fermi.
    return ClipRect(
      child: SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (previous.isNotEmpty)
              Transform.translate(
                offset: Offset(0, outgoingDy),
                child: builder(previous),
              ),
            Transform.translate(
              offset: Offset(0, incomingDy),
              child: builder(current),
            ),
          ],
        ),
      ),
    );
  }
}

/// Allinea due numeri a destra, riempiendo a sinistra con stringhe vuote.
///
/// Le posizioni vanno contate dalle unità, non dall'inizio: passando da 99 a
/// 100 le unità restano unità, mentre allineando a sinistra la prima cifra
/// rollerebbe da 9 a 1 e la terza spunterebbe dal nulla.
List<({String previous, String current})> alignDigits(
  String previous,
  String current,
) {
  final int width = current.length > previous.length
      ? current.length
      : previous.length;
  final String p = previous.padLeft(width);
  final String c = current.padLeft(width);

  return <({String previous, String current})>[
    for (int i = 0; i < width; i++)
      (previous: p[i] == ' ' ? '' : p[i], current: c[i] == ' ' ? '' : c[i]),
  ];
}
