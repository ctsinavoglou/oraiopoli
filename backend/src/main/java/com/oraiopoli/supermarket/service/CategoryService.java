package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.CategoryRequest;
import com.oraiopoli.supermarket.dto.response.CategoryResponse;
import com.oraiopoli.supermarket.entity.Category;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public List<CategoryResponse> getActiveCategories() {
        return categoryRepository.findByParentIsNullAndActiveTrueOrderByDisplayOrderAsc()
                .stream()
                .map(CategoryResponse::fromEntity)
                .toList();
    }

    public List<CategoryResponse> getAllCategories() {
        return categoryRepository.findAll().stream()
                .map(CategoryResponse::fromEntityFlat)
                .toList();
    }

    public Page<CategoryResponse> getAllCategoriesPaged(String search, Pageable pageable) {
        Page<Category> page;
        if (search != null && !search.isBlank()) {
            page = categoryRepository.searchByName(search, pageable);
        } else {
            page = categoryRepository.findAll(pageable);
        }
        return page.map(CategoryResponse::fromEntityFlat);
    }

    public CategoryResponse getCategoryById(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", id));
        return CategoryResponse.fromEntity(category);
    }

    public CategoryResponse getCategoryBySlug(String slug) {
        Category category = categoryRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "slug", slug));
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public CategoryResponse createCategory(CategoryRequest request) {
        String slug = generateSlug(request.getName());

        Category category = Category.builder()
                .name(request.getName())
                .slug(slug)
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .displayOrder(request.getDisplayOrder())
                .active(request.isActive())
                .build();

        if (request.getParentId() != null) {
            Category parent = categoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent category", "id", request.getParentId()));
            category.setParent(parent);
        }

        category = categoryRepository.save(category);
        return CategoryResponse.fromEntityFlat(category);
    }

    @Transactional
    public CategoryResponse updateCategory(Long id, CategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", id));

        category.setName(request.getName());
        category.setDescription(request.getDescription());
        category.setImageUrl(request.getImageUrl());
        category.setDisplayOrder(request.getDisplayOrder());
        category.setActive(request.isActive());

        if (request.getParentId() != null) {
            Category parent = categoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parent category", "id", request.getParentId()));
            category.setParent(parent);
        } else {
            category.setParent(null);
        }

        category = categoryRepository.save(category);
        return CategoryResponse.fromEntityFlat(category);
    }

    @Transactional
    public void deleteCategory(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", id));
        categoryRepository.delete(category);
    }

    private String generateSlug(String name) {
        String transliterated = transliterateGreek(name.toLowerCase());
        String slug = transliterated
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-")
                .replaceAll("^-|-$", "")
                .trim();

        if (slug.isEmpty()) {
            slug = "category";
        }

        // If slug already exists, append a counter
        String baseSlug = slug;
        int counter = 1;
        while (categoryRepository.existsBySlug(slug)) {
            slug = baseSlug + "-" + counter;
            counter++;
        }

        return slug;
    }

    private static final Map<String, String> GREEK_MAP = new LinkedHashMap<>();

    static {
        // Multi-char combinations first (order matters)
        GREEK_MAP.put("μπ", "mp");
        GREEK_MAP.put("ντ", "nt");
        GREEK_MAP.put("γκ", "gk");
        GREEK_MAP.put("γγ", "ng");
        GREEK_MAP.put("γχ", "nch");
        GREEK_MAP.put("γξ", "nx");
        GREEK_MAP.put("τσ", "ts");
        GREEK_MAP.put("τζ", "tz");
        GREEK_MAP.put("ου", "ou");
        GREEK_MAP.put("αι", "ai");
        GREEK_MAP.put("ει", "ei");
        GREEK_MAP.put("οι", "oi");
        GREEK_MAP.put("υι", "yi");
        GREEK_MAP.put("αυ", "av");
        GREEK_MAP.put("ευ", "ev");

        // Single characters (with accents)
        GREEK_MAP.put("ά", "a");
        GREEK_MAP.put("έ", "e");
        GREEK_MAP.put("ή", "i");
        GREEK_MAP.put("ί", "i");
        GREEK_MAP.put("ό", "o");
        GREEK_MAP.put("ύ", "y");
        GREEK_MAP.put("ώ", "o");
        GREEK_MAP.put("ϊ", "i");
        GREEK_MAP.put("ΐ", "i");
        GREEK_MAP.put("ϋ", "y");
        GREEK_MAP.put("ΰ", "y");

        // Base Greek letters
        GREEK_MAP.put("α", "a");
        GREEK_MAP.put("β", "v");
        GREEK_MAP.put("γ", "g");
        GREEK_MAP.put("δ", "d");
        GREEK_MAP.put("ε", "e");
        GREEK_MAP.put("ζ", "z");
        GREEK_MAP.put("η", "i");
        GREEK_MAP.put("θ", "th");
        GREEK_MAP.put("ι", "i");
        GREEK_MAP.put("κ", "k");
        GREEK_MAP.put("λ", "l");
        GREEK_MAP.put("μ", "m");
        GREEK_MAP.put("ν", "n");
        GREEK_MAP.put("ξ", "x");
        GREEK_MAP.put("ο", "o");
        GREEK_MAP.put("π", "p");
        GREEK_MAP.put("ρ", "r");
        GREEK_MAP.put("σ", "s");
        GREEK_MAP.put("ς", "s");
        GREEK_MAP.put("τ", "t");
        GREEK_MAP.put("υ", "y");
        GREEK_MAP.put("φ", "f");
        GREEK_MAP.put("χ", "ch");
        GREEK_MAP.put("ψ", "ps");
        GREEK_MAP.put("ω", "o");
    }

    private String transliterateGreek(String text) {
        String result = text;
        for (Map.Entry<String, String> entry : GREEK_MAP.entrySet()) {
            result = result.replace(entry.getKey(), entry.getValue());
        }
        return result;
    }
}

