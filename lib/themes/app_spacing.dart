import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;

  static const screenPad = EdgeInsets.all(lg);
  static const cardPadLarge = EdgeInsets.all(22);
  static const cardPadSmall = EdgeInsets.all(md);
  static const inputPad = EdgeInsets.symmetric(horizontal: md, vertical: 11);
  static const buttonPad = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
  static const chipPad = EdgeInsets.symmetric(horizontal: md, vertical: 11);
  static const badgePad = EdgeInsets.symmetric(horizontal: sm, vertical: 5);
}

class AppRadius {
  AppRadius._();

  static const cardLarge = 24.0;
  static const cardSmall = 18.0;
  static const button = 18.0;
  static const chip = 22.0;
  static const badge = 20.0;
  static const input = 22.0;
  static const iconBox = 16.0;

  static const rCardLarge = BorderRadius.all(Radius.circular(cardLarge));
  static const rCardSmall = BorderRadius.all(Radius.circular(cardSmall));
  static const rButton = BorderRadius.all(Radius.circular(button));
  static const rChip = BorderRadius.all(Radius.circular(chip));
  static const rBadge = BorderRadius.all(Radius.circular(badge));
  static const rInput = BorderRadius.all(Radius.circular(input));
  static const rIconBox = BorderRadius.all(Radius.circular(iconBox));
}

class AppSizes {
  AppSizes._();

  static const headerIcon = 42.0;
  static const iconBoxLarge = 60.0;
  static const iconBoxSmall = 54.0;
  static const sendButton = 42.0;
  static const listAvatar = 46.0;

  static const iconLarge = 32.0;
  static const iconMedium = 24.0;
  static const iconSmall = 20.0;
}
