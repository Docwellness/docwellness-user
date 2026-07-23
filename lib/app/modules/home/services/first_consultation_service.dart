import 'package:docwellness/main.dart';
import 'package:docwellness/utils/functions/dio_function.dart';

class FirstConsultationService {
  final ApiService service = ApiService();

  final String templatePath = '/consultation-form-template';
  final String consultationPath = '/first-consultation';
  final String consentPath = '/first-consultation/consent';

  /// Field definitions (labels/types/sections/etc) for the assigned
  /// dietician's questionnaire.
  Future<dynamic> getTemplate() async {
    try {
      final response = await service.request(
        endPoint: templatePath,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  /// The patient's own submitted first consultation (dietician-filled
  /// answers + any consent already given). Null data means none exists yet.
  Future<dynamic> getMyConsultation({bool silent = false}) async {
    try {
      final response = await service.request(
        endPoint: consultationPath,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
        silent: silent,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> submitConsent({
    required bool acknowledged,
    required String signatureName,
  }) async {
    try {
      final response = await service.request(
        endPoint: consentPath,
        method: 'PUT',
        data: {'acknowledged': acknowledged, 'signatureName': signatureName},
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
      // Surface validation errors (e.g. 400) so the UI can show a message.
      if (response != null && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }
}
