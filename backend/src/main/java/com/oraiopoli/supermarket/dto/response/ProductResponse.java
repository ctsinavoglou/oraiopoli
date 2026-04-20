package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Product;
import com.oraiopoli.supermarket.entity.UnitType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductResponse {
    private Long id;
    private String name;
    private String slug;
    private String sku;
    private String description;
    private BigDecimal price;
    private BigDecimal discountPrice;
    private LocalDateTime discountStartDate;
    private LocalDateTime discountEndDate;
    private Integer buyQuantity;
    private Integer getQuantity;
    private String unit;
    private BigDecimal weightQuantity;
    private String weightUnit;
    private BigDecimal pricePerUnit;
    private BigDecimal discountPricePerUnit;
    private String pricePerUnitLabel;
    private boolean active;
    private boolean featured;
    private String thumbnailUrl;
    private String categoryName;
    private Long categoryId;
    private String brandName;
    private Long brandId;
    private int stockQuantity;
    private boolean inStock;
    private Integer maxQuantityPerOrder;
    private List<ProductImageResponse> images;

    /**
     * Checks whether the discount is currently active based on date range.
     * If no dates are set, the discount is always active (backwards compatible).
     */
    private static boolean isDiscountActive(Product product) {
        if (product.getDiscountPrice() == null) return false;
        return isWithinDateRange(product);
    }

    /**
     * Checks whether the buy+get offer is currently active based on date range.
     */
    private static boolean isOfferActive(Product product) {
        if (product.getBuyQuantity() == null || product.getGetQuantity() == null) return false;
        if (product.getBuyQuantity() < 1 || product.getGetQuantity() < 1) return false;
        return isWithinDateRange(product);
    }

    private static boolean isWithinDateRange(Product product) {
        LocalDateTime now = LocalDateTime.now();
        if (product.getDiscountStartDate() != null && now.isBefore(product.getDiscountStartDate())) return false;
        if (product.getDiscountEndDate() != null && now.isAfter(product.getDiscountEndDate())) return false;
        return true;
    }

    /**
     * Computes the divisor to convert from sub-unit to base unit.
     * gr -> /1000 (per kg), ml -> /1000 (per lt), cm -> /100 (per m), pieces -> quantity itself (per piece).
     */
    private static BigDecimal getConversionFactor(String weightUnit, BigDecimal weightQuantity) {
        if (weightUnit == null || weightQuantity == null || weightQuantity.compareTo(BigDecimal.ZERO) <= 0) return null;
        return switch (weightUnit.toLowerCase()) {
            case "gr" -> weightQuantity.divide(new BigDecimal("1000"), 10, RoundingMode.HALF_UP);
            case "ml" -> weightQuantity.divide(new BigDecimal("1000"), 10, RoundingMode.HALF_UP);
            case "cm" -> weightQuantity.divide(new BigDecimal("100"), 10, RoundingMode.HALF_UP);
            case "pieces" -> weightQuantity;
            default -> null;
        };
    }

    private static String getBaseUnitLabel(String weightUnit) {
        if (weightUnit == null) return null;
        return switch (weightUnit.toLowerCase()) {
            case "gr" -> "/kg";
            case "ml" -> "/lt";
            case "cm" -> "/m";
            case "pieces" -> "/pc";
            default -> null;
        };
    }

    /**
     * Returns the per-unit label for non-WEIGHED unit types.
     */
    private static String getDirectUnitLabel(UnitType unit) {
        if (unit == null) return null;
        return switch (unit) {
            case KG -> "/kg";
            case LITERS -> "/lt";
            case METERS -> "/m";
            case PIECES -> "/pc";
            default -> null;
        };
    }

    /**
     * Applies pricePerUnit and discountPricePerUnit to the builder.
     * - For KG, LITERS, METERS, PIECES: the price IS the per-unit price already.
     * - For WEIGHED: we compute from the weightQuantity/weightUnit conversion.
     */
    private static void applyPricePerUnit(ProductResponseBuilder builder, Product product, BigDecimal discountPrice) {
        if (product.getUnit() == null) return;

        if (product.getUnit() == UnitType.WEIGHED) {
            // Weighed: compute price per base unit from sub-unit quantity
            if (product.getWeightQuantity() == null || product.getWeightUnit() == null) return;
            BigDecimal factor = getConversionFactor(product.getWeightUnit(), product.getWeightQuantity());
            if (factor == null || factor.compareTo(BigDecimal.ZERO) <= 0) return;
            String label = getBaseUnitLabel(product.getWeightUnit());
            builder.pricePerUnit(product.getPrice().divide(factor, 2, RoundingMode.HALF_UP));
            builder.pricePerUnitLabel(label);
            builder.weightQuantity(product.getWeightQuantity());
            builder.weightUnit(product.getWeightUnit());
            if (discountPrice != null) {
                builder.discountPricePerUnit(discountPrice.divide(factor, 2, RoundingMode.HALF_UP));
            }
        } else {
            // KG, LITERS, METERS, PIECES: price already IS per unit
            String label = getDirectUnitLabel(product.getUnit());
            if (label == null) return;
            builder.pricePerUnit(product.getPrice());
            builder.pricePerUnitLabel(label);
            if (discountPrice != null) {
                builder.discountPricePerUnit(discountPrice);
            }
        }
    }

    public static ProductResponse fromEntity(Product product) {
        BigDecimal activeDiscount = isDiscountActive(product) ? product.getDiscountPrice() : null;
        ProductResponseBuilder builder = ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .description(product.getDescription())
                .price(product.getPrice())
                .discountPrice(activeDiscount)
                .discountStartDate(product.getDiscountStartDate())
                .discountEndDate(product.getDiscountEndDate())
                .buyQuantity(isOfferActive(product) ? product.getBuyQuantity() : null)
                .getQuantity(isOfferActive(product) ? product.getGetQuantity() : null)
                .unit(product.getUnit() != null ? product.getUnit().name() : null)
                .active(product.isActive())
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .brandId(product.getBrand() != null ? product.getBrand().getId() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .maxQuantityPerOrder(product.getMaxQuantityPerOrder())
                .images(product.getImages() != null
                        ? product.getImages().stream().map(ProductImageResponse::fromEntity).toList()
                        : null);
        applyPricePerUnit(builder, product, activeDiscount);
        return builder.build();
    }

    public static ProductResponse fromEntityLightweight(Product product) {
        BigDecimal activeDiscount = isDiscountActive(product) ? product.getDiscountPrice() : null;
        ProductResponseBuilder builder = ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .price(product.getPrice())
                .discountPrice(activeDiscount)
                .buyQuantity(isOfferActive(product) ? product.getBuyQuantity() : null)
                .getQuantity(isOfferActive(product) ? product.getGetQuantity() : null)
                .unit(product.getUnit() != null ? product.getUnit().name() : null)
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .maxQuantityPerOrder(product.getMaxQuantityPerOrder());
        applyPricePerUnit(builder, product, activeDiscount);
        return builder.build();
    }

    /**
     * Admin variant — always includes the raw discountPrice regardless of date range,
     * so the admin can see and edit scheduled discounts.
     */
    public static ProductResponse fromEntityAdmin(Product product) {
        ProductResponseBuilder builder = ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .description(product.getDescription())
                .price(product.getPrice())
                .discountPrice(product.getDiscountPrice())
                .discountStartDate(product.getDiscountStartDate())
                .discountEndDate(product.getDiscountEndDate())
                .buyQuantity(product.getBuyQuantity())
                .getQuantity(product.getGetQuantity())
                .unit(product.getUnit() != null ? product.getUnit().name() : null)
                .weightQuantity(product.getWeightQuantity())
                .weightUnit(product.getWeightUnit())
                .active(product.isActive())
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .brandId(product.getBrand() != null ? product.getBrand().getId() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .maxQuantityPerOrder(product.getMaxQuantityPerOrder())
                .images(product.getImages() != null
                        ? product.getImages().stream().map(ProductImageResponse::fromEntity).toList()
                        : null);
        applyPricePerUnit(builder, product, product.getDiscountPrice());
        return builder.build();
    }
}

