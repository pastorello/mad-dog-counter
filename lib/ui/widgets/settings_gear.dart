/// L'ingranaggio delle impostazioni: si apre SOLO con una pressione lunga
/// (`kSettingsLongPress`).
///
/// Il tap semplice è ignorato di proposito (FUNCTIONAL_SPEC → Pannello
/// impostazioni): è a prova di dita ubriache. Sta sopra le zone di tap, così i
/// suoi tocchi non finiscono nel contatore.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../config.dart';

class SettingsGear extends StatefulWidget {
  const SettingsGear({super.key, required this.onLongPress});

  final VoidCallback onLongPress;

  @override
  State<SettingsGear> createState() => _SettingsGearState();
}

class _SettingsGearState extends State<SettingsGear> {
  Timer? _hold;
  double _progress = 0;

  void _startHold() {
    _hold?.cancel();
    setState(() => _progress = 1);
    // Non si usa onLongPress di GestureDetector: la sua durata è fissa a
    // mezzo secondo, mentre qui ne servono tre.
    _hold = Timer(kSettingsLongPress, () {
      _hold = null;
      setState(() => _progress = 0);
      widget.onLongPress();
    });
  }

  void _cancelHold() {
    _hold?.cancel();
    _hold = null;
    if (mounted) setState(() => _progress = 0);
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Impostazioni: tieni premuto',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _startHold(),
        onTapUp: (_) => _cancelHold(),
        onTapCancel: _cancelHold,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Anello che si riempie mentre si tiene premuto: senza, tenere
              // il dito su un'icona spenta per un paio di secondi sembra rotto.
              SizedBox(
                width: 40,
                height: 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _progress),
                  duration: _progress == 0 ? Duration.zero : kSettingsLongPress,
                  builder: (BuildContext context, double value, Widget? _) =>
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: kSettingsRingStroke,
                        color: kPrimaryRed.withValues(alpha: 0.7),
                        backgroundColor: Colors.transparent,
                      ),
                ),
              ),
              const Icon(Icons.settings, size: 26, color: Color(0x59F0F0F0)),
            ],
          ),
        ),
      ),
    );
  }
}
