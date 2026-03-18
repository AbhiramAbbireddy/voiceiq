package com.voiceiq.backend.speech.controller;

import com.voiceiq.backend.common.api.ApiResponse;
import com.voiceiq.backend.auth.security.CurrentUserService;
import com.voiceiq.backend.speech.dto.CompleteUploadRequest;
import com.voiceiq.backend.speech.dto.CreateSessionRequest;
import com.voiceiq.backend.speech.dto.InitiateUploadRequest;
import com.voiceiq.backend.speech.dto.InitiateUploadResponse;
import com.voiceiq.backend.speech.dto.RecordingUploadResponse;
import com.voiceiq.backend.speech.dto.SessionResponse;
import com.voiceiq.backend.speech.dto.SessionStatusResponse;
import com.voiceiq.backend.speech.service.SpeechSessionService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/speech")
public class SpeechController {

    private final SpeechSessionService speechSessionService;
    private final CurrentUserService currentUserService;

    public SpeechController(SpeechSessionService speechSessionService, CurrentUserService currentUserService) {
        this.speechSessionService = speechSessionService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/sessions")
    public ApiResponse<SessionResponse> createSession(@Valid @RequestBody CreateSessionRequest request) {
        return ApiResponse.success(
                speechSessionService.createSession(currentUserService.requireCurrentUser(), request),
                "Session created successfully"
        );
    }

    @PostMapping("/sessions/{sessionId}/initiate-upload")
    public ApiResponse<InitiateUploadResponse> initiateUpload(
            @PathVariable UUID sessionId,
            @Valid @RequestBody InitiateUploadRequest request
    ) {
        return ApiResponse.success(
                speechSessionService.initiateUpload(sessionId, request),
                "Upload initiated successfully"
        );
    }

    @PostMapping("/sessions/{sessionId}/complete-upload")
    public ApiResponse<RecordingUploadResponse> completeUpload(
            @PathVariable UUID sessionId,
            @Valid @RequestBody CompleteUploadRequest request
    ) {
        return ApiResponse.success(
                speechSessionService.completeUpload(sessionId, request),
                "Upload completed successfully"
        );
    }

    @PostMapping(value = "/sessions/{sessionId}/recording", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<RecordingUploadResponse> uploadRecording(
            @PathVariable UUID sessionId,
            @RequestPart("file") MultipartFile file,
            @RequestParam(required = false) Integer durationSeconds,
            @RequestParam(required = false) String mimeType
    ) {
        return ApiResponse.success(
                speechSessionService.uploadRecording(sessionId, file, durationSeconds, mimeType),
                "Recording uploaded successfully"
        );
    }

    @GetMapping("/sessions/{sessionId}")
    public ApiResponse<SessionResponse> getSession(@PathVariable UUID sessionId) {
        return ApiResponse.success(speechSessionService.getSession(sessionId), "Session fetched successfully");
    }

    @GetMapping("/sessions/{sessionId}/status")
    public ApiResponse<SessionStatusResponse> getSessionStatus(@PathVariable UUID sessionId) {
        return ApiResponse.success(speechSessionService.getSessionStatus(sessionId), "Session status fetched successfully");
    }

    @GetMapping("/sessions/user/{userId}")
    public ApiResponse<List<SessionResponse>> getUserSessions(@PathVariable UUID userId) {
        return ApiResponse.success(speechSessionService.getUserSessions(userId), "User sessions fetched successfully");
    }
}
