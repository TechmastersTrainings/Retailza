import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/shop_model.dart';

class ShopService {
  Future<ShopModel> setupShop({
    required String shopName,
    required String ownerName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? upiQrImage,
    String? upiId,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.shopSetup,
      body: {
        'shop_name': shopName,
        'owner_name': ownerName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'upi_qr_image': upiQrImage,
        'upi_id': upiId,
      },
    );
    return ShopModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ShopModel> updateShop({
    String? shopName,
    String? ownerName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? upiQrImage,
    String? upiId,
  }) async {
    final Map<String, dynamic> body = {};
    if (shopName != null) body['shop_name'] = shopName;
    if (ownerName != null) body['owner_name'] = ownerName;
    if (address != null) body['address'] = address;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (pincode != null) body['pincode'] = pincode;
    if (upiQrImage != null) body['upi_qr_image'] = upiQrImage;
    if (upiId != null) body['upi_id'] = upiId;

    final response = await ApiClient.put(ApiConstants.currentShop, body: body);
    return ShopModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ShopModel> getCurrentShop() async {
    final response = await ApiClient.get(ApiConstants.currentShop);
    return ShopModel.fromJson(response as Map<String, dynamic>);
  }
}
