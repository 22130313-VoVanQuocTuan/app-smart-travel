package com.example.smart_travel_BE.dto.chat;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatSuggestion {
	private Long id;
	private String type;
	private String name;
	private String description;
	private String image;
	private Double rating;
	private String detailUrl;
	private Double latitude;
	private Double longitude;
}

