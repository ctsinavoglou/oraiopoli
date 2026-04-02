package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.BrandRequest;
import com.oraiopoli.supermarket.dto.response.BrandResponse;
import com.oraiopoli.supermarket.entity.Brand;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.BrandRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BrandService {

    private final BrandRepository brandRepository;

    public List<BrandResponse> getActiveBrands() {
        return brandRepository.findByActiveTrue().stream()
                .map(BrandResponse::fromEntity)
                .toList();
    }

    public List<BrandResponse> getAllBrands() {
        return brandRepository.findAll().stream()
                .map(BrandResponse::fromEntity)
                .toList();
    }

    public BrandResponse getBrandById(Long id) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Brand", "id", id));
        return BrandResponse.fromEntity(brand);
    }

    @Transactional
    public BrandResponse createBrand(BrandRequest request) {
        String slug = generateSlug(request.getName());
        if (brandRepository.existsBySlug(slug)) {
            throw new BadRequestException("Brand with similar name already exists");
        }

        Brand brand = Brand.builder()
                .name(request.getName())
                .slug(slug)
                .logoUrl(request.getLogoUrl())
                .description(request.getDescription())
                .active(request.isActive())
                .build();

        brand = brandRepository.save(brand);
        return BrandResponse.fromEntity(brand);
    }

    @Transactional
    public BrandResponse updateBrand(Long id, BrandRequest request) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Brand", "id", id));

        brand.setName(request.getName());
        brand.setLogoUrl(request.getLogoUrl());
        brand.setDescription(request.getDescription());
        brand.setActive(request.isActive());

        brand = brandRepository.save(brand);
        return BrandResponse.fromEntity(brand);
    }

    @Transactional
    public void deleteBrand(Long id) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Brand", "id", id));
        brandRepository.delete(brand);
    }

    private String generateSlug(String name) {
        return name.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-")
                .trim();
    }
}

