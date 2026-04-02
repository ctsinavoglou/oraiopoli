package com.oraiopoli.supermarket.controller;

import com.oraiopoli.supermarket.dto.request.*;
import com.oraiopoli.supermarket.dto.response.*;
import com.oraiopoli.supermarket.entity.OrderStatus;
import com.oraiopoli.supermarket.entity.Role;
import com.oraiopoli.supermarket.entity.StoreSettings;
import com.oraiopoli.supermarket.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Admin-only management endpoints")
public class AdminController {

    private final DashboardService dashboardService;
    private final UserService userService;
    private final CategoryService categoryService;
    private final BrandService brandService;
    private final ProductService productService;
    private final OrderService orderService;
    private final BannerService bannerService;
    private final PromotionService promotionService;
    private final StoreSettingsService storeSettingsService;
    private final FileStorageService fileStorageService;

    // Dashboard
    @GetMapping("/dashboard")
    @Operation(summary = "Get dashboard statistics")
    public ResponseEntity<ApiResponse<DashboardResponse>> getDashboard() {
        return ResponseEntity.ok(ApiResponse.success(dashboardService.getDashboardStats()));
    }

    // File Upload
    @PostMapping(value = "/upload/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Upload an image file")
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "products") String type) {
        String url = fileStorageService.storeFile(file, type);
        return ResponseEntity.ok(ApiResponse.success(Map.of("url", url)));
    }

    // Users
    @GetMapping("/users")
    @Operation(summary = "Get all users with search and pagination")
    public ResponseEntity<ApiResponse<Page<UserResponse>>> getUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Role role,
            @PageableDefault(size = 20) Pageable pageable) {
        if (search != null && !search.isBlank()) {
            return ResponseEntity.ok(ApiResponse.success(userService.searchUsers(search, pageable)));
        }
        if (role != null) {
            return ResponseEntity.ok(ApiResponse.success(userService.getUsersByRole(role, pageable)));
        }
        return ResponseEntity.ok(ApiResponse.success(userService.getAllUsers(pageable)));
    }

    @GetMapping("/users/{id}")
    @Operation(summary = "Get user by ID")
    public ResponseEntity<ApiResponse<UserResponse>> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(userService.getUserById(id)));
    }

    @PatchMapping("/users/{id}/toggle-status")
    @Operation(summary = "Enable or disable user")
    public ResponseEntity<ApiResponse<UserResponse>> toggleUserStatus(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(userService.toggleUserStatus(id)));
    }

    // Categories
    @GetMapping("/categories")
    @Operation(summary = "Get all categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getCategories() {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getAllCategories()));
    }

    @GetMapping("/categories/{id}")
    @Operation(summary = "Get category by ID")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategory(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(categoryService.getCategoryById(id)));
    }

    @PostMapping("/categories")
    @Operation(summary = "Create category")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(@Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(categoryService.createCategory(request)));
    }

    @PutMapping("/categories/{id}")
    @Operation(summary = "Update category")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.ok(ApiResponse.success(categoryService.updateCategory(id, request)));
    }

    @DeleteMapping("/categories/{id}")
    @Operation(summary = "Delete category")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Long id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(ApiResponse.success("Category deleted", null));
    }

    // Brands
    @GetMapping("/brands")
    @Operation(summary = "Get all brands")
    public ResponseEntity<ApiResponse<List<BrandResponse>>> getBrands() {
        return ResponseEntity.ok(ApiResponse.success(brandService.getAllBrands()));
    }

    @GetMapping("/brands/{id}")
    @Operation(summary = "Get brand by ID")
    public ResponseEntity<ApiResponse<BrandResponse>> getBrand(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(brandService.getBrandById(id)));
    }

    @PostMapping("/brands")
    @Operation(summary = "Create brand")
    public ResponseEntity<ApiResponse<BrandResponse>> createBrand(@Valid @RequestBody BrandRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(brandService.createBrand(request)));
    }

    @PutMapping("/brands/{id}")
    @Operation(summary = "Update brand")
    public ResponseEntity<ApiResponse<BrandResponse>> updateBrand(
            @PathVariable Long id,
            @Valid @RequestBody BrandRequest request) {
        return ResponseEntity.ok(ApiResponse.success(brandService.updateBrand(id, request)));
    }

    @DeleteMapping("/brands/{id}")
    @Operation(summary = "Delete brand")
    public ResponseEntity<ApiResponse<Void>> deleteBrand(@PathVariable Long id) {
        brandService.deleteBrand(id);
        return ResponseEntity.ok(ApiResponse.success("Brand deleted", null));
    }

    // Products
    @GetMapping("/products")
    @Operation(summary = "Get all products with pagination")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getProducts(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(productService.getAllProducts(pageable)));
    }

    @GetMapping("/products/{id}")
    @Operation(summary = "Get product by ID")
    public ResponseEntity<ApiResponse<ProductResponse>> getProduct(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(productService.getProductById(id)));
    }

    @PostMapping("/products")
    @Operation(summary = "Create product")
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(@Valid @RequestBody ProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(productService.createProduct(request)));
    }

    @PutMapping("/products/{id}")
    @Operation(summary = "Update product")
    public ResponseEntity<ApiResponse<ProductResponse>> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody ProductRequest request) {
        return ResponseEntity.ok(ApiResponse.success(productService.updateProduct(id, request)));
    }

    @DeleteMapping("/products/{id}")
    @Operation(summary = "Delete product")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
        return ResponseEntity.ok(ApiResponse.success("Product deleted", null));
    }

    @PatchMapping("/products/{id}/inventory")
    @Operation(summary = "Update product inventory/stock")
    public ResponseEntity<ApiResponse<ProductResponse>> updateInventory(
            @PathVariable Long id,
            @Valid @RequestBody InventoryUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(productService.updateInventory(id, request)));
    }

    @GetMapping("/products/low-stock")
    @Operation(summary = "Get low stock products")
    public ResponseEntity<ApiResponse<List<ProductResponse>>> getLowStockProducts() {
        return ResponseEntity.ok(ApiResponse.success(productService.getLowStockProducts()));
    }

    // Orders
    @GetMapping("/orders")
    @Operation(summary = "Get all orders with filtering")
    public ResponseEntity<ApiResponse<Page<OrderResponse>>> getOrders(
            @RequestParam(required = false) OrderStatus status,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getAllOrders(status, search, pageable)));
    }

    @GetMapping("/orders/{id}")
    @Operation(summary = "Get order details")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrder(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getOrderById(id)));
    }

    @PatchMapping("/orders/{id}/status")
    @Operation(summary = "Update order status")
    public ResponseEntity<ApiResponse<OrderResponse>> updateOrderStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateOrderStatusRequest request) {
        return ResponseEntity.ok(ApiResponse.success(orderService.updateOrderStatus(id, request)));
    }

    // Banners
    @GetMapping("/banners")
    @Operation(summary = "Get all banners")
    public ResponseEntity<ApiResponse<List<BannerResponse>>> getBanners() {
        return ResponseEntity.ok(ApiResponse.success(bannerService.getAllBanners()));
    }

    @GetMapping("/banners/{id}")
    @Operation(summary = "Get banner by ID")
    public ResponseEntity<ApiResponse<BannerResponse>> getBanner(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(bannerService.getBannerById(id)));
    }

    @PostMapping("/banners")
    @Operation(summary = "Create banner")
    public ResponseEntity<ApiResponse<BannerResponse>> createBanner(@Valid @RequestBody BannerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(bannerService.createBanner(request)));
    }

    @PutMapping("/banners/{id}")
    @Operation(summary = "Update banner")
    public ResponseEntity<ApiResponse<BannerResponse>> updateBanner(
            @PathVariable Long id,
            @Valid @RequestBody BannerRequest request) {
        return ResponseEntity.ok(ApiResponse.success(bannerService.updateBanner(id, request)));
    }

    @DeleteMapping("/banners/{id}")
    @Operation(summary = "Delete banner")
    public ResponseEntity<ApiResponse<Void>> deleteBanner(@PathVariable Long id) {
        bannerService.deleteBanner(id);
        return ResponseEntity.ok(ApiResponse.success("Banner deleted", null));
    }

    // Promotions
    @GetMapping("/promotions")
    @Operation(summary = "Get all promotions")
    public ResponseEntity<ApiResponse<List<PromotionResponse>>> getPromotions() {
        return ResponseEntity.ok(ApiResponse.success(promotionService.getAllPromotions()));
    }

    @GetMapping("/promotions/{id}")
    @Operation(summary = "Get promotion by ID")
    public ResponseEntity<ApiResponse<PromotionResponse>> getPromotion(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(promotionService.getPromotionById(id)));
    }

    @PostMapping("/promotions")
    @Operation(summary = "Create promotion")
    public ResponseEntity<ApiResponse<PromotionResponse>> createPromotion(@Valid @RequestBody PromotionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(promotionService.createPromotion(request)));
    }

    @PutMapping("/promotions/{id}")
    @Operation(summary = "Update promotion")
    public ResponseEntity<ApiResponse<PromotionResponse>> updatePromotion(
            @PathVariable Long id,
            @Valid @RequestBody PromotionRequest request) {
        return ResponseEntity.ok(ApiResponse.success(promotionService.updatePromotion(id, request)));
    }

    @DeleteMapping("/promotions/{id}")
    @Operation(summary = "Delete promotion")
    public ResponseEntity<ApiResponse<Void>> deletePromotion(@PathVariable Long id) {
        promotionService.deletePromotion(id);
        return ResponseEntity.ok(ApiResponse.success("Promotion deleted", null));
    }

    // Store Settings
    @GetMapping("/settings")
    @Operation(summary = "Get all store settings")
    public ResponseEntity<ApiResponse<Map<String, String>>> getSettings() {
        return ResponseEntity.ok(ApiResponse.success(storeSettingsService.getAllSettings()));
    }

    @GetMapping("/settings/{key}")
    @Operation(summary = "Get setting by key")
    public ResponseEntity<ApiResponse<String>> getSetting(@PathVariable String key) {
        return ResponseEntity.ok(ApiResponse.success(storeSettingsService.getSetting(key)));
    }

    @PostMapping("/settings")
    @Operation(summary = "Create or update setting")
    public ResponseEntity<ApiResponse<StoreSettings>> upsertSetting(@Valid @RequestBody StoreSettingsRequest request) {
        return ResponseEntity.ok(ApiResponse.success(storeSettingsService.upsertSetting(request)));
    }

    @DeleteMapping("/settings/{key}")
    @Operation(summary = "Delete setting")
    public ResponseEntity<ApiResponse<Void>> deleteSetting(@PathVariable String key) {
        storeSettingsService.deleteSetting(key);
        return ResponseEntity.ok(ApiResponse.success("Setting deleted", null));
    }
}

