import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  Future<AnnouncementModel?> getLatestAnnouncement() async {
    try {
      final response = await ApiClient.get(ApiConstants.latestAnnouncement);
      if (response != null && response is Map<String, dynamic> && response['id'] != null) {
        return AnnouncementModel.fromJson(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
