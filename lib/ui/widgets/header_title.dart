/// L'intestazione «MAD DOG COUNTER» al bordo alto.
///
/// In Oswald Bold come il marchio, mai col font display: è un'insegna, non
/// una celebrazione. La fascia alta resta la fascia degli eventi: quando
/// serve a loro (combo, strike, faccina annoiata) l'intestazione si
/// dissolve e torna a scena finita (DECISIONS → 01). Decorativa: non
/// intercetta tap.
library;

import 'package:flutter/widgets.dart';

import '../../config.dart';

class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key, required this.visible});

  /// Falso mentre la fascia alta è degli eventi: l'intestazione cede il
  /// passo senza mai spostarsi.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: kHeaderFadeDuration,
        curve: Curves.easeOut,
        child: const Text(
          kHeaderText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kBrandFont,
            fontWeight: FontWeight.w700,
            fontSize: kHeaderTextSize,
            letterSpacing: kHeaderTracking,
            height: 1,
            color: kHeaderColor,
          ),
        ),
      ),
    );
  }
}
