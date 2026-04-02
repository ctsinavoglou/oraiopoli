package com.oraiopoli.supermarket.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CategoryRequest {
    @NotBlank(message = "Name is required")
    private String name;

    private String description;
    private String imageUrl;
    private int displayOrder;
    private boolean active = true;
    private Long parentId;
}

