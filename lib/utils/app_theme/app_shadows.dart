import 'package:flutter/material.dart';

/// The soft maroon-tinted shadow every card-style Container in the app
/// should use, so cards read as one consistent system instead of some
/// having depth and others being flat borders - this exact color/blur/
/// offset combination originated on the Goal Journey card (see
/// journey_card.dart) and is now the app-wide standard. Not `const`
/// because Color.withValues() isn't a const constructor - computed once
/// here instead of re-allocating per build.
final List<BoxShadow> cardShadow = [
  BoxShadow(
    color: const Color(0xff851653).withValues(alpha: 0.06),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];

/// The thin rose-tinted border every neutral card should pair with
/// cardShadow - also lifted from the Goal Journey card. Skip this on a
/// card whose border color is already carrying its own meaning (e.g. a
/// green/red success-or-error state, a selected/unselected toggle) -
/// those should keep their semantic color, not be flattened to this.
const Color cardBorderColor = Color(0xffFCE7F6);
const Border cardBorder = Border.fromBorderSide(
  BorderSide(color: cardBorderColor, width: 1.2),
);
