import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(dioProvider));
});

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  Future<Order> checkout(int addressId, {String? notes, String? promoCode, String? deliveryTimeSlot, String? deliveryMethod}) async {
    final data = <String, dynamic>{'addressId': addressId, 'notes': notes};
    if (promoCode != null && promoCode.isNotEmpty) {
      data['promotionCode'] = promoCode;
    }
    if (deliveryTimeSlot != null && deliveryTimeSlot.isNotEmpty) {
      data['deliveryTimeSlot'] = deliveryTimeSlot;
    }
    if (deliveryMethod != null && deliveryMethod.isNotEmpty) {
      data['deliveryMethod'] = deliveryMethod;
    }
    final res = await _dio.post(ApiConstants.customerCheckout, data: data);
    return Order.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> validatePromoCode(String code, double orderTotal) async {
    final res = await _dio.post(ApiConstants.customerValidatePromo,
        data: {'code': code, 'orderTotal': orderTotal.toStringAsFixed(2)});
    return Map<String, dynamic>.from(res.data['data']);
  }

  Future<List<Order>> getOrders({int page = 0, int size = 10}) async {
    final res = await _dio.get(ApiConstants.customerOrders, queryParameters: {'page': page, 'size': size});
    return (res.data['data']['content'] as List).map((o) => Order.fromJson(o)).toList();
  }

  Future<Order> getOrderById(int id) async {
    final res = await _dio.get('${ApiConstants.customerOrders}/$id');
    return Order.fromJson(res.data['data']);
  }

  Future<List<Address>> getAddresses() async {
    final res = await _dio.get(ApiConstants.customerAddresses);
    return (res.data['data'] as List).map((a) => Address.fromJson(a)).toList();
  }

  Future<Address> createAddress(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.customerAddresses, data: data);
    return Address.fromJson(res.data['data']);
  }

  Future<Address> updateAddress(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.customerAddresses}/$id', data: data);
    return Address.fromJson(res.data['data']);
  }

  Future<void> deleteAddress(int id) async {
    await _dio.delete('${ApiConstants.customerAddresses}/$id');
  }

  Future<User> getProfile() async {
    final res = await _dio.get(ApiConstants.customerProfile);
    return User.fromJson(res.data['data']);
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put(ApiConstants.customerProfile, data: data);
    return User.fromJson(res.data['data']);
  }
}

