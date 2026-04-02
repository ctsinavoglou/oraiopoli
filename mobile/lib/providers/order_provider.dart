import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/order_repository.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) {
  return ref.read(orderRepositoryProvider).getOrders();
});

final addressesProvider = FutureProvider<List<Address>>((ref) {
  return ref.read(orderRepositoryProvider).getAddresses();
});

final profileProvider = FutureProvider<User>((ref) {
  return ref.read(orderRepositoryProvider).getProfile();
});

