package com.voiceiq.backend.progress.domain;

import com.voiceiq.backend.auth.domain.User;
import com.voiceiq.backend.speech.domain.InterviewSession;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "progress_scores")
public class ProgressScore {

    @Id
    private UUID id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id")
    private InterviewSession session;

    @Column(name = "overall_score", nullable = false)
    private int overallScore;

    @Column(name = "improvement_delta", nullable = false)
    private int improvementDelta;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public InterviewSession getSession() { return session; }
    public void setSession(InterviewSession session) { this.session = session; }
    public int getOverallScore() { return overallScore; }
    public void setOverallScore(int overallScore) { this.overallScore = overallScore; }
    public int getImprovementDelta() { return improvementDelta; }
    public void setImprovementDelta(int improvementDelta) { this.improvementDelta = improvementDelta; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
