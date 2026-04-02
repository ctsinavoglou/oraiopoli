package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Banner;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BannerResponse {
    private Long id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String linkUrl;
    private int displayOrder;
    private boolean active;
    private LocalDateTime startDate;
    private LocalDateTime endDate;

    public static BannerResponse fromEntity(Banner banner) {
        return BannerResponse.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .subtitle(banner.getSubtitle())
                .imageUrl(banner.getImageUrl())
                .linkUrl(banner.getLinkUrl())
                .displayOrder(banner.getDisplayOrder())
                .active(banner.isActive())
                .startDate(banner.getStartDate())
                .endDate(banner.getEndDate())
                .build();
    }
}

