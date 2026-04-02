package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class PromotionRequest {
    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private String code;
    private BigDecimal discountPercentage;
    private BigDecimal discountAmount;
    private BigDecimal minOrderAmount;
    private String imageUrl;
    private boolean active = true;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
}

