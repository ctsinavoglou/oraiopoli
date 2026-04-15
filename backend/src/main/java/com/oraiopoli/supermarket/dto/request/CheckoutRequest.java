package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CheckoutRequest {
    @NotNull(message = "Shipping address ID is required")
    private Long addressId;

    private String notes;

    private String promotionCode;

    private String deliveryTimeSlot;

    private String deliveryMethod; // STANDARD, EXPRESS, PICKUP
}

