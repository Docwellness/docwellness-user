/// Shared across the Signup "Primary Goal" step and the Request Diet Plan
/// personal-info form, so both places offer identical goal choices and
/// validate Initial vs. Target weight the same way.
const List<String> primaryGoalOptions = [
  'Weight Loss',
  'Weight Gain',
  'Weight Maintenance',
  'Muscle Gain (Body Recomposition)',
  'Fat Loss',
  'Healthy Weight Management',
];

({double minKg, double maxKg})? healthyWeightRangeFromHeight(double? heightCm) {
  if (heightCm == null || heightCm <= 0) return null;
  final heightM = heightCm / 100;
  return (minKg: 18.5 * heightM * heightM, maxKg: 25 * heightM * heightM);
}

/// Returns a validation error message if [targetWeight] doesn't make sense
/// for the selected [goal] relative to [initialWeight], or null if it's
/// fine. [heightCm] is only needed for "Healthy Weight Management", which
/// checks against the healthy BMI range instead of a direction relative to
/// the initial weight.
String? validateGoalWeights({
  required String goal,
  required double initialWeight,
  required double targetWeight,
  double? heightCm,
}) {
  if (initialWeight <= 0 || targetWeight <= 0) return null;

  switch (goal) {
    case 'Weight Loss':
    case 'Fat Loss':
      if (targetWeight >= initialWeight) {
        return 'For $goal, Target Weight must be lower than Initial Weight.';
      }
      break;

    case 'Weight Gain':
      if (targetWeight <= initialWeight) {
        return 'For Weight Gain, Target Weight must be higher than Initial Weight.';
      }
      break;

    case 'Weight Maintenance':
      if ((targetWeight - initialWeight).abs() > 2) {
        return 'For Weight Maintenance, Target Weight should stay close to '
            'Initial Weight (within 2 Kg).';
      }
      break;

    case 'Muscle Gain (Body Recomposition)':
      // Body recomposition builds muscle while losing fat - net weight
      // usually stays flat or rises slightly, so only rule out a
      // meaningful drop rather than requiring an exact match.
      if (targetWeight < initialWeight - 2) {
        return 'For Muscle Gain (Body Recomposition), Target Weight should '
            'not be significantly lower than Initial Weight.';
      }
      break;

    case 'Healthy Weight Management':
      final range = healthyWeightRangeFromHeight(heightCm);
      if (range != null &&
          (targetWeight < range.minKg || targetWeight > range.maxKg)) {
        return 'For Healthy Weight Management, Target Weight should be '
            'within the healthy range for your height '
            '(${range.minKg.toStringAsFixed(1)}–${range.maxKg.toStringAsFixed(1)} Kg).';
      }
      break;
  }
  return null;
}
