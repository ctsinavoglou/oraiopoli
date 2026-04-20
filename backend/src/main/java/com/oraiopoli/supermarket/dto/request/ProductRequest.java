package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
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

    private LocalDateTime discountStartDate;
    private LocalDateTime discountEndDate;

    private Integer buyQuantity;
    private Integer getQuantity;

    private String unit;

    private BigDecimal weightQuantity;
    private String weightUnit;

    @Min(value = 1, message = "Max quantity per order must be at least 1")
    private Integer maxQuantityPerOrder;

    private boolean active = true;
    private boolean featured = false;

    private String thumbnailUrl;

    @NotNull(message = "Category is required")
    private Long categoryId;

    private Long brandId;

    @Min(value = -1, message = "Stock quantity must be -1 (unlimited) or >= 0")
    private int stockQuantity = -1;

    private int lowStockThreshold = 10;

    private List<ProductImageRequest> images;
}

