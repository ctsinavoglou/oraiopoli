package com.oraiopoli.supermarket.repository;

import com.oraiopoli.supermarket.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
    Optional<Product> findBySlug(String slug);
    Optional<Product> findBySku(String sku);
    boolean existsBySlug(String slug);
    boolean existsBySku(String sku);

    Page<Product> findByActiveTrueAndFeaturedTrue(Pageable pageable);
    @Query("SELECT p FROM Product p WHERE p.active = true " +
            "ORDER BY " +
            "CASE WHEN p.buyQuantity IS NOT NULL AND p.getQuantity IS NOT NULL " +
            "AND (p.discountStartDate IS NULL OR p.discountStartDate <= CURRENT_TIMESTAMP) " +
            "AND (p.discountEndDate IS NULL OR p.discountEndDate >= CURRENT_TIMESTAMP) THEN 0 " +
            "WHEN p.discountPrice IS NOT NULL " +
            "AND (p.discountStartDate IS NULL OR p.discountStartDate <= CURRENT_TIMESTAMP) " +
            "AND (p.discountEndDate IS NULL OR p.discountEndDate >= CURRENT_TIMESTAMP) THEN 1 " +
            "ELSE 2 END ASC, " +
            "p.name ASC")
    Page<Product> findByActiveTrueSorted(Pageable pageable);
    Page<Product> findByBrandIdAndActiveTrue(Long brandId, Pageable pageable);

    @Query("SELECT p FROM Product p WHERE p.category.id = :categoryId AND p.active = true " +
            "ORDER BY " +
            "CASE WHEN p.buyQuantity IS NOT NULL AND p.getQuantity IS NOT NULL " +
            "AND (p.discountStartDate IS NULL OR p.discountStartDate <= CURRENT_TIMESTAMP) " +
            "AND (p.discountEndDate IS NULL OR p.discountEndDate >= CURRENT_TIMESTAMP) THEN 0 " +
            "WHEN p.discountPrice IS NOT NULL " +
            "AND (p.discountStartDate IS NULL OR p.discountStartDate <= CURRENT_TIMESTAMP) " +
            "AND (p.discountEndDate IS NULL OR p.discountEndDate >= CURRENT_TIMESTAMP) THEN 1 " +
            "ELSE 2 END ASC, " +
            "p.name ASC")
    Page<Product> findByCategoryIdAndActiveTrue(@Param("categoryId") Long categoryId, Pageable pageable);

    @Query("SELECT p FROM Product p WHERE p.active = true AND " +
            "(LOWER(p.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(p.description) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(p.sku) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Product> searchProducts(@Param("query") String query, Pageable pageable);

    @Query("SELECT p FROM Product p WHERE " +
            "LOWER(p.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(p.sku) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Product> searchAllProducts(@Param("query") String query, Pageable pageable);

    long countByActiveTrue();

    @Query("SELECT p FROM Product p JOIN p.inventory i WHERE i.quantity <= i.lowStockThreshold AND p.active = true")
    List<Product> findLowStockProducts();

    @Query("SELECT COUNT(p) FROM Product p JOIN p.inventory i WHERE i.quantity <= i.lowStockThreshold AND p.active = true")
    long countLowStockProducts();
}

