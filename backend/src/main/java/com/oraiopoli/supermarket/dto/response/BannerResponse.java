package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Banner;
import com.oraiopoli.supermarket.entity.LinkType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

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
    private LinkType linkType;
    private String contentBody;
    private List<Long> productIds;
    private List<ProductResponse> products;
    private int displayOrder;
    private boolean active;
    private LocalDateTime startDate;
    private LocalDateTime endDate;

    /** Lightweight — no products loaded (for list endpoints). */
    public static BannerResponse fromEntity(Banner banner) {
        List<Long> pIds = null;
        try {
            pIds = banner.getProducts() != null
                    ? banner.getProducts().stream().map(p -> p.getId()).toList()
                    : null;
        } catch (Exception ignored) {
            // lazy-load not initialised – that's fine for list calls
        }

        return BannerResponse.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .subtitle(banner.getSubtitle())
                .imageUrl(banner.getImageUrl())
                .linkUrl(banner.getLinkUrl())
                .linkType(banner.getLinkType())
                .contentBody(banner.getContentBody())
                .productIds(pIds)
                .displayOrder(banner.getDisplayOrder())
                .active(banner.isActive())
                .startDate(banner.getStartDate())
                .endDate(banner.getEndDate())
                .build();
    }

    /** Full — includes resolved product list (for detail endpoint). */
    public static BannerResponse fromEntityWithProducts(Banner banner) {
        List<Long> pIds = banner.getProducts() != null
                ? banner.getProducts().stream().map(p -> p.getId()).toList()
                : List.of();

        List<ProductResponse> prods = banner.getProducts() != null
                ? banner.getProducts().stream().map(ProductResponse::fromEntity).toList()
                : List.of();

        return BannerResponse.builder()
                .id(banner.getId())
                .title(banner.getTitle())
                .subtitle(banner.getSubtitle())
                .imageUrl(banner.getImageUrl())
                .linkUrl(banner.getLinkUrl())
                .linkType(banner.getLinkType())
                .contentBody(banner.getContentBody())
                .productIds(pIds)
                .products(prods)
                .displayOrder(banner.getDisplayOrder())
                .active(banner.isActive())
                .startDate(banner.getStartDate())
                .endDate(banner.getEndDate())
                .build();
    }
}

