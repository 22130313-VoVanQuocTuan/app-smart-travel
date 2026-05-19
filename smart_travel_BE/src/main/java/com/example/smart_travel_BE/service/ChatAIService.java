package com.example.smart_travel_BE.service;

import com.example.smart_travel_BE.dto.chat.ChatAskRequest;
import com.example.smart_travel_BE.dto.chat.ChatAskResponse;
import com.example.smart_travel_BE.dto.chat.ChatSuggestion;
import com.example.smart_travel_BE.dto.destination.response.DestinationDetailResponse;
import com.example.smart_travel_BE.dto.homestay.response.HomestayResponse;
import com.example.smart_travel_BE.entity.Destination;
import com.example.smart_travel_BE.entity.Homestay;
import com.example.smart_travel_BE.repository.DestinationRepository;
import com.example.smart_travel_BE.repository.HomestayRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatAIService {

	private static final String GITHUB_MODELS_API = "https://models.inference.ai.azure.com/chat/completions";

	private final DestinationRepository destinationRepository;
	private final HomestayRepository homestayRepository;
	private final ObjectMapper objectMapper = new ObjectMapper();
	private final RestTemplate restTemplate = new RestTemplate();

	@Value("${github.token}")
	private String githubToken;

	@Value("${github.model}")
	private String githubModel;

	public ChatAskResponse askAI(ChatAskRequest request) {
		try {
			Map<String, Object> candidateContext = buildCandidateContext(request.getPrompt());
			Map<String, Object> payload = buildPayload(request.getPrompt(), candidateContext);

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.setBearerAuth(githubToken);

			HttpEntity<String> entity = new HttpEntity<>(objectMapper.writeValueAsString(payload), headers);
			ResponseEntity<String> response = restTemplate.postForEntity(GITHUB_MODELS_API, entity, String.class);
			String content = extractContent(response.getBody());

			return parseResponse(content);
		} catch (Exception e) {
			log.error("Chat AI error", e);
			return fallbackResponse();
		}
	}

	private Map<String, Object> buildPayload(String userPrompt, Map<String, Object> candidateContext) {
		String prompt = """
				Bạn là trợ lý du lịch Smart Travel.
				Hãy trả lời ngắn gọn bằng tiếng Việt và chỉ chọn từ danh sách gợi ý có sẵn.
				Chủ yếu về homstay và điểm đến.
				Output PHẢI là JSON object với format:
				{
				  "message": "...",
				  "suggestions": [
					{"id":1,"type":"DESTINATION|HOMESTAY","name":"...","description":"...","thumbnail":"...","rating":4.5}
				  ]
				}

				Danh sách ứng viên:
				%s

				Câu hỏi người dùng: %s
				""".formatted(toJson(candidateContext), userPrompt);

		Map<String, Object> payload = new HashMap<>();
		payload.put("model", githubModel);
		payload.put("temperature", 0.5);
		payload.put("max_tokens", 900);
		payload.put("response_format", Map.of("type", "json_object"));
		payload.put("messages", List.of(Map.of("role", "user", "content", prompt)));
		return payload;
	}

	private Map<String, Object> buildCandidateContext(String prompt) {
		List<DestinationDetailResponse> destinations = destinationRepository.findTop5ByIsActiveTrueOrderByViewCountDesc()
				.stream().map(this::mapDestination).collect(Collectors.toList());
		List<HomestayResponse> homestays = homestayRepository.findTop5ByOrderByPricePerNightAsc()
				.stream().map(this::mapHotel).collect(Collectors.toList());

		return Map.of(
				"destinations", destinations,
				"homestays", homestays,
				"prompt", prompt
		);
	}

	private DestinationDetailResponse mapDestination(Destination d) {
		DestinationDetailResponse dto = new DestinationDetailResponse();
		dto.setId(d.getId());
		dto.setName(d.getName());
		dto.setDescription(d.getDescription());
		dto.setAddress(d.getAddress());
		dto.setLatitude(d.getLatitude());
		dto.setLongitude(d.getLongitude());
		dto.setAverageRating(d.getAverageRating());
		dto.setReviewCount(d.getReviewCount());
		dto.setIsActive(d.getIsActive());
		dto.setIsFeatured(d.getIsFeatured());
		return dto;
	}

	private HomestayResponse mapHotel(Homestay h) {
		return HomestayResponse.builder()
				.id(h.getId())
				.name(h.getName())
				.address(h.getAddress())
				.pricePerNight(h.getMinPrice())
				.stars(h.getStarRating())
				.rating(h.getAverageRating() != null ? h.getAverageRating().doubleValue() : null)
				.numOfReviews(h.getReviewCount())
				.thumbnail(h.getThumbnail())
				.destinationId(h.getDestination() != null ? h.getDestination().getId() : null)
				.destinationName(h.getDestination() != null ? h.getDestination().getName() : null)
				.description(h.getDescription())
				.latitude(h.getLatitude())
				.longitude(h.getLongitude())
				.build();
	}

	private String extractContent(String body) throws Exception {
		Map<String, Object> json = objectMapper.readValue(body, new TypeReference<>() {});
		List<Map<String, Object>> choices = (List<Map<String, Object>>) json.get("choices");
		Map<String, Object> choice = choices.get(0);
		Map<String, Object> message = (Map<String, Object>) choice.get("message");
		return Objects.toString(message.get("content"), "{}");
	}

	private ChatAskResponse parseResponse(String content) {
		try {
			Map<String, Object> json = objectMapper.readValue(content, new TypeReference<>() {});
			List<ChatSuggestion> suggestions = new ArrayList<>();
			List<Map<String, Object>> rawSuggestions = (List<Map<String, Object>>) json.getOrDefault("suggestions", List.of());
			for (Map<String, Object> item : rawSuggestions) {
				suggestions.add(ChatSuggestion.builder()
						.id(item.get("id") != null ? Long.valueOf(item.get("id").toString()) : null)
						.type(Objects.toString(item.get("type"), ""))
						.name(Objects.toString(item.get("name"), ""))
						.description(Objects.toString(item.get("description"), ""))
						.image(Objects.toString(item.get("thumbnail"), null))
						.rating(item.get("rating") != null ? Double.valueOf(item.get("rating").toString()) : null)
						.latitude(item.get("latitude") != null ? Double.valueOf(item.get("latitude").toString()) : null)
						.longitude(item.get("longitude") != null ? Double.valueOf(item.get("longitude").toString()) : null)
						.detailUrl(buildDetailUrl(Objects.toString(item.get("type"), ""), item.get("id")))
						.build());
			}

			return ChatAskResponse.builder()
					.message(Objects.toString(json.get("message"), content))
					.suggestions(suggestions)
					.timestamp(Instant.now().getEpochSecond())
					.build();
		} catch (Exception e) {
			log.warn("AI response not JSON", e);
			return ChatAskResponse.builder()
					.message(content)
					.suggestions(List.of())
					.timestamp(Instant.now().getEpochSecond())
					.build();
		}
	}

	private String buildDetailUrl(String type, Object id) {
		if (id == null) return null;
		if ("HOMESTAY".equalsIgnoreCase(type)) return "/hotel-detail/" + id;
		if ("DESTINATION".equalsIgnoreCase(type)) return "/destination-detail/" + id;
		return null;
	}

	private String toJson(Object obj) {
		try {
			return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(obj);
		} catch (Exception e) {
			return "{}";
		}
	}

	private ChatAskResponse fallbackResponse() {
		return ChatAskResponse.builder()
				.message("Mình chưa lấy được kết quả AI lúc này, bạn thử lại nhé.")
				.suggestions(List.of())
				.timestamp(Instant.now().getEpochSecond())
				.build();
	}
}


