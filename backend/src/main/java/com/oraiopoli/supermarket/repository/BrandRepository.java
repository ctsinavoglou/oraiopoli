package com.oraiopoli.supermarket.repository;

import com.oraiopoli.supermarket.entity.Brand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BrandRepository extends JpaRepository<Brand, Long> {
    Optional<Brand> findBySlug(String slug);
    boolean existsBySlug(String slug);
    List<Brand> findByActiveTrue();
}

