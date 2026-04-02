package com.oraiopoli.supermarket.repository;

import com.oraiopoli.supermarket.entity.Order;
import com.oraiopoli.supermarket.entity.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    Page<Order> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
    Optional<Order> findByOrderNumber(String orderNumber);
    Optional<Order> findByIdAndUserId(Long id, Long userId);
    long countByStatus(OrderStatus status);

    @Query("SELECT COALESCE(SUM(o.totalAmount), 0) FROM Order o WHERE o.status = 'COMPLETED'")
    BigDecimal getTotalRevenue();

    @Query("SELECT o FROM Order o WHERE o.status = :status AND o.orderNumber LIKE CONCAT('%', CAST(:search AS string), '%') ORDER BY o.createdAt DESC")
    Page<Order> findByStatusAndSearch(@Param("status") OrderStatus status,
                                      @Param("search") String search,
                                      Pageable pageable);

    @Query("SELECT o FROM Order o WHERE o.status = :status ORDER BY o.createdAt DESC")
    Page<Order> findByStatusOnly(@Param("status") OrderStatus status, Pageable pageable);

    @Query("SELECT o FROM Order o WHERE o.orderNumber LIKE CONCAT('%', CAST(:search AS string), '%') ORDER BY o.createdAt DESC")
    Page<Order> findBySearchOnly(@Param("search") String search, Pageable pageable);

    Page<Order> findAllByOrderByCreatedAtDesc(Pageable pageable);
}

