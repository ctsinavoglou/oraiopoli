import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/order_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _selectedAddressId;
  final _notesCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  bool _loading = false;
  bool _validatingPromo = false;
  String? _appliedPromo;
  String? _promoTitle;
  double _promoDiscount = 0;
  String? _promoError;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);
    final cart = ref.watch(cartProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: addressesAsync.when(
        data: (addresses) {
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            _selectedAddressId = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first).id;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...addresses.map((addr) => RadioListTile<int>(
                value: addr.id,
                groupValue: _selectedAddressId,
                onChanged: (v) => setState(() => _selectedAddressId = v),
                title: Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${addr.addressLine}${addr.city != null ? ', ${addr.city}' : ''}'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.white,
              )),
              if (addresses.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No addresses. Please add one from your profile.'))),
              const SizedBox(height: 20),
              const Text('Order Notes (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              TextField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Any special instructions...')),

              // Promo Code Section
              const SizedBox(height: 24),
              const Text('Promotion Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCtrl,
                      enabled: _appliedPromo == null,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                        suffixIcon: _appliedPromo != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _removePromo,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _appliedPromo != null || _validatingPromo ? null : _applyPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appliedPromo != null ? AppColors.success : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _validatingPromo
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_appliedPromo != null ? '✓ Applied' : 'Apply'),
                    ),
                  ),
                ],
              ),
              if (_promoError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_promoError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              if (_appliedPromo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '$_promoTitle — You save €${_promoDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              if (cart != null) ...[
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text('${item.productName} x${item.quantity}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (item.hasDiscount) ...[
                          Text('€${(item.originalPrice * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                          const SizedBox(width: 6),
                        ],
                        Text('€${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: item.hasDiscount ? FontWeight.w600 : FontWeight.normal,
                            color: item.hasDiscount ? AppColors.accent : null,
                          )),
                      ]),
                    )),
                    const Divider(height: 20),
                    () {
                      final totalSavings = cart.items.fold<double>(0, (sum, item) =>
                        sum + (item.hasDiscount ? (item.originalPrice - item.unitPrice) * item.quantity : 0));
                      if (totalSavings > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: const [
                              Icon(Icons.savings_outlined, size: 18, color: AppColors.success),
                              SizedBox(width: 6),
                              Text('Product savings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                            ]),
                            Text('-€${totalSavings.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                          ]),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                    if (_promoDiscount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            const Icon(Icons.local_offer, size: 18, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text('Promo ($_appliedPromo)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ]),
                          Text('-€${_promoDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ]),
                      ),
                    // Delivery fee from store settings
                    Builder(builder: (_) {
                      final storeInfo = ref.watch(storeInfoProvider);
                      final fee = storeInfo.whenOrNull(data: (info) => double.tryParse(info['delivery_fee'] ?? '0') ?? 0) ?? 0;
                      final threshold = storeInfo.whenOrNull(data: (info) => double.tryParse(info['free_delivery_threshold'] ?? '0') ?? 0) ?? 0;
                      final subtotalAfterPromo = cart.totalAmount - _promoDiscount;
                      final isFree = threshold > 0 && subtotalAfterPromo >= threshold;
                      final effectiveFee = isFree ? 0.0 : fee;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: [
                              const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              const Text('Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ]),
                            isFree
                                ? Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (fee > 0) Text('€${fee.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                                    if (fee > 0) const SizedBox(width: 6),
                                    const Text('FREE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                                  ])
                                : Text(effectiveFee > 0 ? '€${effectiveFee.toStringAsFixed(2)}' : 'FREE',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                        color: effectiveFee > 0 ? null : AppColors.success)),
                          ]),
                        ),
                        if (!isFree && threshold > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Add €${(threshold - subtotalAfterPromo).toStringAsFixed(2)} more for free delivery!',
                              style: const TextStyle(fontSize: 12, color: AppColors.warning, fontStyle: FontStyle.italic)),
                          ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('€${(subtotalAfterPromo + effectiveFee).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                      ]);
                    }),
                  ]),
                )),
              ],
              const SizedBox(height: 20),
              // Min order amount warning
              Builder(builder: (_) {
                final storeInfo = ref.watch(storeInfoProvider);
                final minOrder = storeInfo.whenOrNull(data: (info) => double.tryParse(info['min_order_amount'] ?? '0') ?? 0) ?? 0;
                final cartTotal = cart?.totalAmount ?? 0;
                if (minOrder > 0 && cartTotal < minOrder) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Minimum order amount is €${minOrder.toStringAsFixed(2)}. Add €${(minOrder - cartTotal).toStringAsFixed(2)} more to place your order.',
                          style: const TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w500),
                        )),
                      ]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Builder(builder: (_) {
                final storeInfo = ref.watch(storeInfoProvider);
                final minOrder = storeInfo.whenOrNull(data: (info) => double.tryParse(info['min_order_amount'] ?? '0') ?? 0) ?? 0;
                final cartTotal = cart?.totalAmount ?? 0;
                final belowMin = minOrder > 0 && cartTotal < minOrder;
                return SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _loading || _selectedAddressId == null || belowMin ? null : _placeOrder,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Place Order'),
                ));
              }),
            ]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load addresses')),
      ),
    );
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null) return;

    setState(() { _validatingPromo = true; _promoError = null; });
    try {
      final result = await ref.read(orderRepositoryProvider).validatePromoCode(code, cart.totalAmount);
      setState(() {
        _appliedPromo = code;
        _promoTitle = result['title'] as String?;
        _promoDiscount = (result['discountAmount'] is int)
            ? (result['discountAmount'] as int).toDouble()
            : (result['discountAmount'] as num).toDouble();
        _promoError = null;
      });
    } catch (e) {
      String message = 'Invalid promotion code';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          message = data['message'];
        }
      }
      setState(() { _promoError = message; });
    }
    setState(() { _validatingPromo = false; });
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoTitle = null;
      _promoDiscount = 0;
      _promoError = null;
      _promoCtrl.clear();
    });
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    try {
      await ref.read(orderRepositoryProvider).checkout(
        _selectedAddressId!,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        promoCode: _appliedPromo,
      );
      ref.invalidate(ordersProvider);
      ref.read(cartProvider.notifier).loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppColors.success));
        context.go('/orders');
      }
    } catch (e) {
      if (mounted) {
        String message = 'Something went wrong. Please try again.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            message = data['message'];
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}

