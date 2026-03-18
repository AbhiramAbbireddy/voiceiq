package com.voiceiq.backend.feedback.domain;

import com.voiceiq.backend.speech.domain.InterviewSession;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "feedback_reports")
public class FeedbackReport {

    @Id
    private UUID id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id")
    private InterviewSession session;

    @Column(name = "overall_score", nullable = false)
    private int overallScore;

    @Column(name = "pace_score", nullable = false)
    private int paceScore;

    @Column(name = "clarity_score", nullable = false)
    private int clarityScore;

    @Column(name = "confidence_score", nullable = false)
    private int confidenceScore;

    @Column(name = "filler_score", nullable = false)
    private int fillerScore;

    @Column(nullable = false, columnDefinition = "text")
    private String summary;

    @Column(nullable = false, columnDefinition = "text")
    private String suggestions;

    @Column(columnDefinition = "text")
    private String strengths;

    @Column(columnDefinition = "text")
    private String weaknesses;

    @Column(name = "better_answer", columnDefinition = "text")
    private String betterAnswer;

    @Column(name = "filler_breakdown", columnDefinition = "text")
    private String fillerBreakdown;

    @Column(name = "hesitation_phrases", columnDefinition = "text")
    private String hesitationPhrases;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public InterviewSession getSession() { return session; }
    public void setSession(InterviewSession session) { this.session = session; }
    public int getOverallScore() { return overallScore; }
    public void setOverallScore(int overallScore) { this.overallScore = overallScore; }
    public int getPaceScore() { return paceScore; }
    public void setPaceScore(int paceScore) { this.paceScore = paceScore; }
    public int getClarityScore() { return clarityScore; }
    public void setClarityScore(int clarityScore) { this.clarityScore = clarityScore; }
    public int getConfidenceScore() { return confidenceScore; }
    public void setConfidenceScore(int confidenceScore) { this.confidenceScore = confidenceScore; }
    public int getFillerScore() { return fillerScore; }
    public void setFillerScore(int fillerScore) { this.fillerScore = fillerScore; }
    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }
    public String getSuggestions() { return suggestions; }
    public void setSuggestions(String suggestions) { this.suggestions = suggestions; }
    public String getStrengths() { return strengths; }
    public void setStrengths(String strengths) { this.strengths = strengths; }
    public String getWeaknesses() { return weaknesses; }
    public void setWeaknesses(String weaknesses) { this.weaknesses = weaknesses; }
    public String getBetterAnswer() { return betterAnswer; }
    public void setBetterAnswer(String betterAnswer) { this.betterAnswer = betterAnswer; }
    public String getFillerBreakdown() { return fillerBreakdown; }
    public void setFillerBreakdown(String fillerBreakdown) { this.fillerBreakdown = fillerBreakdown; }
    public String getHesitationPhrases() { return hesitationPhrases; }
    public void setHesitationPhrases(String hesitationPhrases) { this.hesitationPhrases = hesitationPhrases; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
