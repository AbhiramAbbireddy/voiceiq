package com.voiceiq.backend.speech.repository;

import com.voiceiq.backend.speech.domain.Transcript;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface TranscriptRepository extends JpaRepository<Transcript, UUID> {
    Optional<Transcript> findBySession_Id(UUID sessionId);
}
