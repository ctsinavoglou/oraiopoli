import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/order_repository.dart';
import '../../models/models.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  String _deliveryMethodLabel(String method) {
    switch (method) {
      case 'EXPRESS': return 'Express Delivery';
      case 'PICKUP': return 'Store Pickup';
      default: return 'Standard Delivery';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<Order>(
        future: ref.read(orderRepositoryProvider).getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Failed to load order'));
          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(order.orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(order.status, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text('Address: ${order.shippingAddress}', style: const TextStyle(color: AppColors.textSecondary)),
                if (order.deliveryMethod != null)
                  Text('Delivery: ${_deliveryMethodLabel(order.deliveryMethod!)}', style: const TextStyle(color: AppColors.textSecondary)),
                if (order.contactPhone != null) Text('Phone: ${order.contactPhone}', style: const TextStyle(color: AppColors.textSecondary)),
                if (order.deliveryTimeSlot != null) Text('Delivery Slot: ${order.deliveryTimeSlot}', style: const TextStyle(color: AppColors.textSecondary)),
                if (order.notes != null) Text('Notes: ${order.notes}', style: const TextStyle(color: AppColors.textSecondary)),
              ]))),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Card(
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Text('€${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}'),
                  trailing: Text('€${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              )),
              const SizedBox(height: 16),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('€${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
              )),
            ]),
          );
        },
      ),
    );
  }
}

