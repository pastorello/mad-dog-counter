/// Il badge col giornaliero e il record da battere: «OGGI 87 · RECORD 214».
///
/// Sempre a schermo, piccolo e discreto, in alto a sinistra (l'angolo
/// opposto al panico): etichette in ink spento, numeri in oro
/// (DECISIONS → 01). Il giornaliero mostrato non scende mai sotto zero;
/// finché non esiste un record si legge «RECORD —».
///
/// È UNA riga sola (`Text.rich`), mai un `Text` il cui contenuto sia una
/// cifra singola: il numerone è fatto di `Text` a cifra singola e i widget
/// test li contano.
///
/// Senza un [DailyStatsController] (test, bootstrap degradato) il badge
/// semplicemente non compare: il contatore non dipende mai da lui.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../state/daily_stats.dart';
import '../../state/daily_stats_provider.dart';

class DailyStatsBadge extends ConsumerWidget {
  const DailyStatsBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DailyStats? stats = ref
        .watch(dailyStatsProvider)
        .maybeWhen(data: (DailyStats value) => value, orElse: () => null);
    if (stats == null) return const SizedBox.shrink();

    const TextStyle label = TextStyle(
      fontFamily: kBrandFont,
      fontWeight: FontWeight.w700,
      fontSize: kBadgeTextSize,
      letterSpacing: kBadgeTracking,
      height: 1,
      color: kBadgeLabelColor,
    );
    const TextStyle number = TextStyle(
      fontFamily: kBrandFont,
      fontWeight: FontWeight.w700,
      fontSize: kBadgeTextSize,
      letterSpacing: kBadgeTracking,
      height: 1,
      color: kCelebrationGold,
    );

    final String record = stats.bestCount > 0
        ? '${stats.bestCount}'
        : kRecordEmptyPlaceholder;

    return IgnorePointer(
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: '$kDailyLabel ', style: label),
            TextSpan(text: '${stats.displayCount}', style: number),
            const TextSpan(text: ' · $kRecordLabel ', style: label),
            TextSpan(text: record, style: number),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}
