package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class StoreSettingsRequest {
    @NotBlank(message = "Key is required")
    private String key;

    private String value;
    private String description;
}

