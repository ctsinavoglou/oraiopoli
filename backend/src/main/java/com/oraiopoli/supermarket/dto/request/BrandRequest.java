package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class BrandRequest {
    @NotBlank(message = "Name is required")
    private String name;

    private String logoUrl;
    private String description;
    private boolean active = true;
}

