package com.oraiopoli.supermarket.repository;

import com.oraiopoli.supermarket.entity.Promotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Long> {
    Optional<Promotion> findByCode(String code);

    @Query("SELECT p FROM Promotion p WHERE p.active = true AND " +
            "(p.startDate IS NULL OR p.startDate <= CURRENT_TIMESTAMP) AND " +
            "(p.endDate IS NULL OR p.endDate >= CURRENT_TIMESTAMP)")
    List<Promotion> findActivePromotions();

    List<Promotion> findAllByOrderByCreatedAtDesc();
}

