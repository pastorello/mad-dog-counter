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
            letterSpacing: 1,
          ),
        ),
        const Text(
          kBrandNameLine2,
          style: TextStyle(
            fontFamily: kBrandFont,
            color: kPrimaryRed,
            fontSize: kHomdWordmarkSize,
            height: 1,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: kHomdTaglineGap),
        const Text(
          kBrandTagline,
          style: TextStyle(
            fontFamily: kBrandFont,
            color: kTextColor,
            fontSize: kHomdTaglineSize,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
