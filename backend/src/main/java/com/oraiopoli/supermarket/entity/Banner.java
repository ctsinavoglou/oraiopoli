package com.oraiopoli.supermarket.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "banners", indexes = {
        @Index(name = "idx_banner_active", columnList = "active"),
        @Index(name = "idx_banner_order", columnList = "display_order")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Banner extends BaseEntity {

    @Column(nullable = false)
    private String title;

    private String subtitle;

    @Column(name = "image_url", nullable = false)
    private String imageUrl;

    @Column(name = "link_url")
    private String linkUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "link_type")
    @Builder.Default
    private LinkType linkType = LinkType.NONE;

    @Column(name = "content_body", columnDefinition = "TEXT")
    private String contentBody;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "banner_products",
            joinColumns = @JoinColumn(name = "banner_id"),
            inverseJoinColumns = @JoinColumn(name = "product_id")
    )
    @Builder.Default
    private List<Product> products = new ArrayList<>();

    @Column(name = "display_order")
    @Builder.Default
    private int displayOrder = 0;

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "end_date")
    private LocalDateTime endDate;
}

