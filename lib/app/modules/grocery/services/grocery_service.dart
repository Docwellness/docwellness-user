import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

import '../models/grocery_model.dart';

class GroceryService {
  final ApiService _service = ApiService();

  /// Every ready week's grocery list in one call - see the backend's
  /// getGroceriesForCurrentWeek doc comment.
  Future<GroceryWeeksResult> fetchGroceries() async {
    try {
      final response = await _service.request(
        endPoint: '/diet/groceries',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return GroceryWeeksResult.fromJson(
          Map<String, dynamic>.from(response.data['data'] ?? {}),
        );
      }
    } catch (_) {}
    return GroceryWeeksResult.empty();
  }
}
