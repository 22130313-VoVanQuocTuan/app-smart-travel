package com.example.smart_travel_BE.dto.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatAskResponse {
	private String message;

	@Builder.Default
	private List<ChatSuggestion> suggestions = new ArrayList<>();

	private Long timestamp;
}

