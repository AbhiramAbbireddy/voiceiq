package com.voiceiq.backend.speech.domain;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "transcripts")
public class Transcript {

    @Id
    private UUID id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id")
    private InterviewSession session;

    @Column(name = "transcript_text", nullable = false, columnDefinition = "text")
    private String transcriptText;

    @Column(name = "filler_count", nullable = false)
    private int fillerCount;

    @Column(name = "words_per_minute", nullable = false)
    private int wordsPerMinute;

    @Column(name = "highlights_json", columnDefinition = "text")
    private String highlightsJson;

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
    public String getTranscriptText() { return transcriptText; }
    public void setTranscriptText(String transcriptText) { this.transcriptText = transcriptText; }
    public int getFillerCount() { return fillerCount; }
    public void setFillerCount(int fillerCount) { this.fillerCount = fillerCount; }
    public int getWordsPerMinute() { return wordsPerMinute; }
    public void setWordsPerMinute(int wordsPerMinute) { this.wordsPerMinute = wordsPerMinute; }
    public String getHighlightsJson() { return highlightsJson; }
    public void setHighlightsJson(String highlightsJson) { this.highlightsJson = highlightsJson; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
