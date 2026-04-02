package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.response.DashboardResponse;
import com.oraiopoli.supermarket.dto.response.OrderResponse;
import com.oraiopoli.supermarket.entity.OrderStatus;
import com.oraiopoli.supermarket.entity.Role;
import com.oraiopoli.supermarket.repository.OrderRepository;
import com.oraiopoli.supermarket.repository.ProductRepository;
import com.oraiopoli.supermarket.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardService {

    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;

    public DashboardResponse getDashboardStats() {
        List<OrderResponse> latestOrders = orderRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, 10))
                .map(OrderResponse::fromEntity)
                .getContent();

        return DashboardResponse.builder()
                .totalUsers(userRepository.countByRole(Role.CUSTOMER))
                .totalProducts(productRepository.countByActiveTrue())
                .lowStockProducts(productRepository.countLowStockProducts())
                .pendingOrders(orderRepository.countByStatus(OrderStatus.PENDING))
                .completedOrders(orderRepository.countByStatus(OrderStatus.COMPLETED))
                .cancelledOrders(orderRepository.countByStatus(OrderStatus.CANCELLED))
                .totalRevenue(orderRepository.getTotalRevenue())
                .latestOrders(latestOrders)
                .build();
    }
}

