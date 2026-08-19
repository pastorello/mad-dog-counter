/// Il pannello impostazioni.
///
/// Overlay scuro sopra la schermata, con la tipografia secondaria: nel
/// pannello serve leggibilità, non il lettering brush (UX_UI_SPEC → Layout).
///
/// Contenuto volutamente minimale (FUNCTIONAL_SPEC → Pannello impostazioni).
/// È pensato per crescere in fase 2, ma nell'MVP non deve contenere altro.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../state/counter_provider.dart';
import '../state/settings_provider.dart';

class SettingsPanel extends ConsumerStatefulWidget {
  const SettingsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  final TextEditingController _totalField = TextEditingController();

  /// Il valore in attesa di conferma. Finché non è null, il pannello mostra
  /// "vecchio → nuovo" invece del campo.
  int? _pendingTotal;
  String? _error;

  @override
  void dispose() {
    _totalField.dispose();
    super.dispose();
  }

  void _prepare() {
    final int? parsed = int.tryParse(_totalField.text.trim());
    if (parsed == null || parsed < kMinCount || parsed > kMaxSettableTotal) {
      setState(() {
        _error = kSettingsInvalidNumber;
        _pendingTotal = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _pendingTotal = parsed;
    });
  }

  void _confirm() {
    final int? value = _pendingTotal;
    if (value == null) return;
    ref.read(counterActionsProvider).setTotal(value);
    _totalField.clear();
    setState(() => _pendingTotal = null);
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = ref.watch(settingsProvider);
    final int currentTotal = ref
        .watch(counterTotalProvider)
        .maybeWhen(data: (int value) => value, orElse: () => kInitialCount);

    // Material e non ColoredBox: i controlli del pannello (l'interruttore
    // audio, i bottoni) dipingono l'ink sul Material più vicino, e un
    // ColoredBox glielo coprirebbe.
    return Material(
      // Fondo pieno, non semitrasparente: mentre il pannello è aperto i tap
      // sul contatore sono disabilitati, e deve vedersi che lo sono.
      color: kBackground,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    kSettingsTitle,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kTextColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _CounterField(
                    controller: _totalField,
                    currentTotal: currentTotal,
                    pendingTotal: _pendingTotal,
                    error: _error,
                    onPrepare: _prepare,
                    onConfirm: _confirm,
                    onCancel: () => setState(() => _pendingTotal = null),
                  ),
                  const SizedBox(height: 24),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      kSettingsAudioLabel,
                      style: TextStyle(color: kTextColor, fontSize: 18),
                    ),
                    value: settings.soundEnabled,
                    activeThumbColor: kPrimaryRed,
                    onChanged: (bool value) => ref
                        .read(settingsProvider.notifier)
                        .setSoundEnabled(value),
                  ),
                  const Divider(color: kSurfaceNavy),

                  _IdleMinutes(
                    minutes: settings.idleMinutes,
                    onChanged: (int value) => ref
                        .read(settingsProvider.notifier)
                        .setIdleMinutes(value),
                  ),
                  const SizedBox(height: 32),

                  // Unico modo per uscire: nessun altro elemento di navigazione.
                  FilledButton(
                    onPressed: widget.onClose,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryRed,
                      foregroundColor: kTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      kSettingsClose,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo "Imposta contatore", con la conferma esplicita vecchio → nuovo.
///
/// È la manovra con cui si subentra al vecchio counter il giorno
/// dell'installazione: sbagliarla vuol dire riscrivere la storia del pub, e la
/// conferma esiste per quello.
class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.controller,
    required this.currentTotal,
    required this.pendingTotal,
    required this.error,
    required this.onPrepare,
    required this.onConfirm,
    required this.onCancel,
  });

  final TextEditingController controller;
  final int currentTotal;
  final int? pendingTotal;
  final String? error;
  final VoidCallback onPrepare;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (pendingTotal case final int pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            kSettingsCounterLabel,
            style: TextStyle(color: kTextColor, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            '$currentTotal → $pending',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kCelebrationGold,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text(kSettingsCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text(kSettingsConfirm),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(color: kTextColor, fontSize: 20),
                decoration: const InputDecoration(
                  labelText: kSettingsCounterLabel,
                  hintText: kSettingsCounterHint,
                  labelStyle: TextStyle(color: kTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kSurfaceNavy),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onPrepare,
              child: const Text(kSettingsApply),
            ),
          ],
        ),
        if (error case final String message)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: const TextStyle(color: kPrimaryRed, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

/// Minuti di inattività prima della faccina annoiata.
class _IdleMinutes extends StatelessWidget {
  const _IdleMinutes({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            kSettingsIdleLabel,
            style: TextStyle(color: kTextColor, fontSize: 18),
          ),
        ),
        IconButton(
          onPressed: minutes > kIdleMinutesMin
              ? () => onChanged(minutes - 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline, color: kTextColor),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$minutes',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextColor, fontSize: 20),
          ),
        ),
        IconButton(
          onPressed: minutes < kIdleMinutesMax
              ? () => onChanged(minutes + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline, color: kTextColor),
        ),
      ],
    );
  }
}
