package com.oraiopoli.supermarket.controller;

import com.oraiopoli.supermarket.dto.response.*;
import com.oraiopoli.supermarket.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
@RequiredArgsConstructor
@Tag(name = "Public", description = "Public endpoints accessible without authentication")
public class PublicController {

    private final ProductService productService;
    private final CategoryService categoryService;
    private final BrandService brandService;
    private final BannerService bannerService;
    private final PromotionService promotionService;
    private final StoreSettingsService storeSettingsService;

    // Categories
    @GetMapping("/categories")
    @Operation(summary = "Get all active categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getCategories() {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getActiveCategories()));
    }

    @GetMapping("/categories/{slug}")
    @Operation(summary = "Get category by slug")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategoryBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getCategoryBySlug(slug)));
    }

    // Brands
    @GetMapping("/brands")
    @Operation(summary = "Get all active brands")
    public ResponseEntity<ApiResponse<List<BrandResponse>>> getBrands() {
        return ResponseEntity.ok(ApiResponse.success(brandService.getActiveBrands()));
    }

    // Products
    @GetMapping("/products")
    @Operation(summary = "Get paginated active products")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getProducts(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.getActiveProducts(pageable)));
    }

    @GetMapping("/products/featured")
    @Operation(summary = "Get featured products")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getFeaturedProducts(
            @PageableDefault(size = 10) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.getFeaturedProducts(pageable)));
    }

    @GetMapping("/products/search")
    @Operation(summary = "Search products by name or description")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> searchProducts(
            @RequestParam String query,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.searchProducts(query, pageable)));
    }

    @GetMapping("/products/filter")
    @Operation(summary = "Filter products by category, brand, price, availability")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> filterProducts(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long brandId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) Boolean inStock,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(
                productService.filterProducts(categoryId, brandId, minPrice, maxPrice, inStock, pageable)));
    }

    @GetMapping("/products/category/{categoryId}")
    @Operation(summary = "Get products by category")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getProductsByCategory(
            @PathVariable Long categoryId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.getProductsByCategory(categoryId, pageable)));
    }

    @GetMapping("/products/brand/{brandId}")
    @Operation(summary = "Get products by brand")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getProductsByBrand(
            @PathVariable Long brandId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.getProductsByBrand(brandId, pageable)));
    }

    @GetMapping("/products/{slug}")
    @Operation(summary = "Get product details by slug")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(ApiResponse.success(productService.getProductBySlug(slug)));
    }

    // Banners
    @GetMapping("/banners")
    @Operation(summary = "Get active banners")
    public ResponseEntity<ApiResponse<List<BannerResponse>>> getBanners() {
        return ResponseEntity.ok(ApiResponse.success(bannerService.getActiveBanners()));
    }

    // Promotions
    @GetMapping("/promotions")
    @Operation(summary = "Get active promotions")
    public ResponseEntity<ApiResponse<List<PromotionResponse>>> getPromotions() {
        return ResponseEntity.ok(ApiResponse.success(promotionService.getActivePromotions()));
    }

    // Store Info
    @GetMapping("/store-info")
    @Operation(summary = "Get public store information (name, hours, delivery fees, etc.)")
    public ResponseEntity<ApiResponse<Map<String, String>>> getStoreInfo() {
        Map<String, String> info = new java.util.HashMap<>(Map.of(
                "store_name", storeSettingsService.getSettingOrDefault("store_name", "Oraiopoli"),
                "store_phone", storeSettingsService.getSettingOrDefault("store_phone", ""),
                "store_email", storeSettingsService.getSettingOrDefault("store_email", ""),
                "store_address", storeSettingsService.getSettingOrDefault("store_address", ""),
                "store_hours", storeSettingsService.getSettingOrDefault("store_hours", ""),
                "delivery_fee", storeSettingsService.getSettingOrDefault("delivery_fee", "0"),
                "free_delivery_threshold", storeSettingsService.getSettingOrDefault("free_delivery_threshold", "0"),
                "min_order_amount", storeSettingsService.getSettingOrDefault("min_order_amount", "0"),
                "currency", storeSettingsService.getSettingOrDefault("currency", "EUR")
        ));
        info.put("store_latitude", storeSettingsService.getSettingOrDefault("store_latitude", "0"));
        info.put("store_longitude", storeSettingsService.getSettingOrDefault("store_longitude", "0"));
        info.put("max_delivery_km", storeSettingsService.getSettingOrDefault("max_delivery_km", "10"));
        info.put("express_delivery_fee", storeSettingsService.getSettingOrDefault("express_delivery_fee", "1.00"));
        info.put("plastic_bag_fee_per_10", storeSettingsService.getSettingOrDefault("plastic_bag_fee_per_10", "0.10"));
        return ResponseEntity.ok(ApiResponse.success(info));
    }
}

