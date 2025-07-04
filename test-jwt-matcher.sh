#!/bin/bash

# Test JWT Matcher Extension with curl commands
WIREMOCK_URL="http://localhost:8080"

# Valid JWT token (header: {"alg":"HS256","typ":"JWT"}, payload: {"name":"John Doe","aud":["foo","bar"]})
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJhdWQiOlsiZm9vIiwiYmFyIl19.aqa_OxjpGtC4nHVCUlCqmiNHOAYK6VFyq2HFsOOmJIY"

# RS256 JWT token (header: {"alg":"RS256","typ":"JWT","kid":"8db263e805464c24829cf1154e2275a9"}, payload: {"iss":"sandbox_client_id","sub":"sandbox_operator_token","aud":"http://localhost:8080/oauth2/v2/token"})
RS256_JWT="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjhkYjI2M2U4MDU0NjRjMjQ4MjljZjExNTRlMjI3NWE5In0.eyJpc3MiOiJzYW5kYm94X2NsaWVudF9pZCIsInN1YiI6InNhbmRib3hfb3BlcmF0b3JfdG9rZW4iLCJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvcmVhbG1zL3NhbmRib3giLCJleHAiOjE3NTA5NTk5MDksImlhdCI6MTc1MDk1NjMwOSwianRpIjoiODg4NzhBOUMtMzNCMy00QUM4LUFEMzAtMkUwRTIzRDJDRjg4Iiwic2NvcGUiOiJkcHY6RnJhdWRQcmV2ZW50aW9uQW5kRGV0ZWN0aW9uIG51bWJlci12ZXJpZmljYXRpb246dmVyaWZ5In0.dummy_signature"

echo "Setting up HS256 JWT mapping..."
curl -X POST $WIREMOCK_URL/__admin/mappings \
  -H "Content-Type: application/json" \
  -d '{
    "request": {
      "url": "/test",
      "method": "POST",
      "customMatcher": {
        "name": "jwt-matcher",
        "parameters": {
          "payload": {
            "name": "John Doe"
          }
        }
      }
    },
    "response": {
      "status": 200,
      "body": "HS256 JWT matched!"
    }
  }'

echo -e "\n\n1. Test Authorization header (should match):"
curl -X POST $WIREMOCK_URL/test \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -v

echo -e "\n\n2. Test JSON body assertion (should match):"
curl -X POST $WIREMOCK_URL/test \
  -H "Content-Type: application/json" \
  -d "{\"assertion\": \"$JWT_TOKEN\"}" \
  -v

echo -e "\n\n3. Test without JWT (should not match):"
curl -X POST $WIREMOCK_URL/test \
  -v

echo -e "\n\n4. Test invalid JWT (should not match):"
curl -X POST $WIREMOCK_URL/test \
  -H "Authorization: Bearer invalid.jwt.token" \
  -v

echo -e "\n\nSetting up RS256 OAuth2 mapping..."
curl -X POST $WIREMOCK_URL/__admin/mappings \
  -H "Content-Type: application/json" \
  -d '{
    "request": {
      "method": "POST",
      "urlPath": "/oauth2/v2/token",
      "customMatcher": {
        "name": "jwt-matcher",
        "parameters": {
          "header": {
            "alg": "RS256",
            "typ": "JWT",
            "kid": "8db263e805464c24829cf1154e2275a9"
          },
          "payload": {
            "iss": "sandbox_client_id",
            "sub": "sandbox_operator_token"
          }
        }
      }
    },
    "response": {
      "status": 200,
      "jsonBody": {
        "access_token": "test_access_token",
        "token_type": "Bearer",
        "expires_in": 3600
      }
    }
  }'

echo -e "\n\n5. Test RS256 JWT in JSON body (should match):"
curl -X POST $WIREMOCK_URL/oauth2/v2/token \
  -H "Content-Type: application/json" \
  -d "{\"assertion\": \"$RS256_JWT\"}" \
  -v