/// La salva di cuoricini che accompagna le tette (effetto 8 adiacenti).
///
/// Parte una volta sola, quando la coppia di 8 si forma: i cuori esplodono
/// attorno al numerone e ricadono con la gravità, come i coriandoli dei
/// fuochi. Non entra nella coda effetti — è un contorno dello stato
/// persistente delle tette (ANIMATIONS_SPEC → regola 3) — e come tutto il
/// layer effetti è fire-and-forget rispetto al conteggio.
library;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../config.dart';

class HeartsBurst extends StatefulWidget {
  const HeartsBurst({super.key});

  @override
  State<HeartsBurst> createState() => _HeartsBurstState();
}

class _HeartsBurstState extends State<HeartsBurst> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    // Una salva sola: il controller si ferma da sé, il widget resta in scena
    // finché durano le tette senza sparare più niente.
    _controller = ConfettiController(duration: kHeartsBurstDuration)..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        // I cuori nascono al centro, cioè addosso alle tette: il numerone sta
        // sempre lì.
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: kHeartsCount,
          emissionFrequency: 0.08,
          maxBlastForce: 26,
          minBlastForce: 10,
          gravity: kHeartsGravity,
          shouldLoop: false,
          colors: const <Color>[kHeartPink, kFleshPink, kPrimaryRed],
          // Cuori quadrati di base: senza questo il pacchetto li disegna
          // rettangolari e sembrano coriandoli qualunque.
          minimumSize: const Size(22, 22),
          maximumSize: const Size(34, 34),
          createParticlePath: _heartPath,
        ),
      ),
    );
  }
}

/// Un cuore disegnato dentro al riquadro che il pacchetto coriandoli passa.
Path _heartPath(Size size) {
  final double w = size.width;
  final double h = size.height;

  return Path()
    ..moveTo(w / 2, h * 0.95)
    // Lobo sinistro, poi destro: due curve simmetriche che si chiudono sulla
    // punta in basso.
    ..cubicTo(-w * 0.22, h * 0.55, w * 0.16, -h * 0.14, w / 2, h * 0.30)
    ..cubicTo(w * 0.84, -h * 0.14, w * 1.22, h * 0.55, w / 2, h * 0.95)
    ..close();
}
