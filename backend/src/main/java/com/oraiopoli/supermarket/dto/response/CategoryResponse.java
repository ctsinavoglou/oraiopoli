package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Category;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryResponse {
    private Long id;
    private String name;
    private String slug;
    private String description;
    private String imageUrl;
    private int displayOrder;
    private boolean active;
    private Long parentId;
    private List<CategoryResponse> children;

    public static CategoryResponse fromEntity(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .slug(category.getSlug())
                .description(category.getDescription())
                .imageUrl(category.getImageUrl())
                .displayOrder(category.getDisplayOrder())
                .active(category.isActive())
                .parentId(category.getParent() != null ? category.getParent().getId() : null)
                .children(category.getChildren() != null
                        ? category.getChildren().stream().map(CategoryResponse::fromEntity).toList()
                        : null)
                .build();
    }

    public static CategoryResponse fromEntityFlat(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .slug(category.getSlug())
                .description(category.getDescription())
                .imageUrl(category.getImageUrl())
                .displayOrder(category.getDisplayOrder())
                .active(category.isActive())
                .parentId(category.getParent() != null ? category.getParent().getId() : null)
                .build();
    }
}

