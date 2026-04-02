import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 40, backgroundColor: AppColors.primaryLight,
                      child: Text(user.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(user.phone, style: const TextStyle(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _menuItem(context, Icons.shopping_bag_outlined, 'My Orders', () => context.push('/orders')),
              _menuItem(context, Icons.location_on_outlined, 'Addresses', () {
                ref.invalidate(addressesProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Addresses page coming soon')));
              }),
              const SizedBox(height: 16),

              // Store Info section
              const Text('Store Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _StoreInfoCard(ref: ref),

              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  onTap: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  final WidgetRef ref;
  const _StoreInfoCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final storeInfo = ref.watch(storeInfoProvider);
    return storeInfo.when(
      data: (info) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.store, info['store_name'] ?? 'Oraiopoli'),
              if (info['store_address']?.isNotEmpty == true)
                _infoRow(Icons.location_on_outlined, info['store_address']!),
              if (info['store_phone']?.isNotEmpty == true)
                _infoRow(Icons.phone_outlined, info['store_phone']!),
              if (info['store_email']?.isNotEmpty == true)
                _infoRow(Icons.email_outlined, info['store_email']!),
              if (info['store_hours']?.isNotEmpty == true)
                _infoRow(Icons.access_time, info['store_hours']!),
              const Divider(height: 20),
              _infoRow(Icons.local_shipping_outlined,
                  'Delivery: €${info['delivery_fee'] ?? '0'}'),
              _infoRow(Icons.card_giftcard_outlined,
                  'Free delivery over €${info['free_delivery_threshold'] ?? '0'}'),
              _infoRow(Icons.shopping_basket_outlined,
                  'Min. order: €${info['min_order_amount'] ?? '0'}'),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => const Card(
        child: Padding(padding: EdgeInsets.all(20),
          child: Text('Could not load store info')),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}

