import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final Future<void> Function()? onAddToCart;

  const ProductCard({super.key, required this.product, required this.onTap, this.onAddToCart});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: product.resolvedThumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.resolvedThumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.divider),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.divider,
                              child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textHint),
                            ),
                          )
                        : Container(
                            color: AppColors.divider,
                            child: const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.textHint),
                          ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '-${((1 - product.discountPrice! / product.price) * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (!product.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Out of Stock', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Row(
                      children: [
                        if (product.hasDiscount) ...[
                          Text('€${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                          const SizedBox(width: 4),
                          Text('€${product.discountPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ] else
                          Text('€${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const Spacer(),
                        if (product.inStock && widget.onAddToCart != null)
                          GestureDetector(
                            onTap: _adding ? null : () async {
                              setState(() => _adding = true);
                              await widget.onAddToCart!();
                              if (mounted) setState(() => _adding = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                              child: _adding
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

