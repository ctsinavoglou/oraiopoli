import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/responsive/responsive.dart';
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
    final isDesktop = Responsive.isLarge(context);

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

          // Center content with max width on large screens
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 14 : 10),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      final imgSize = isDesktop ? 90.0 : 70.0;
                      return Card(
                        key: ValueKey(item.id),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: null, // card is not tappable as a whole
                          child: Padding(
                            padding: EdgeInsets.all(isDesktop ? 16 : 12),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: item.resolvedProductThumbnail != null
                                    ? CachedNetworkImage(imageUrl: item.resolvedProductThumbnail!, width: imgSize, height: imgSize, fit: BoxFit.cover)
                                    : Container(width: imgSize, height: imgSize, color: AppColors.divider, child: const Icon(Icons.image)),
                              ),
                              SizedBox(width: isDesktop ? 20 : 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.productName,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 15 : 14),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (item.hasDiscount) ...[
                                      Text('€${item.originalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                                      const SizedBox(width: 4),
                                      Text('€${item.unitPrice.toStringAsFixed(2)}',
                                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: isDesktop ? 15 : 13)),
                                    ] else
                                      Text('€${item.unitPrice.toStringAsFixed(2)}',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: isDesktop ? 15 : 13)),
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
                                  _qtyBtn(Icons.remove, isDesktop, () async {
                                    try {
                                      await ref.read(cartProvider.notifier).updateItem(item.id, item.quantity - 1);
                                    } catch (e) {
                                      if (context.mounted) _showError(context, e);
                                    }
                                  }),
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(item.totalWeightLabel ?? '${item.quantity}',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 15 : 14))),
                                  _qtyBtn(Icons.add, isDesktop,
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
                                const SizedBox(height: 6),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                                    child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ),
                                ),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 16,
                    isDesktop ? 24 : 16,
                    isDesktop ? 24 : 16,
                    isDesktop ? 24 : 16,
                  ),
                  decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
                  child: SafeArea(
                    top: false,
                    child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            Text('€${cart.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ]),
                          SizedBox(
                            width: 220,
                            child: ElevatedButton(
                              onPressed: () => context.push('/checkout'),
                              child: const Text('Checkout'),
                            ),
                          ),
                        ],
                      )
                    : Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('€${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ElevatedButton(
                          onPressed: () => context.push('/checkout'),
                          child: const Text('Checkout'),
                        )),
                      ]),
                  ),
                ),
              ]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load cart')),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, bool isDesktop, VoidCallback? onTap, {bool disabled = false}) {
    final size = isDesktop ? 10.0 : 4.0;
    final iconSize = isDesktop ? 20.0 : 16.0;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(size),
          decoration: BoxDecoration(
            border: Border.all(color: disabled ? AppColors.divider : AppColors.border),
            borderRadius: BorderRadius.circular(6),
            color: disabled ? AppColors.divider.withValues(alpha: 0.3) : null,
          ),
          child: Icon(icon, size: iconSize, color: disabled ? AppColors.textHint : AppColors.textPrimary),
        ),
      ),
    );
  }

  int? _effectiveMax(CartItem item) {
    final bool unlimitedStock = item.stockQuantity == -1;
    final int? maxPerOrder = item.maxQuantityPerOrder;
    if (unlimitedStock) return maxPerOrder;
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
