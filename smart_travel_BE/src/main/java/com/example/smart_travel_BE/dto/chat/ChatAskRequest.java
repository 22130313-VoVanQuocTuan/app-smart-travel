package com.example.smart_travel_BE.dto.chat;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatAskRequest {
	@NotBlank(message = "Prompt không được rỗng")
	private String prompt;
}

