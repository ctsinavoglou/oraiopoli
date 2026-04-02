package com.oraiopoli.supermarket.repository;

import com.oraiopoli.supermarket.entity.Banner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BannerRepository extends JpaRepository<Banner, Long> {
    @Query("SELECT b FROM Banner b WHERE b.active = true AND " +
            "(b.startDate IS NULL OR b.startDate <= CURRENT_TIMESTAMP) AND " +
            "(b.endDate IS NULL OR b.endDate >= CURRENT_TIMESTAMP) " +
            "ORDER BY b.displayOrder ASC")
    List<Banner> findActiveBanners();

    List<Banner> findAllByOrderByDisplayOrderAsc();
}

