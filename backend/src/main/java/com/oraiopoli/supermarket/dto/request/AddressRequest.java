package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddressRequest {
    @NotBlank(message = "Label is required")
    private String label;

    @NotBlank(message = "Address line is required")
    private String addressLine;

    private String city;
    private String postalCode;
    private String country;
    private boolean isDefault;
}

