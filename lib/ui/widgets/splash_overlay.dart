/// Lo splash: il logo House of Mad Dogs sopra la schermata, che svanisce.
///
/// FUNCTIONAL_SPEC → Avvio chiede uno splash a tema e di essere «pronti a
/// contare in meno di 2 secondi». Le due cose andrebbero in conflitto se lo
/// splash fosse una schermata a sé che ritarda il contatore, quindi non lo è:
/// il contatore è già montato e già vivo sotto, e questo overlay non
/// intercetta i tocchi. Un barista che tappa mentre il logo è ancora a video
/// conta il suo cicchetto — perdere quel tap sarebbe la regola d'oro 1 rotta
/// per un'animazione.
///
/// La composizione segue il sottobicchiere ufficiale
/// (`design/raw/logo_house_of_mad_dogs_sottobicchiere.jpg`), adattata al
/// landscape: riga del pub in alto, bicchiere e lettering affiancati invece
/// che impilati, bandierina in basso.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../config.dart';
import 'dutch_flag_divider.dart';
import 'homd_mark.dart';

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, this.onFinished});

  /// Chiamata quando la dissolvenza è finita e l'overlay può sparire.
  final VoidCallback? onFinished;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  bool _visible = true;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    // Un Timer e non Future.delayed: questo si cancella. Un future in volo
    // sopravvive al widget e nei test resta pendente dopo la dispose.
    _hold = Timer(kSplashHold, () {
      _hold = null;
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: kSplashFade,
        curve: Curves.easeOut,
        onEnd: () {
          if (!_visible) widget.onFinished?.call();
        },
        // Fondo pieno: mentre il logo è a piena opacità copre il numerone,
        // e svanendo lo scopre.
        child: ColoredBox(
          color: kBackground,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double markSize = constraints.maxHeight * 0.42;
              return Stack(
                children: <Widget>[
                  // Il logo si rimpicciolisce per stare dentro: in landscape
                  // stretto il lettering affiancato al bicchiere sfonderebbe
                  // la larghezza.
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.06,
                      vertical: constraints.maxHeight * 0.08,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const _PubLine(),
                          SizedBox(height: markSize * 0.12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              HomdMark(size: markSize),
                              SizedBox(width: markSize * 0.28),
                              _Wordmark(scale: markSize / 200),
                            ],
                          ),
                          SizedBox(height: markSize * 0.12),
                          const _Tagline(),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DutchFlagDivider(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PubLine extends StatelessWidget {
  const _PubLine();

  @override
  Widget build(BuildContext context) {
    return const Text(
      kBrandPub,
      style: TextStyle(
        fontFamily: kBrandFont,
        color: kTextColor,
        fontSize: 22,
        letterSpacing: 4,
      ),
    );
  }
}

/// «HOUSE OF / MAD DOGS», su due righe come nel logo.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    // Oswald Bold, non il lettering brush: nel logo HoMD la tipografia è
    // quella (UX_UI_SPEC → Tipografia; font vero, dal vettoriale del
    // committente).
    final TextStyle style = TextStyle(
      fontFamily: kBrandFont,
      color: kPrimaryRed,
      fontSize: 54 * scale,
      height: 0.98,
      letterSpacing: 2 * scale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(kBrandNameLine1, style: style),
        Text(kBrandNameLine2, style: style),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Text(
      kBrandTagline,
      style: TextStyle(
        fontFamily: kBrandFont,
        color: kTextColor,
        fontSize: 16,
        letterSpacing: 2.5,
      ),
    );
  }
}
