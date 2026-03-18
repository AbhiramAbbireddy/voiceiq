package com.voiceiq.backend.feedback.repository;

import com.voiceiq.backend.feedback.domain.FeedbackReport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FeedbackReportRepository extends JpaRepository<FeedbackReport, UUID> {
    Optional<FeedbackReport> findBySession_Id(UUID sessionId);
}
