package com.oraiopoli.supermarket.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "order_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(name = "product_name", nullable = false)
    private String productName;

    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "paid_quantity", columnDefinition = "int default 0")
    @Builder.Default
    private int paidQuantity = 0;

    @Column(name = "free_quantity", columnDefinition = "int default 0")
    @Builder.Default
    private int freeQuantity = 0;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal subtotal;
}

