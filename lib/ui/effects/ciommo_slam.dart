/// Il timbro gigante "Ciommo Approved": lo slam.
///
/// Dalla v2 Ciommo non è più una fila di timbrini ai lati del marchio: a ogni
/// multiplo dell'intervallo (5, 10, 15… col default, regolabile dal pannello)
/// UN timbro monumentale piomba e sfuma. Inclinazione e ritmo decisi nei
/// mockup (design/mockups/DECISIONS.md → 02): −14°, 2,0 s col ta-daa (che
/// suona il motore).
///
/// Dalla v3 il timbro non piomba più al centro: a 85% d'altezza copriva la
/// scritta celebrativa della combo («Bello!», «Fantastico!»…). I timbri
/// girano su tre posti decisi da [ciommoSlamSlot], tutti SOTTO il blocco
/// combo: il primo a sinistra, il secondo a destra, il terzo sotto la
/// scritta (più piccolo), poi il giro ricomincia.
///
/// È scenografia pura (regola d'oro 2): radice [IgnorePointer], sotto si
/// continua a contare. Non entra nella coda effetti — è un fatto della combo,
/// come il moltiplicatore: in coda arriverebbe in ritardo, dietro a fuochi o
/// strike.
library;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../state/combo_machine.dart';

class CiommoSlamOverlay extends StatelessWidget {
  const CiommoSlamOverlay({super.key, required this.serial});

  /// Quanti multipli dell'intervallo ha toccato la combo
  /// (`count ~/ intervallo`): 0 = nessun timbro; ogni valore nuovo fa
  /// ripartire lo slam da capo (via [ValueKey]) nel posto successivo.
  final int serial;

  @override
  Widget build(BuildContext context) {
    if (serial <= 0) return const SizedBox.shrink();
    final int slot = ciommoSlamSlot(serial);

    return IgnorePointer(
      // Tutti i posti vivono sotto il blocco combo (moltiplicatore + testo):
      // qualunque sia la larghezza della scritta, il timbro non la copre.
      child: Padding(
        padding: const EdgeInsets.only(top: kCiommoSlamAreaTop),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double area = constraints.maxHeight;
            // Schermo più basso del blocco combo: niente da disegnare.
            if (area <= 0 || !constraints.maxHeight.isFinite) {
              return const SizedBox.shrink();
            }
            final double height =
                area *
                (slot == 2
                    ? kCiommoSlamSmallHeightFraction
                    : kCiommoSlamSideHeightFraction);
            final Alignment alignment = switch (slot) {
              0 => Alignment.centerLeft,
              1 => Alignment.centerRight,
              // Sotto la scritta: appena fuori dal blocco combo, centrato.
              _ => Alignment.topCenter,
            };
            return Align(
              alignment: alignment,
              child: Padding(
                padding: slot == 2
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: kCiommoSlamSideMargin,
                      ),
                child: _Slam(key: ValueKey<int>(serial), height: height),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Slam extends StatelessWidget {
  const _Slam({super.key, required this.height});

  /// Altezza del timbro, già decisa dal posto che occupa.
  final double height;

  @override
  Widget build(BuildContext context) {
    final double width = height * kCiommoStampAspect;
    // L'asset e' 924x1316: senza cacheHeight Flutter lo decodificherebbe a
    // piena risoluzione per poi scalarlo (P1 dell'audit prestazioni).
    final int cacheHeight = (height * MediaQuery.devicePixelRatioOf(context))
        .round();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: kCiommoSlamDuration,
      builder: (BuildContext context, double t, Widget? child) {
        final double scale;
        final double opacity;
        if (t < kCiommoSlamInEnd) {
          // Piomba: arriva grande e trasparente, schiaccia con un filo di
          // rimbalzo (l'overshoot di easeOutBack scende sotto la scala 1).
          final double p = Curves.easeOutBack.transform(t / kCiommoSlamInEnd);
          scale = kCiommoSlamStartScale + (1 - kCiommoSlamStartScale) * p;
          opacity = (t / kCiommoSlamInEnd).clamp(0.0, 1.0);
        } else if (t < kCiommoSlamHoldEnd) {
          scale = 1;
          opacity = 1;
        } else {
          scale = 1;
          opacity = 1 - (t - kCiommoSlamHoldEnd) / (1 - kCiommoSlamHoldEnd);
        }
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: kCiommoSlamAngle,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      // Slot a dimensione fissa dalle proporzioni note dell'asset: esiste
      // prima del decode e resta sano se il PNG non si carica affatto.
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          kImgCiommoApproved,
          fit: BoxFit.contain,
          cacheHeight: cacheHeight,
          // Line-art bianca tinta del rosso di brand, come prima della v2.
          color: kPrimaryRed,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
              const SizedBox.shrink(),
        ),
      ),
    );
  }
}
