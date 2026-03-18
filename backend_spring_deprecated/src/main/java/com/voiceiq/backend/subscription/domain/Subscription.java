package com.voiceiq.backend.subscription.domain;

import com.voiceiq.backend.auth.domain.PlanType;
import com.voiceiq.backend.auth.domain.User;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "subscriptions")
public class Subscription {

    @Id
    private UUID id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlanType plan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubscriptionProvider provider;

    @Column(name = "external_subscription_id")
    private String externalSubscriptionId;

    @Column(name = "current_period_start", nullable = false)
    private LocalDateTime currentPeriodStart;

    @Column(name = "current_period_end", nullable = false)
    private LocalDateTime currentPeriodEnd;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public PlanType getPlan() { return plan; }
    public void setPlan(PlanType plan) { this.plan = plan; }
    public SubscriptionStatus getStatus() { return status; }
    public void setStatus(SubscriptionStatus status) { this.status = status; }
    public SubscriptionProvider getProvider() { return provider; }
    public void setProvider(SubscriptionProvider provider) { this.provider = provider; }
    public String getExternalSubscriptionId() { return externalSubscriptionId; }
    public void setExternalSubscriptionId(String externalSubscriptionId) { this.externalSubscriptionId = externalSubscriptionId; }
    public LocalDateTime getCurrentPeriodStart() { return currentPeriodStart; }
    public void setCurrentPeriodStart(LocalDateTime currentPeriodStart) { this.currentPeriodStart = currentPeriodStart; }
    public LocalDateTime getCurrentPeriodEnd() { return currentPeriodEnd; }
    public void setCurrentPeriodEnd(LocalDateTime currentPeriodEnd) { this.currentPeriodEnd = currentPeriodEnd; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
