package com.voiceiq.backend.speech.repository;

import com.voiceiq.backend.speech.domain.Recording;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RecordingRepository extends JpaRepository<Recording, UUID> {
    Optional<Recording> findBySession_Id(UUID sessionId);
}
