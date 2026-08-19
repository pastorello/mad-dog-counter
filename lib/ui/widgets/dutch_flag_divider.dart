/// La bandierina olandese: separatore firma del brand.
library;

import 'package:flutter/material.dart';

import '../../config.dart';

class DutchFlagDivider extends StatelessWidget {
  const DutchFlagDivider({super.key, this.height = 6});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Column(
        children: <Widget>[
          Expanded(
            child: ColoredBox(color: kPrimaryRed, child: SizedBox.expand()),
          ),
          Expanded(
            child: ColoredBox(color: kTextColor, child: SizedBox.expand()),
          ),
          Expanded(
            child: ColoredBox(color: kAccentBlue, child: SizedBox.expand()),
          ),
        ],
      ),
    );
  }
}
