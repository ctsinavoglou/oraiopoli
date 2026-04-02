import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/product_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No categories available'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final cat = list[i];
                  final hasChildren = cat.hasChildren;
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cat.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: cat.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.category, color: AppColors.primary),
                              )
                            : const Icon(Icons.category, color: AppColors.primary),
                      ),
                      title: Text(cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: hasChildren
                          ? Text(
                              '${cat.children!.length} subcategories',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary),
                            )
                          : cat.description != null
                              ? Text(cat.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                      trailing: Icon(
                        hasChildren ? Icons.expand_more : Icons.chevron_right,
                        color: AppColors.textHint,
                      ),
                      onTap: () {
                        if (hasChildren) {
                          context.push('/category/${cat.id}');
                        } else {
                          context.push(
                              '/products/category/${cat.id}?title=${cat.name}');
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Failed to load categories')),
      ),
    );
  }
}
