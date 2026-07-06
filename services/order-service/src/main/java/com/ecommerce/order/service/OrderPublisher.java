package com.ecommerce.order.service;
import com.google.cloud.spring.pubsub.core.PubSubTemplate;
import com.ecommerce.order.model.Order;
import org.springframework.stereotype.Service;

@Service
public class OrderPublisher {
    private final PubSubTemplate pubSubTemplate;
    private static final String TOPIC = "order-events";

    public OrderPublisher(PubSubTemplate pubSubTemplate) {
        this.pubSubTemplate = pubSubTemplate;
    }

    public void publishOrderPlaced(Order order) {
        String message = String.format(
            "{\"orderId\":%d,\"customerEmail\":\"%s\",\"productId\":%d,\"quantity\":%d,\"status\":\"%s\"}",
            order.getId(), order.getCustomerEmail(), order.getProductId(), order.getQuantity(), order.getStatus()
        );
        pubSubTemplate.publish(TOPIC, message);
    }
}