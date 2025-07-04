#!/bin/bash

WIREMOCK_URL="http://localhost:8080"
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJhdWQiOlsiZm9vIiwiYmFyIl19.aqa_OxjpGtC4nHVCUlCqmiNHOAYK6VFyq2HFsOOmJIY"

echo "Clear all mappings..."
curl -X DELETE $WIREMOCK_URL/__admin/mappings

echo -e "\n\nSetup simple JWT body test..."
curl -X POST $WIREMOCK_URL/__admin/mappings \
  -H "Content-Type: application/json" \
  -d '{
    "request": {
      "method": "POST",
      "url": "/body-test",
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
      "body": "Body JWT matched!"
    }
  }'

echo -e "\n\nTest JSON body with assertion:"
curl -X POST $WIREMOCK_URL/body-test \
  -H "Content-Type: application/json" \
  -d "{\"assertion\": \"$JWT_TOKEN\"}" \
  -v