import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final order = orders[i];
                    return Card(
                      child: InkWell(
                        onTap: () => context.push('/orders/${order.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              _statusChip(order.status),
                            ]),
                            const SizedBox(height: 8),
                            Text('${order.items.length} items • €${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            if (order.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(order.createdAt!, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load orders')),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status) {
      case 'COMPLETED' || 'DELIVERED': bg = AppColors.success.withValues(alpha: 0.1); fg = AppColors.success;
      case 'CANCELLED' || 'REFUNDED': bg = AppColors.error.withValues(alpha: 0.1); fg = AppColors.error;
      case 'PENDING': bg = AppColors.warning.withValues(alpha: 0.1); fg = AppColors.warning;
      default: bg = AppColors.primaryLight; fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

