package com.voiceiq.backend.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.amqp.support.converter.SimpleMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;

@Configuration
@EnableRabbit
public class RabbitAnalysisConfig {

    private final AnalysisQueueProperties analysisQueueProperties;

    public RabbitAnalysisConfig(AnalysisQueueProperties analysisQueueProperties) {
        this.analysisQueueProperties = analysisQueueProperties;
    }

    @Bean
    public DirectExchange analysisExchange() {
        return new DirectExchange(analysisQueueProperties.exchange(), true, false);
    }

    @Bean
    public Queue analysisQueue() {
        return new Queue(
                analysisQueueProperties.queue(),
                true,
                false,
                false,
                Map.of(
                        "x-dead-letter-exchange", analysisQueueProperties.exchange(),
                        "x-dead-letter-routing-key", analysisQueueProperties.deadLetterRoutingKey()
                )
        );
    }

    @Bean
    public Queue analysisRetryQueue() {
        return new Queue(
                analysisQueueProperties.retryQueue(),
                true,
                false,
                false,
                Map.of(
                        "x-message-ttl", retryDelayMs(),
                        "x-dead-letter-exchange", analysisQueueProperties.exchange(),
                        "x-dead-letter-routing-key", analysisQueueProperties.routingKey()
                )
        );
    }

    @Bean
    public Queue analysisDeadLetterQueue() {
        return new Queue(analysisQueueProperties.deadLetterQueue(), true);
    }

    @Bean
    public Binding analysisBinding(Queue analysisQueue, DirectExchange analysisExchange) {
        return BindingBuilder.bind(analysisQueue)
                .to(analysisExchange)
                .with(analysisQueueProperties.routingKey());
    }

    @Bean
    public Binding analysisRetryBinding(Queue analysisRetryQueue, DirectExchange analysisExchange) {
        return BindingBuilder.bind(analysisRetryQueue)
                .to(analysisExchange)
                .with(analysisQueueProperties.retryRoutingKey());
    }

    @Bean
    public Binding analysisDeadLetterBinding(Queue analysisDeadLetterQueue, DirectExchange analysisExchange) {
        return BindingBuilder.bind(analysisDeadLetterQueue)
                .to(analysisExchange)
                .with(analysisQueueProperties.deadLetterRoutingKey());
    }

    @Bean
    public MessageConverter messageConverter() {
        return new SimpleMessageConverter();
    }

    private int retryDelayMs() {
        return analysisQueueProperties.retryDelayMs() == null || analysisQueueProperties.retryDelayMs() <= 0
                ? 10000
                : analysisQueueProperties.retryDelayMs();
    }
}
