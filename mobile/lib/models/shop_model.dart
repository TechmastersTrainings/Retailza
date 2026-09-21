class ShopModel {
  final int id;
  final int ownerId;
  final String shopName;
  final String ownerName;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? upiQrImage;
  final String? upiId;

  ShopModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.ownerName,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.upiQrImage,
    this.upiId,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      shopName: json['shop_name'] as String,
      ownerName: json['owner_name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      upiQrImage: json['upi_qr_image'] as String?,
      upiId: json['upi_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'shop_name': shopName,
      'owner_name': ownerName,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'upi_qr_image': upiQrImage,
      'upi_id': upiId,
    };
  }
}
