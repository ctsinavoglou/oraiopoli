package com.oraiopoli.supermarket.dto.request;

import com.oraiopoli.supermarket.entity.LinkType;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class BannerRequest {
    @NotBlank(message = "Title is required")
    private String title;

    private String subtitle;

    @NotBlank(message = "Image URL is required")
    private String imageUrl;

    private String linkUrl;
    private LinkType linkType = LinkType.NONE;
    private String contentBody;
    private List<Long> productIds;
    private int displayOrder;
    private boolean active = true;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
}

