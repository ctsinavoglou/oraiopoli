package com.oraiopoli.supermarket.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "inventory", indexes = {
        @Index(name = "idx_inventory_quantity", columnList = "quantity")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Inventory extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false, unique = true)
    private Product product;

    @Column(nullable = false)
    @Builder.Default
    private int quantity = 0;

    @Column(name = "low_stock_threshold")
    @Builder.Default
    private int lowStockThreshold = 10;

    public boolean isInStock() {
        return quantity > 0;
    }

    public boolean isLowStock() {
        return quantity > 0 && quantity <= lowStockThreshold;
    }
}

