import '../models/card.dart';
import 'api_client.dart';

class CardService {
  final ApiClient _api = ApiClient();

  Future<List<CardModel>> getCards({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    int? softwareId,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null && search.isNotEmpty) params['keyword'] = search;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (softwareId != null) params['software_id'] = softwareId;

      final resp = await _api.get('/cards', params: params);
      final items = resp['items'] as List? ?? [];
      return items.map((e) => CardModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> batchCreate({
    required int softwareId,
    required int count,
    required String durationUnit,
    int? durationValue,
    String? prefix,
    int? unbindLimit,
    String? remarks,
  }) async {
    final data = <String, dynamic>{
      'software_id': softwareId,
      'count': count,
      'duration_unit': durationUnit,
    };
    if (durationValue != null) data['duration_value'] = durationValue;
    if (prefix != null && prefix.isNotEmpty) data['prefix'] = prefix;
    if (unbindLimit != null) data['unbind_limit'] = unbindLimit;
    if (remarks != null && remarks.isNotEmpty) data['remarks'] = remarks;

    return await _api.post('/cards/batch', data: data);
  }

  /// Batch status: banned or unused
  Future<Map<String, dynamic>> batchStatus(List<int> cardIds, String status) async {
    return await _api.post('/cards/status', data: {
      'card_ids': cardIds,
      'status': status,
    });
  }

  /// Reset HWID for a single card
  Future<Map<String, dynamic>> resetHwid(int cardId) async {
    return await _api.post('/cards/$cardId/reset-hwid');
  }
}
