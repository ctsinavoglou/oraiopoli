package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class ProductRequest {
    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "SKU is required")
    private String sku;

    private String description;

    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private BigDecimal price;

    private BigDecimal discountPrice;

    private String unit;

    private boolean active = true;
    private boolean featured = false;

    private String thumbnailUrl;

    @NotNull(message = "Category is required")
    private Long categoryId;

    private Long brandId;

    @Min(value = 0, message = "Stock quantity cannot be negative")
    private int stockQuantity = 0;

    private int lowStockThreshold = 10;

    private List<ProductImageRequest> images;
}

