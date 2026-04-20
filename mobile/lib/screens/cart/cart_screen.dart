import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartAsync.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ]));
          }
          return Column(children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = cart.items[i];
                  return Card(
                    key: ValueKey(item.id),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.resolvedProductThumbnail != null
                              ? CachedNetworkImage(imageUrl: item.resolvedProductThumbnail!, width: 70, height: 70, fit: BoxFit.cover)
                              : Container(width: 70, height: 70, color: AppColors.divider, child: const Icon(Icons.image)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.hasDiscount) ...[
                                Text('€${item.originalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                                const SizedBox(width: 4),
                                Text('€${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                              ] else
                                Text('€${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              if (item.hasOffer) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                  child: Text(item.offerLabel,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          if (item.freeQuantity > 0) ...[
                            const SizedBox(height: 4),
                            Text('${item.paidQuantity} paid + ${item.freeQuantity} FREE',
                              style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ])),
                        Column(children: [
                          Row(children: [
                            _qtyBtn(Icons.remove, () async {
                              try {
                                await ref.read(cartProvider.notifier).updateItem(item.id, item.quantity - 1);
                              } catch (e) {
                                if (context.mounted) _showError(context, e);
                              }
                            }),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(item.totalWeightLabel ?? '${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600))),
                            _qtyBtn(
                              Icons.add,
                              _effectiveMax(item) != null && item.quantity >= _effectiveMax(item)!
                                  ? null
                                  : () async {
                                      try {
                                        await ref.read(cartProvider.notifier).updateItem(item.id, item.quantity + 1);
                                      } catch (e) {
                                        if (context.mounted) _showError(context, e);
                                      }
                                    },
                              disabled: _effectiveMax(item) != null && item.quantity >= _effectiveMax(item)!,
                            ),
                          ]),
                          if (_effectiveMax(item) != null && item.quantity >= _effectiveMax(item)!)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Max: ${_effectiveMax(item)}', style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                            child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
              child: SafeArea(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('€${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => context.push('/checkout'),
                  child: const Text('Checkout'),
                )),
              ])),
            ),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load cart')),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap, {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: disabled ? AppColors.divider : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: disabled ? AppColors.textHint : null),
      ),
    );
  }

  /// Returns the effective max quantity for a cart item, or null if unlimited.
  int? _effectiveMax(CartItem item) {
    final bool unlimitedStock = item.stockQuantity == -1;
    final int? maxPerOrder = item.maxQuantityPerOrder;
    if (unlimitedStock) return maxPerOrder; // null if no limit at all
    if (maxPerOrder != null && maxPerOrder < item.stockQuantity) return maxPerOrder;
    return item.stockQuantity;
  }

  void _showError(BuildContext context, Object e) {
    String message = 'Something went wrong';
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) message = data['message'];
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)),
    );
  }
}
