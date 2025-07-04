package com.github.masonm;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.tomakehurst.wiremock.common.Json;
import com.github.tomakehurst.wiremock.extension.Parameters;
import com.github.tomakehurst.wiremock.http.Request;
import com.github.tomakehurst.wiremock.matching.MatchResult;
import com.github.tomakehurst.wiremock.matching.RequestMatcherExtension;
import com.github.tomakehurst.wiremock.matching.RequestPattern;

import java.util.Map;
import java.util.Objects;

import static com.github.tomakehurst.wiremock.matching.MatchResult.noMatch;
import static com.github.tomakehurst.wiremock.matching.MatchResult.exactMatch;

public class JwtMatcherExtension extends RequestMatcherExtension {
    public static final String NAME = "jwt-matcher";
    public static final String PARAM_NAME_PAYLOAD = "payload";
    public static final String PARAM_NAME_HEADER = "header";
    public static final String PARAM_NAME_REQUEST = "request";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Override
    public String getName() {
        return NAME;
    }

    @Override
    public MatchResult match(Request request, Parameters parameters) {
        if (!parameters.containsKey(PARAM_NAME_PAYLOAD) && !parameters.containsKey(PARAM_NAME_HEADER)) {
            return noMatch();
        }

        if (parameters.containsKey(PARAM_NAME_REQUEST)) {
            Parameters requestParameters = Parameters.of(parameters.get(PARAM_NAME_REQUEST));
            RequestPattern requestPattern = requestParameters.as(RequestPattern.class);
            if (!requestPattern.match(request).isExactMatch()) {
                return noMatch();
            }
        }

        Jwt token = null;

        // 1. Try Authorization header (Bearer)
        String authString = request.getHeader("Authorization");
        if (authString != null && !authString.isEmpty()) {
            token = Jwt.fromAuthHeader(authString);
        }

        // 2. Try body: assertion field (standard OAuth2 JWT Bearer)
        if (token == null) {
            String body = request.getBodyAsString();
            if (body != null && !body.isEmpty()) {
                try {
                    JsonNode json = MAPPER.readTree(body);
                    if (json.has("assertion")) {
                        String jwt = json.get("assertion").asText();
                        token = new Jwt(jwt);
                    }
                } catch (Exception e) {
                    // Optionally log: e.g., log.debug("Failed to parse body as JSON", e);
                }
            }
        }

        // Null check to avoid NPE
        if (token == null) {
            return noMatch();
        }

        if (parameters.containsKey(PARAM_NAME_HEADER) &&
                !matchParams(token.getHeader(), parameters.get(PARAM_NAME_HEADER))) {
            return noMatch();
        }

        if (parameters.containsKey(PARAM_NAME_PAYLOAD) &&
                !matchParams(token.getPayload(), parameters.get(PARAM_NAME_PAYLOAD))) {
            return noMatch();
        }

        return exactMatch();
    }

    private boolean matchParams(JsonNode tokenValues, Object parameters) {
        Map<String, JsonNode> parameterMap = MAPPER.convertValue(
                parameters,
                new TypeReference<Map<String, JsonNode>>() {
                });
        for (Map.Entry<String, JsonNode> entry : parameterMap.entrySet()) {
            JsonNode tokenValue = tokenValues.path(entry.getKey());
            if (!Objects.equals(tokenValue, entry.getValue())) {
                return false;
            }
        }
        return true;
    }
}
