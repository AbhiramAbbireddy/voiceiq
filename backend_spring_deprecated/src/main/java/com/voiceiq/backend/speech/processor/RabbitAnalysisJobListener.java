package com.voiceiq.backend.speech.processor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.voiceiq.backend.config.AnalysisQueueProperties;
import com.voiceiq.backend.speech.domain.SessionStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageDeliveryMode;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Service
@ConditionalOnProperty(prefix = "voiceiq.analysis", name = "dispatcher", havingValue = "rabbit", matchIfMissing = true)
public class RabbitAnalysisJobListener {

    private static final Logger log = LoggerFactory.getLogger(RabbitAnalysisJobListener.class);

    private final AnalysisOrchestrationService analysisOrchestrationService;
    private final AnalysisStatusService analysisStatusService;
    private final AnalysisQueueProperties analysisQueueProperties;
    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    public RabbitAnalysisJobListener(
            AnalysisOrchestrationService analysisOrchestrationService,
            AnalysisStatusService analysisStatusService,
            AnalysisQueueProperties analysisQueueProperties,
            RabbitTemplate rabbitTemplate
    ) {
        this.analysisOrchestrationService = analysisOrchestrationService;
        this.analysisStatusService = analysisStatusService;
        this.analysisQueueProperties = analysisQueueProperties;
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = new ObjectMapper();
    }

    @RabbitListener(queues = "#{analysisQueue.name}")
    public void handle(Message message) {
        String payload = new String(message.getBody(), StandardCharsets.UTF_8);

        try {
            AnalysisJobMessage jobMessage = objectMapper.readValue(payload, AnalysisJobMessage.class);
            int attempt = readAttempt(message);

            log.info("Consumed analysis job from RabbitMQ for session {} on attempt {}", jobMessage.sessionId(), attempt);
            analysisOrchestrationService.processSession(jobMessage.sessionId());
            log.info("RabbitMQ analysis job completed for session {}", jobMessage.sessionId());
        } catch (Exception exception) {
            handleFailure(message, payload, exception);
        }
    }

    private void handleFailure(Message originalMessage, String payload, Exception exception) {
        log.error("RabbitMQ analysis job failed for payload {}", payload, exception);

        try {
            AnalysisJobMessage jobMessage = objectMapper.readValue(payload, AnalysisJobMessage.class);
            int nextAttempt = readAttempt(originalMessage) + 1;

            if (nextAttempt <= maxAttempts()) {
                Message retryMessage = MessageBuilder.withBody(originalMessage.getBody())
                        .setContentType(originalMessage.getMessageProperties().getContentType())
                        .setDeliveryMode(MessageDeliveryMode.PERSISTENT)
                        .setHeader("x-analysis-attempt", nextAttempt)
                        .build();

                rabbitTemplate.send(
                        analysisQueueProperties.exchange(),
                        analysisQueueProperties.retryRoutingKey(),
                        retryMessage
                );
                log.warn("Scheduled retry {} for session {}", nextAttempt, jobMessage.sessionId());
                return;
            }

            analysisStatusService.updateStatus(jobMessage.sessionId(), SessionStatus.FAILED);

            Message deadLetterMessage = MessageBuilder.withBody(originalMessage.getBody())
                    .setContentType(originalMessage.getMessageProperties().getContentType())
                    .setDeliveryMode(MessageDeliveryMode.PERSISTENT)
                    .setHeader("x-analysis-attempt", readAttempt(originalMessage))
                    .setHeader("x-analysis-failure", exception.getClass().getSimpleName())
                    .build();

            rabbitTemplate.send(
                    analysisQueueProperties.exchange(),
                    analysisQueueProperties.deadLetterRoutingKey(),
                    deadLetterMessage
            );
            log.error("Moved analysis job to dead-letter queue for session {}", jobMessage.sessionId());
        } catch (Exception innerException) {
            log.error("Unable to process failed analysis job payload {}", payload, innerException);
        }
    }

    private int readAttempt(Message message) {
        Object attempt = message.getMessageProperties().getHeaders().get("x-analysis-attempt");
        if (attempt instanceof Number number) {
            return number.intValue();
        }
        return 1;
    }

    private int maxAttempts() {
        return analysisQueueProperties.maxAttempts() == null || analysisQueueProperties.maxAttempts() <= 0
                ? 3
                : analysisQueueProperties.maxAttempts();
    }
}
