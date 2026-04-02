package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Promotion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromotionResponse {
    private Long id;
    private String title;
    private String description;
    private String code;
    private BigDecimal discountPercentage;
    private BigDecimal discountAmount;
    private BigDecimal minOrderAmount;
    private String imageUrl;
    private boolean active;
    private LocalDateTime startDate;
    private LocalDateTime endDate;

    public static PromotionResponse fromEntity(Promotion promotion) {
        return PromotionResponse.builder()
                .id(promotion.getId())
                .title(promotion.getTitle())
                .description(promotion.getDescription())
                .code(promotion.getCode())
                .discountPercentage(promotion.getDiscountPercentage())
                .discountAmount(promotion.getDiscountAmount())
                .minOrderAmount(promotion.getMinOrderAmount())
                .imageUrl(promotion.getImageUrl())
                .active(promotion.isActive())
                .startDate(promotion.getStartDate())
                .endDate(promotion.getEndDate())
                .build();
    }
}

