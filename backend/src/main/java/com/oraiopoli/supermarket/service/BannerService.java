package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.BannerRequest;
import com.oraiopoli.supermarket.dto.response.BannerResponse;
import com.oraiopoli.supermarket.entity.Banner;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.BannerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BannerService {

    private final BannerRepository bannerRepository;

    public List<BannerResponse> getActiveBanners() {
        return bannerRepository.findActiveBanners().stream()
                .map(BannerResponse::fromEntity)
                .toList();
    }

    public List<BannerResponse> getAllBanners() {
        return bannerRepository.findAllByOrderByDisplayOrderAsc().stream()
                .map(BannerResponse::fromEntity)
                .toList();
    }

    public BannerResponse getBannerById(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Banner", "id", id));
        return BannerResponse.fromEntity(banner);
    }

    @Transactional
    public BannerResponse createBanner(BannerRequest request) {
        Banner banner = Banner.builder()
                .title(request.getTitle())
                .subtitle(request.getSubtitle())
                .imageUrl(request.getImageUrl())
                .linkUrl(request.getLinkUrl())
                .displayOrder(request.getDisplayOrder())
                .active(request.isActive())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .build();

        banner = bannerRepository.save(banner);
        return BannerResponse.fromEntity(banner);
    }

    @Transactional
    public BannerResponse updateBanner(Long id, BannerRequest request) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Banner", "id", id));

        banner.setTitle(request.getTitle());
        banner.setSubtitle(request.getSubtitle());
        banner.setImageUrl(request.getImageUrl());
        banner.setLinkUrl(request.getLinkUrl());
        banner.setDisplayOrder(request.getDisplayOrder());
        banner.setActive(request.isActive());
        banner.setStartDate(request.getStartDate());
        banner.setEndDate(request.getEndDate());

        banner = bannerRepository.save(banner);
        return BannerResponse.fromEntity(banner);
    }

    @Transactional
    public void deleteBanner(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Banner", "id", id));
        bannerRepository.delete(banner);
    }
}

