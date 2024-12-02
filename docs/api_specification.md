# What-to-Cook LLM API Specification

## Overview
RESTful API that generates recipe suggestions based on provided ingredients using OpenAI's GPT model.

## Base URL
`/api/v1`

## Endpoints

### Generate Recipe
`POST /recipes`

Generates a recipe based on provided ingredients.

#### Request
```json
{
  "ingredients": ["tomato", "pasta"] // or "tomato, pasta" as string
}
```

#### Response
```json
{
  "recipe": {
    "title": "Pasta with Tomato Sauce",
    "ingredients": ["tomato", "pasta", "olive oil", "garlic"],
    "instructions": ["Step 1: Boil pasta", "Step 2: Make sauce"],
    "cooking_time": "30 minutes",
    "servings": 4,
    "difficulty": "easy",
    "created_at": "2024-01-20T12:00:00Z"
  },
  "remaining_requests": 4
}
```

#### Error Responses
- 422 Unprocessable Entity: Invalid input data
- 429 Too Many Requests: Rate limit exceeded
- 500 Internal Server Error: Unexpected error
- 503 Service Unavailable: OpenAI API error

## Rate Limiting
- 5 requests per hour per session
- Reset time provided in error response when limit exceeded
