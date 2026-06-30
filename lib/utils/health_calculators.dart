class HealthCalculators {
  /// Calculates Body Mass Index (BMI).
  /// [weight] is in kilograms (kg).
  /// [height] is in meters (m).
  static double calculateBMI(double weight, double height) {
    if (height <= 0 || weight <= 0) {
      return 0.0;
    }
    double bmi = weight / (height * height);
    // Round to one decimal place
    return (bmi * 10).round() / 10;
  }
}
