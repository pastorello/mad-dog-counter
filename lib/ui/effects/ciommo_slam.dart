/// Il timbro gigante "Ciommo Approved": lo slam.
///
/// Dalla v2 Ciommo non è più una fila di timbrini ai lati del marchio: a ogni
/// multiplo dell'intervallo (5, 10, 15… col default, regolabile dal pannello)
/// UN timbro monumentale piomba inclinato di −14° (DECISIONS → 02) col
/// ta-daa (che suona il motore).
///
/// Dalla v3 il timbro non piomba più al centro dello schermo: a 85%
/// d'altezza copriva la scritta celebrativa della combo. I timbri girano su
/// tre posti decisi da [ciommoSlamSlot]: il primo a sinistra, il secondo a
/// destra, il terzo al centro, poi il giro ricomincia.
///
/// Dalla v4 (richieste del committente dopo l'anteprima):
/// - sono tutti alti metà monitor ([kCiommoSlamHeightFraction]);
/// - RESTANO a video finché dura la combo, uno per posto
///   ([ciommoStampsOnScreen]): dal quarto, il nuovo prende il posto di
///   quello di un giro prima. Se ne vanno con la dissolvenza di fine combo;
/// - i laterali si appoggiano sulla bandierina olandese; il centrale scende
///   quanto basta per stare tutto sotto la scritta, e il suo fondo finisce
///   dietro la bandierina (nessun timbro la scavalca).
///
/// È scenografia pura (regola d'oro 2): radice [IgnorePointer], sotto si
/// continua a contare. Non entra nella coda effetti — è un fatto della combo,
/// come il moltiplicatore: in coda arriverebbe in ritardo, dietro a fuochi o
/// strike.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../state/combo_machine.dart';

/// L'altezza del timbro su uno schermo alto [screenHeight]: metà monitor,
/// uguale nei tre posti.
double ciommoSlamHeight(double screenHeight) =>
    screenHeight * kCiommoSlamHeightFraction;

/// La quota del centro del timbro nel posto [slot].
///
/// I laterali stanno il più in basso possibile, col disegno ruotato che
/// arriva alla bandierina olandese senza scavalcarla: «APPROVED» resta
/// intera. Il centrale ha sopra di sé la scritta della combo: scende quanto
/// basta perché la tesa del cappello resti sotto il blocco combo.
double ciommoSlamCenterY(int slot, double screenHeight) {
  final double height = ciommoSlamHeight(screenHeight);
  if (slot == 2) {
    final double comboBottom =
        kTopOverlayTop + screenHeight * kComboBlockHeightFraction;
    return comboBottom + height * kCiommoSlamReachUp;
  }
  return screenHeight - kDutchFlagHeight - height * kCiommoSlamReachDown;
}

class CiommoSlamOverlay extends StatefulWidget {
  const CiommoSlamOverlay({super.key, required this.serial});

  /// Quanti multipli dell'intervallo ha toccato la combo
  /// (`count ~/ intervallo`): 0 = nessun timbro, o combo finita. Ogni valore
  /// nuovo fa piombare un timbro nel posto successivo.
  final int serial;

  @override
  State<CiommoSlamOverlay> createState() => _CiommoSlamOverlayState();
}

class _CiommoSlamOverlayState extends State<CiommoSlamOverlay> {
  /// Il serial da disegnare: a fine combo resta quello vecchio per tutta la
  /// dissolvenza, come fa l'overlay della combo.
  int _shown = 0;

  /// Contatore delle combo: entra nella chiave dei timbri, così una combo
  /// nuova li fa piombare da capo anche se il serial si ripete.
  int _combo = 0;

  /// Smonta i timbri a dissolvenza conclusa.
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _shown = widget.serial;
  }

  @override
  void didUpdateWidget(CiommoSlamOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serial > 0) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      // Combo nuova (anche mentre la vecchia sta ancora sfumando).
      if (oldWidget.serial <= 0 || widget.serial < oldWidget.serial) {
        _combo++;
      }
      _shown = widget.serial;
    } else if (oldWidget.serial > 0) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(kComboDismissDelay, () {
        if (mounted) setState(() => _shown = 0);
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shown <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        // Se ne vanno insieme alla combo, con la stessa dissolvenza.
        opacity: widget.serial > 0 ? 1 : 0,
        duration: kComboFadeDuration,
        curve: Curves.easeOut,
        // Nessun timbro scavalca la bandierina olandese: il centrale, che
        // scende di più, ci finisce dietro.
        child: ClipRect(
          clipper: const _AboveDutchFlag(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // L'overlay è a tutto schermo: le misure SONO quelle del monitor.
              final Size screen = constraints.biggest;
              if (!screen.isFinite || screen.isEmpty) {
                return const SizedBox.shrink();
              }
              final double height = ciommoSlamHeight(screen.height);
              final double width = height * kCiommoStampAspect;
              return Stack(
                children: <Widget>[
                  // In ordine di arrivo: il più recente passa davanti.
                  for (final int serial in ciommoStampsOnScreen(_shown))
                    _place(
                      slot: ciommoSlamSlot(serial),
                      screen: screen,
                      size: Size(width, height),
                      child: _Slam(
                        key: ValueKey<(int, int)>((_combo, serial)),
                        height: height,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _place({
    required int slot,
    required Size screen,
    required Size size,
    required Widget child,
  }) {
    final double top = ciommoSlamCenterY(slot, screen.height) - size.height / 2;
    return switch (slot) {
      0 => Positioned(left: kCiommoSlamSideMargin, top: top, child: child),
      1 => Positioned(right: kCiommoSlamSideMargin, top: top, child: child),
      _ => Positioned(
        left: (screen.width - size.width) / 2,
        top: top,
        child: child,
      ),
    };
  }
}

/// Tutto lo schermo tranne la fascia della bandierina olandese in fondo.
class _AboveDutchFlag extends CustomClipper<Rect> {
  const _AboveDutchFlag();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height - kDutchFlagHeight);

  @override
  bool shouldReclip(_AboveDutchFlag oldClipper) => false;
}

class _Slam extends StatelessWidget {
  const _Slam({super.key, required this.height});

  /// Altezza del timbro: metà monitor.
  final double height;

  @override
  Widget build(BuildContext context) {
    final double width = height * kCiommoStampAspect;
    // L'asset e' 776x976: senza cacheHeight Flutter lo decodificherebbe a
    // piena risoluzione per poi scalarlo (P1 dell'audit prestazioni).
    final int cacheHeight = (height * MediaQuery.devicePixelRatioOf(context))
        .round();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: kCiommoSlamInDuration,
      builder: (BuildContext context, double t, Widget? child) {
        // Piomba: arriva grande e trasparente, schiaccia con un filo di
        // rimbalzo (l'overshoot di easeOutBack scende sotto la scala 1).
        // Poi resta fermo: niente dissolvenza, se ne va con la combo.
        final double p = Curves.easeOutBack.transform(t);
        final double scale =
            kCiommoSlamStartScale + (1 - kCiommoSlamStartScale) * p;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
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
