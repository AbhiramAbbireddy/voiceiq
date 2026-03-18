package com.voiceiq.backend.progress.repository;

import com.voiceiq.backend.progress.domain.ProgressScore;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProgressScoreRepository extends JpaRepository<ProgressScore, UUID> {
    List<ProgressScore> findTop30ByUser_IdOrderByCreatedAtDesc(UUID userId);
    Optional<ProgressScore> findBySession_Id(UUID sessionId);
}
