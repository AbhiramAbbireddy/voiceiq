package com.voiceiq.backend.subscription.repository;

import com.voiceiq.backend.subscription.domain.UsageCounter;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface UsageCounterRepository extends JpaRepository<UsageCounter, UUID> {
    Optional<UsageCounter> findByUser_IdAndPeriodStartAndPeriodEnd(UUID userId, LocalDateTime periodStart, LocalDateTime periodEnd);
}
