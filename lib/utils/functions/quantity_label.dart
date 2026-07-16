// Mirrors the dietician app's food_card_widget.dart _formatQuantityLabel/
// _formatPieceFraction exactly, so a recipe's portion reads identically on
// both apps (e.g. "100 g (~7 tbsp)") instead of a bare, harder-to-picture
// gram/ml figure on the patient side.

// 15g ≈ 1 tbsp - the same approximation the source diet plans themselves
// use ("rice (10 tbsp)" ≈ 150g rice).
const num _gramsPerTablespoon = 15;
// 250ml ≈ 1 cup (the standard metric/Indian recipe cup).
const num _mlPerCup = 250;

/// Formats a raw numeric quantity string for display: piece-based units get
/// fraction notation (1/4, 1/2, 3/4, 1 1/2...) instead of a raw decimal;
/// ml-based units get an approximate cup count (also in fraction notation);
/// gram-based units get an approximate tablespoon count.
String formatQuantityLabel(String rawValue, String unit) {
  final value = num.tryParse(rawValue);
  if (value == null) {
    return unit.isNotEmpty ? '$rawValue $unit' : rawValue;
  }
  if (unit == 'piece') {
    return '${_formatPieceFraction(value)} $unit';
  }
  if (unit == 'ml') {
    final cups = _formatPieceFraction(value / _mlPerCup);
    return '$rawValue $unit (~$cups cup)';
  }
  // Already a spoon measure (e.g. a secondaryComponent like "Seeds &
  // Chana") - no further conversion, converting it again as if it were
  // grams would be wrong.
  if (unit == 'tbsp' || unit == 'tsp') {
    return '$rawValue $unit';
  }
  if (unit.isNotEmpty) {
    final tbsp = (value / _gramsPerTablespoon).round();
    return '$rawValue $unit (~$tbsp tbsp)';
  }
  return rawValue;
}

String _formatPieceFraction(num value) {
  final whole = value.floor();
  final frac = value - whole;
  String fracLabel = '';
  if ((frac - 0.25).abs() < 0.01) {
    fracLabel = '¼';
  } else if ((frac - 0.5).abs() < 0.01) {
    fracLabel = '½';
  } else if ((frac - 0.75).abs() < 0.01) {
    fracLabel = '¾';
  } else if (frac > 0.01) {
    fracLabel = frac.toStringAsFixed(2);
  }
  if (whole == 0 && fracLabel.isNotEmpty) return fracLabel;
  if (fracLabel.isEmpty) return '$whole';
  return '$whole $fracLabel';
}
