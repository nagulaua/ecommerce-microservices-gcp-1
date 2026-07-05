package com.ecommerce.notification.listener;
import org.springframework.stereotype.Component;

import com.google.cloud.spring.pubsub.core.PubSubTemplate;

import jakarta.annotation.PostConstruct;

@Component
public class OrderEventListener {
    private final PubSubTemplate pubSubTemplate;
    private static final String SUBSCRIPTION = "order-events-sub";

    public OrderEventListener(PubSubTemplate pubSubTemplate) {
        this.pubSubTemplate = pubSubTemplate;
    }

    @PostConstruct
    public void subscribe() {
        pubSubTemplate.subscribe(SUBSCRIPTION, message -> {
            String payload = message.getPubsubMessage().getData().toStringUtf8();
            System.out.println("Received order event: " + payload);
            // In a real system: send an email/SMS, or write a record to Cloud Storage here.
            message.ack();
        });
    }
}