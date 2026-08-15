// Mirrors the dietician app's food_card_widget.dart _formatQuantityLabel/
// _formatPieceFraction exactly, so a recipe's portion reads identically on
// both apps (e.g. "100 g (~7 tbsp)") instead of a bare, harder-to-picture
// gram/ml figure on the patient side.

// 15g ≈ 1 tbsp - the same approximation the source diet plans themselves
// use ("rice (10 tbsp)" ≈ 150g rice).
const num _gramsPerTablespoon = 15;
// 250ml ≈ 1 cup (the standard metric/Indian recipe cup).
const num _mlPerCup = 250;

/// Formats a raw numeric quantity string for display: a genuinely ambiguous
/// mass/volume (plain "g"/"ml") gets an approximate tbsp/cup hint alongside
/// it, since a bare gram figure is hard to picture. Every other unit -
/// piece, nos, egg, slice, bowl, cup, tbsp, tsp - is already a real,
/// human-sized measure (see COMPONENT_UNITS on the backend) and gets clean
/// fraction notation (1/4, 1/2, 3/4, 1 1/2...) with no further conversion -
/// converting "2 egg" into "~0 tbsp" would be nonsensical, not helpful.
String formatQuantityLabel(String rawValue, String unit) {
  final value = num.tryParse(rawValue);
  if (value == null) {
    return unit.isNotEmpty ? '$rawValue $unit' : rawValue;
  }
  if (unit == 'ml') {
    final cups = _formatPieceFraction(value / _mlPerCup);
    return '$rawValue $unit (~$cups cup)';
  }
  if (unit == 'g') {
    final tbsp = (value / _gramsPerTablespoon).round();
    return '$rawValue $unit (~$tbsp tbsp)';
  }
  if (unit.isEmpty) return rawValue;
  return '${_formatPieceFraction(value)} $unit';
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
