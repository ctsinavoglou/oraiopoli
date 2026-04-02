package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.PromotionRequest;
import com.oraiopoli.supermarket.dto.response.PromotionResponse;
import com.oraiopoli.supermarket.entity.Promotion;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.PromotionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PromotionService {

    private final PromotionRepository promotionRepository;

    public List<PromotionResponse> getActivePromotions() {
        return promotionRepository.findActivePromotions().stream()
                .map(PromotionResponse::fromEntity)
                .toList();
    }

    public List<PromotionResponse> getAllPromotions() {
        return promotionRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(PromotionResponse::fromEntity)
                .toList();
    }

    public PromotionResponse getPromotionById(Long id) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Promotion", "id", id));
        return PromotionResponse.fromEntity(promotion);
    }

    @Transactional
    public PromotionResponse createPromotion(PromotionRequest request) {
        Promotion promotion = Promotion.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .code(request.getCode())
                .discountPercentage(request.getDiscountPercentage())
                .discountAmount(request.getDiscountAmount())
                .minOrderAmount(request.getMinOrderAmount())
                .imageUrl(request.getImageUrl())
                .active(request.isActive())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .build();

        promotion = promotionRepository.save(promotion);
        return PromotionResponse.fromEntity(promotion);
    }

    @Transactional
    public PromotionResponse updatePromotion(Long id, PromotionRequest request) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Promotion", "id", id));

        promotion.setTitle(request.getTitle());
        promotion.setDescription(request.getDescription());
        promotion.setCode(request.getCode());
        promotion.setDiscountPercentage(request.getDiscountPercentage());
        promotion.setDiscountAmount(request.getDiscountAmount());
        promotion.setMinOrderAmount(request.getMinOrderAmount());
        promotion.setImageUrl(request.getImageUrl());
        promotion.setActive(request.isActive());
        promotion.setStartDate(request.getStartDate());
        promotion.setEndDate(request.getEndDate());

        promotion = promotionRepository.save(promotion);
        return PromotionResponse.fromEntity(promotion);
    }

    /**
     * Validates a promo code and returns the promotion if valid.
     */
    public Promotion validatePromoCode(String code, BigDecimal orderTotal) {
        Promotion promotion = promotionRepository.findByCode(code)
                .orElseThrow(() -> new BadRequestException("Invalid promotion code"));

        if (!promotion.isActive()) {
            throw new BadRequestException("This promotion is no longer active");
        }

        LocalDateTime now = LocalDateTime.now();
        if (promotion.getStartDate() != null && now.isBefore(promotion.getStartDate())) {
            throw new BadRequestException("This promotion has not started yet");
        }
        if (promotion.getEndDate() != null && now.isAfter(promotion.getEndDate())) {
            throw new BadRequestException("This promotion has expired");
        }

        if (promotion.getMinOrderAmount() != null && orderTotal.compareTo(promotion.getMinOrderAmount()) < 0) {
            throw new BadRequestException("Minimum order amount is €" + promotion.getMinOrderAmount().toPlainString());
        }

        return promotion;
    }

    /**
     * Calculates the discount amount for a given promotion and order total.
     */
    public BigDecimal calculateDiscount(Promotion promotion, BigDecimal orderTotal) {
        if (promotion.getDiscountPercentage() != null) {
            return orderTotal.multiply(promotion.getDiscountPercentage())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        }
        if (promotion.getDiscountAmount() != null) {
            // Don't discount more than the total
            return promotion.getDiscountAmount().min(orderTotal);
        }
        return BigDecimal.ZERO;
    }

    @Transactional
    public void deletePromotion(Long id) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Promotion", "id", id));
        promotionRepository.delete(promotion);
    }
}

