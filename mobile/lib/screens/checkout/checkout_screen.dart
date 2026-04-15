import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/order_repository.dart';
import '../../models/models.dart';

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
  String _selectedDeliveryMethod = 'STANDARD';
  String? _selectedTimeSlot;
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

              // Delivery Method Section
              const SizedBox(height: 24),
              const Text('Delivery Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Builder(builder: (_) {
                final storeInfo = ref.watch(storeInfoProvider);
                final expressFee = storeInfo.whenOrNull(data: (info) => double.tryParse(info['express_delivery_fee'] ?? '1.00') ?? 1.0) ?? 1.0;
                return Column(children: [
                  _buildDeliveryMethodTile('STANDARD', Icons.local_shipping_outlined, 'Standard Delivery', 'Choose a 2-hour time slot'),
                  const SizedBox(height: 8),
                  _buildDeliveryMethodTile('EXPRESS', Icons.flash_on, 'Express Delivery', 'Delivered within 1 hour (+€${expressFee.toStringAsFixed(2)})'),
                  const SizedBox(height: 8),
                  _buildDeliveryMethodTile('PICKUP', Icons.store_outlined, 'Store Pickup', 'Pick up from the store directly'),
                ]);
              }),

              // Delivery Time Slot (only for Standard)
              if (_selectedDeliveryMethod == 'STANDARD') ...[
                const SizedBox(height: 24),
                const Text('Delivery Time Slot (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTimeSlotChip(null, 'Any time'),
                    _buildTimeSlotChip('09:00-11:00', '09:00–11:00'),
                    _buildTimeSlotChip('11:00-13:00', '11:00–13:00'),
                    _buildTimeSlotChip('13:00-15:00', '13:00–15:00'),
                    _buildTimeSlotChip('15:00-17:00', '15:00–17:00'),
                    _buildTimeSlotChip('17:00-19:00', '17:00–19:00'),
                    _buildTimeSlotChip('19:00-21:00', '19:00–21:00'),
                  ],
                ),
              ],

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Row(children: [
                              Flexible(child: Text('${item.productName} ${item.isWeighed ? item.totalWeightLabel! : 'x${item.quantity}'}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (item.hasOffer) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
                                  child: Text(item.offerLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ])),
                            if (item.hasDiscount || item.freeQuantity > 0) ...[
                              Text('€${(item.originalPrice * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                              const SizedBox(width: 6),
                            ],
                            Text('€${item.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: (item.hasDiscount || item.freeQuantity > 0) ? FontWeight.w600 : FontWeight.normal,
                                color: (item.hasDiscount || item.freeQuantity > 0) ? AppColors.accent : null,
                              )),
                          ]),
                          if (item.freeQuantity > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('${item.paidQuantity} paid + ${item.freeQuantity} FREE',
                                style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    )),
                    const Divider(height: 20),
                    () {
                      final totalSavings = cart.items.fold<double>(0, (sum, item) {
                        double saving = 0;
                        if (item.hasDiscount) {
                          saving += (item.originalPrice - item.unitPrice) * item.quantity;
                        }
                        if (item.freeQuantity > 0) {
                          saving += item.unitPrice * item.freeQuantity;
                        }
                        return sum + saving;
                      });
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
                      final expressFee = storeInfo.whenOrNull(data: (info) => double.tryParse(info['express_delivery_fee'] ?? '1.00') ?? 1.0) ?? 1.0;
                      final bagRate = storeInfo.whenOrNull(data: (info) => double.tryParse(info['plastic_bag_fee_per_10'] ?? '0.10') ?? 0.10) ?? 0.10;
                      final subtotalAfterPromo = cart.totalAmount - _promoDiscount;

                      // Plastic bag fee: rate per €10
                      final bagUnits = (subtotalAfterPromo / 10).floor();
                      final plasticBagFee = bagRate * (bagUnits > 0 ? bagUnits : 0);

                      // Delivery fee based on method
                      double effectiveDeliveryFee;
                      if (_selectedDeliveryMethod == 'PICKUP') {
                        effectiveDeliveryFee = 0;
                      } else {
                        final isFree = threshold > 0 && subtotalAfterPromo >= threshold;
                        effectiveDeliveryFee = isFree ? 0.0 : fee;
                      }

                      // Express surcharge
                      final effectiveExpressFee = _selectedDeliveryMethod == 'EXPRESS' ? expressFee : 0.0;

                      final total = subtotalAfterPromo + plasticBagFee + effectiveDeliveryFee + effectiveExpressFee;

                      return Column(children: [
                        // Plastic bag fee
                        if (plasticBagFee > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: const [
                                Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text('Plastic bags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ]),
                              Text('€${plasticBagFee.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        // Delivery row
                        if (_selectedDeliveryMethod != 'PICKUP')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: [
                                const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                const Text('Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ]),
                              effectiveDeliveryFee == 0 && fee > 0
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text('€${fee.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                                      const SizedBox(width: 6),
                                      const Text('FREE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    ])
                                  : Text(effectiveDeliveryFee > 0 ? '€${effectiveDeliveryFee.toStringAsFixed(2)}' : 'FREE',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                          color: effectiveDeliveryFee > 0 ? null : AppColors.success)),
                            ]),
                          ),
                        if (_selectedDeliveryMethod != 'PICKUP' && effectiveDeliveryFee > 0 && threshold > 0 && subtotalAfterPromo < threshold)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Add €${(threshold - subtotalAfterPromo).toStringAsFixed(2)} more for free delivery!',
                              style: const TextStyle(fontSize: 12, color: AppColors.warning, fontStyle: FontStyle.italic)),
                          ),
                        if (_selectedDeliveryMethod == 'PICKUP')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: const [
                                Icon(Icons.store_outlined, size: 18, color: AppColors.success),
                                SizedBox(width: 6),
                                Text('Store Pickup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                              ]),
                              const Text('FREE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ]),
                          ),
                        // Express fee
                        if (_selectedDeliveryMethod == 'EXPRESS')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: const [
                                Icon(Icons.flash_on, size: 18, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text('Express surcharge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ]),
                              Text('€${expressFee.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        // Total
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('€${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                      ]);
                    }),
                  ]),
                )),
              ],
              const SizedBox(height: 20),
              // Delivery distance warning (skip for PICKUP)
              if (_selectedDeliveryMethod != 'PICKUP')
              Builder(builder: (_) {
                final storeInfo = ref.watch(storeInfoProvider);
                final addresses = ref.watch(addressesProvider).valueOrNull ?? [];
                final storeLat = storeInfo.whenOrNull(data: (info) => double.tryParse(info['store_latitude'] ?? '0')) ?? 0;
                final storeLng = storeInfo.whenOrNull(data: (info) => double.tryParse(info['store_longitude'] ?? '0')) ?? 0;
                final maxKm = storeInfo.whenOrNull(data: (info) => double.tryParse(info['max_delivery_km'] ?? '10')) ?? 10;

                Address? selectedAddr;
                if (_selectedAddressId != null && addresses.isNotEmpty) {
                  selectedAddr = addresses.cast<Address?>().firstWhere((a) => a!.id == _selectedAddressId, orElse: () => null);
                }

                if (selectedAddr != null && selectedAddr.latitude != null && selectedAddr.longitude != null && storeLat != 0) {
                  final dist = _haversineKm(storeLat, storeLng, selectedAddr.latitude!, selectedAddr.longitude!);
                  if (dist > maxKm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 22),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            'Your address is ${dist.toStringAsFixed(1)} km away. We deliver up to ${maxKm.toStringAsFixed(0)} km. Please update your address.',
                            style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500),
                          )),
                        ]),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              }),
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

                // Check delivery distance (not for PICKUP)
                bool exceedsDistance = false;
                if (_selectedDeliveryMethod != 'PICKUP') {
                  final addresses = ref.watch(addressesProvider).valueOrNull ?? [];
                  final storeLat = storeInfo.whenOrNull(data: (info) => double.tryParse(info['store_latitude'] ?? '0')) ?? 0;
                  final storeLng = storeInfo.whenOrNull(data: (info) => double.tryParse(info['store_longitude'] ?? '0')) ?? 0;
                  final maxKm = storeInfo.whenOrNull(data: (info) => double.tryParse(info['max_delivery_km'] ?? '10')) ?? 10;
                  if (_selectedAddressId != null && addresses.isNotEmpty) {
                    final addr = addresses.cast<Address?>().firstWhere((a) => a!.id == _selectedAddressId, orElse: () => null);
                    if (addr != null && addr.latitude != null && addr.longitude != null && storeLat != 0) {
                      exceedsDistance = _haversineKm(storeLat, storeLng, addr.latitude!, addr.longitude!) > maxKm;
                    }
                  }
                }

                return SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _loading || _selectedAddressId == null || belowMin || exceedsDistance ? null : _placeOrder,
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

  Widget _buildDeliveryMethodTile(String value, IconData icon, String title, String subtitle) {
    final isSelected = _selectedDeliveryMethod == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDeliveryMethod = value;
        if (value != 'STANDARD') _selectedTimeSlot = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 24, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12,
              color: isSelected ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textHint)),
          ])),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
        ]),
      ),
    );
  }

  Widget _buildTimeSlotChip(String? value, String label) {
    final isSelected = _selectedTimeSlot == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTimeSlot = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
      showCheckmark: false,
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

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    try {
      await ref.read(orderRepositoryProvider).checkout(
        _selectedAddressId!,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        promoCode: _appliedPromo,
        deliveryTimeSlot: _selectedDeliveryMethod == 'STANDARD' ? _selectedTimeSlot : null,
        deliveryMethod: _selectedDeliveryMethod,
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

