package com.example.smart_travel_BE.controller;

import com.example.smart_travel_BE.dto.chat.ChatAskRequest;
import com.example.smart_travel_BE.dto.chat.ChatAskResponse;
import com.example.smart_travel_BE.dto.user.response.APIResponse;
import com.example.smart_travel_BE.service.ChatAIService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatAIService chatAIService;

    @PostMapping("/ask")
    public ResponseEntity<APIResponse<ChatAskResponse>> ask(@Valid @RequestBody ChatAskRequest request) {
        return ResponseEntity.status(HttpStatus.OK).body(
                APIResponse.<ChatAskResponse>builder()
                        .data(chatAIService.askAI(request))
                        .build()
        );
    }
}
