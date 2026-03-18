package com.voiceiq.backend.speech.processor;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.common.exception.BadRequestException;
import com.voiceiq.backend.config.AnalysisQueueProperties;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageDeliveryMode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@ConditionalOnProperty(prefix = "voiceiq.analysis", name = "dispatcher", havingValue = "rabbit", matchIfMissing = true)
public class RabbitAnalysisJobDispatcher implements AnalysisJobDispatcher {

    private static final Logger log = LoggerFactory.getLogger(RabbitAnalysisJobDispatcher.class);

    private final RabbitTemplate rabbitTemplate;
    private final AnalysisQueueProperties analysisQueueProperties;
    private final ObjectMapper objectMapper;

    public RabbitAnalysisJobDispatcher(RabbitTemplate rabbitTemplate, AnalysisQueueProperties analysisQueueProperties) {
        this.rabbitTemplate = rabbitTemplate;
        this.analysisQueueProperties = analysisQueueProperties;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public void dispatch(UUID sessionId) {
        AnalysisJobMessage message = new AnalysisJobMessage(sessionId);
        try {
            String payload = objectMapper.writeValueAsString(message);
            Message amqpMessage = MessageBuilder.withBody(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8))
                    .setContentType("application/json")
                    .setDeliveryMode(MessageDeliveryMode.PERSISTENT)
                    .setHeader("x-analysis-attempt", 1)
                    .build();

            rabbitTemplate.send(
                    analysisQueueProperties.exchange(),
                    analysisQueueProperties.routingKey(),
                    amqpMessage
            );
            log.info("Published analysis job to RabbitMQ for session {}", sessionId);
        } catch (JsonProcessingException exception) {
            throw new BadRequestException("Unable to serialize analysis job");
        }
    }
}
