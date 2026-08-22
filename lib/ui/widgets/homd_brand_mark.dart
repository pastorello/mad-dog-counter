/// Il marchio completo in fondo alla schermata: bicchiere, "HOUSE OF MAD
/// DOGS" e la tagline, impilati come nel sottobicchiere ufficiale del
/// committente. `HomdMark` da solo resta il solo bicchiere (lo riusa anche
/// lo splash, affiancato al testo invece che sopra) — questo è la
/// composizione completa, un modulo a parte apposta per non toccare l'altro.
library;

import 'package:flutter/material.dart';

import '../../config.dart';
import 'homd_mark.dart';

class HomdBrandMark extends StatelessWidget {
  const HomdBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    // Il marchio ha una sua grandezza di riposo (kHomdMarkSize e compagni),
    // ma si tiene dentro due limiti invece di sconfinare: in altezza non
    // sale fin sul numerone, in larghezza non esce dalla corsia che i timbri
    // di Ciommo gli lasciano libera. Sul tablet di produzione nessuno dei
    // due morde, e il marchio resta a grandezza piena.
    final Size screen = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screen.height * kHomdMarkMaxHeightFraction,
        maxWidth:
            screen.width * kHomdMarkLaneFraction - kHomdMarkLaneMargin * 2,
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: _content()),
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const HomdMark(size: kHomdMarkSize),
        SizedBox(height: kHomdWordmarkGap),
        const Text(
          kBrandNameLine1,
          style: TextStyle(
            fontFamily: kBrandFont,
            color: kPrimaryRed,
            fontSize: kHomdWordmarkSize,
            height: 1,
            letterSpacing: kHomdWordmarkTracking,
          ),
        ),
        const Text(
          kBrandNameLine2,
          style: TextStyle(
            fontFamily: kBrandFont,
            color: kPrimaryRed,
            fontSize: kHomdWordmarkSize,
            height: 1,
            letterSpacing: kHomdWordmarkTracking,
          ),
        ),
        SizedBox(height: kHomdTaglineGap),
        const Text(
          kBrandTagline,
          style: TextStyle(
            fontFamily: kBrandFont,
            color: kTextColor,
            fontSize: kHomdTaglineSize,
            letterSpacing: kHomdTaglineTracking,
          ),
        ),
      ],
    );
  }
}
