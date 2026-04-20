package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.InventoryUpdateRequest;
import com.oraiopoli.supermarket.dto.request.ProductImageRequest;
import com.oraiopoli.supermarket.dto.request.ProductRequest;
import com.oraiopoli.supermarket.dto.response.ProductResponse;
import com.oraiopoli.supermarket.entity.*;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final BrandRepository brandRepository;
    private final InventoryRepository inventoryRepository;
    private final ProductImageRepository productImageRepository;

    // Public methods
    public Page<ProductResponse> getActiveProducts(Pageable pageable) {
        return productRepository.findByActiveTrueSorted(pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    public Page<ProductResponse> getFeaturedProducts(Pageable pageable) {
        return productRepository.findByActiveTrueAndFeaturedTrue(pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    public Page<ProductResponse> getProductsByCategory(Long categoryId, Pageable pageable) {
        return productRepository.findByCategoryIdAndActiveTrue(categoryId, pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    public Page<ProductResponse> getProductsByBrand(Long brandId, Pageable pageable) {
        return productRepository.findByBrandIdAndActiveTrue(brandId, pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    public Page<ProductResponse> searchProducts(String query, Pageable pageable) {
        return productRepository.searchProducts(query, pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    public ProductResponse getProductBySlug(String slug) {
        Product product = productRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "slug", slug));
        return ProductResponse.fromEntity(product);
    }

    public ProductResponse getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        return ProductResponse.fromEntityAdmin(product);
    }

    public Page<ProductResponse> filterProducts(Long categoryId, Long brandId,
                                                  BigDecimal minPrice, BigDecimal maxPrice,
                                                  Boolean inStock, Pageable pageable) {
        Specification<Product> spec = Specification.where(isActive());

        if (categoryId != null) {
            spec = spec.and(hasCategory(categoryId));
        }
        if (brandId != null) {
            spec = spec.and(hasBrand(brandId));
        }
        if (minPrice != null) {
            spec = spec.and(priceGreaterThan(minPrice));
        }
        if (maxPrice != null) {
            spec = spec.and(priceLessThan(maxPrice));
        }

        return productRepository.findAll(spec, pageable)
                .map(ProductResponse::fromEntityLightweight);
    }

    // Admin methods
    public Page<ProductResponse> getAllProducts(Pageable pageable) {
        return productRepository.findAll(pageable)
                .map(ProductResponse::fromEntityAdmin);
    }

    public Page<ProductResponse> getAllProducts(String search, Pageable pageable) {
        if (search != null && !search.isBlank()) {
            return productRepository.searchAllProducts(search, pageable)
                    .map(ProductResponse::fromEntityAdmin);
        }
        return productRepository.findAll(pageable)
                .map(ProductResponse::fromEntityAdmin);
    }

    @Transactional
    public ProductResponse createProduct(ProductRequest request) {
        String slug = generateSlug(request.getName());
        if (productRepository.existsBySlug(slug)) {
            throw new BadRequestException("Product with similar name already exists");
        }
        if (productRepository.existsBySku(request.getSku())) {
            throw new BadRequestException("Product with this SKU already exists");
        }

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));

        Brand brand = null;
        if (request.getBrandId() != null) {
            brand = brandRepository.findById(request.getBrandId())
                    .orElseThrow(() -> new ResourceNotFoundException("Brand", "id", request.getBrandId()));
        }

        Product product = Product.builder()
                .name(request.getName())
                .slug(slug)
                .sku(request.getSku())
                .description(request.getDescription())
                .price(request.getPrice())
                .discountPrice(request.getDiscountPrice())
                .discountStartDate(request.getDiscountStartDate())
                .discountEndDate(request.getDiscountEndDate())
                .buyQuantity(request.getBuyQuantity())
                .getQuantity(request.getGetQuantity())
                .unit(parseUnit(request.getUnit()))
                .weightQuantity(request.getWeightQuantity())
                .weightUnit(request.getWeightUnit())
                .maxQuantityPerOrder(request.getMaxQuantityPerOrder())
                .active(request.isActive())
                .featured(request.isFeatured())
                .thumbnailUrl(request.getThumbnailUrl())
                .category(category)
                .brand(brand)
                .build();

        validateOfferExclusivity(product);
        validateWeighedFields(product);

        product = productRepository.save(product);

        // Create inventory
        Inventory inventory = Inventory.builder()
                .product(product)
                .quantity(request.getStockQuantity())
                .lowStockThreshold(request.getLowStockThreshold())
                .build();
        inventoryRepository.save(inventory);
        product.setInventory(inventory);

        // Create images
        if (request.getImages() != null) {
            for (ProductImageRequest imgReq : request.getImages()) {
                ProductImage image = ProductImage.builder()
                        .imageUrl(imgReq.getImageUrl())
                        .altText(imgReq.getAltText())
                        .displayOrder(imgReq.getDisplayOrder())
                        .product(product)
                        .build();
                productImageRepository.save(image);
                product.getImages().add(image);
            }
        }

        return ProductResponse.fromEntityAdmin(product);
    }

    @Transactional
    public ProductResponse updateProduct(Long id, ProductRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.getCategoryId()));

        Brand brand = null;
        if (request.getBrandId() != null) {
            brand = brandRepository.findById(request.getBrandId())
                    .orElseThrow(() -> new ResourceNotFoundException("Brand", "id", request.getBrandId()));
        }

        product.setName(request.getName());
        product.setSku(request.getSku());
        product.setDescription(request.getDescription());
        product.setPrice(request.getPrice());
        product.setDiscountPrice(request.getDiscountPrice());
        product.setDiscountStartDate(request.getDiscountStartDate());
        product.setDiscountEndDate(request.getDiscountEndDate());
        product.setBuyQuantity(request.getBuyQuantity());
        product.setGetQuantity(request.getGetQuantity());
        product.setUnit(parseUnit(request.getUnit()));
        product.setWeightQuantity(request.getWeightQuantity());
        product.setWeightUnit(request.getWeightUnit());
        product.setMaxQuantityPerOrder(request.getMaxQuantityPerOrder());
        product.setActive(request.isActive());
        product.setFeatured(request.isFeatured());
        product.setThumbnailUrl(request.getThumbnailUrl());
        product.setCategory(category);
        product.setBrand(brand);

        validateOfferExclusivity(product);
        validateWeighedFields(product);

        product = productRepository.save(product);

        // Update inventory
        if (product.getInventory() != null) {
            product.getInventory().setQuantity(request.getStockQuantity());
            product.getInventory().setLowStockThreshold(request.getLowStockThreshold());
            inventoryRepository.save(product.getInventory());
        }

        return ProductResponse.fromEntityAdmin(product);
    }

    @Transactional
    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        productRepository.delete(product);
    }

    @Transactional
    public ProductResponse updateInventory(Long productId, InventoryUpdateRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));

        Inventory inventory = product.getInventory();
        if (inventory == null) {
            inventory = Inventory.builder().product(product).build();
        }

        inventory.setQuantity(request.getQuantity());
        if (request.getLowStockThreshold() != null) {
            inventory.setLowStockThreshold(request.getLowStockThreshold());
        }
        inventoryRepository.save(inventory);

        return ProductResponse.fromEntityAdmin(product);
    }

    public List<ProductResponse> getLowStockProducts() {
        return productRepository.findLowStockProducts().stream()
                .map(ProductResponse::fromEntityAdmin)
                .toList();
    }

    // Validation
    private void validateOfferExclusivity(Product product) {
        boolean hasDiscount = product.getDiscountPrice() != null;
        boolean hasOffer = product.getBuyQuantity() != null && product.getGetQuantity() != null
                && product.getBuyQuantity() >= 1 && product.getGetQuantity() >= 1;
        if (hasDiscount && hasOffer) {
            throw new BadRequestException("A product cannot have both a discount price and a buy+get offer. Please choose one.");
        }
    }

    private void validateWeighedFields(Product product) {
        if (product.getUnit() == UnitType.WEIGHED) {
            if (product.getWeightQuantity() == null || product.getWeightUnit() == null || product.getWeightUnit().isBlank()) {
                throw new BadRequestException("Weighed products require weightQuantity and weightUnit.");
            }
        } else {
            // Clear weight fields for non-weighed products
            product.setWeightQuantity(null);
            product.setWeightUnit(null);
        }
    }

    private UnitType parseUnit(String unit) {
        if (unit == null || unit.isBlank()) return null;
        try {
            return UnitType.valueOf(unit.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid unit type: " + unit + ". Allowed: KG, METERS, LITERS, PIECES, WEIGHED");
        }
    }

    // Specifications
    private Specification<Product> isActive() {
        return (root, query, cb) -> cb.isTrue(root.get("active"));
    }

    private Specification<Product> hasCategory(Long categoryId) {
        return (root, query, cb) -> cb.equal(root.get("category").get("id"), categoryId);
    }

    private Specification<Product> hasBrand(Long brandId) {
        return (root, query, cb) -> cb.equal(root.get("brand").get("id"), brandId);
    }

    private Specification<Product> priceGreaterThan(BigDecimal price) {
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("price"), price);
    }

    private Specification<Product> priceLessThan(BigDecimal price) {
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("price"), price);
    }

    private String generateSlug(String name) {
        return name.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-")
                .trim();
    }
}

