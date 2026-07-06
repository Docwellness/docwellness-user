import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

import '../models/grocery_model.dart';

class GroceryService {
  final ApiService _service = ApiService();

  Future<List<GroceryItem>> fetchGroceries({String? date}) async {
    try {
      String endpoint = '/diet/groceries';
      if (date != null) endpoint += '?date=$date';

      final response = await _service.request(
        endPoint: endpoint,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> rawItems =
            response.data['data']?['items'] as List<dynamic>? ?? [];
        return rawItems
            .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
