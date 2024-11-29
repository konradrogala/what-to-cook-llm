# What to Cook - Recipe Generator

A web application that generates recipes based on available ingredients using AI. The application consists of a Rails API backend and a React frontend.

## Prerequisites

- Ruby 3.x
- Node.js 16+
- PostgreSQL
- Anthropic API Key

## Setup

### Backend Setup

1. Clone the repository
2. Navigate to the project directory
3. Install Ruby dependencies:
   ```bash
   bundle install
   ```
4. Set up the database:
   ```bash
   rails db:create db:migrate
   ```
5. Set up your environment variables:
   ```bash
   export ANTHROPIC_API_KEY=your_api_key_here
   ```
6. Start the Rails server:
   ```bash
   rails s -p 3001
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install Node.js dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

## Usage

1. Open your browser and navigate to `http://localhost:5173`
2. Enter the ingredients you have available in the input field
3. Click "Generate Recipe"
4. Wait for the AI to generate a recipe based on your ingredients
5. The generated recipe will include a title, list of ingredients, and step-by-step instructions

## Testing

Run the test suite:

```bash
rspec
```

## Technologies Used

- Backend:
  - Ruby on Rails (API mode)
  - PostgreSQL
  - Anthropic Claude API
  - RSpec for testing

- Frontend:
  - React
  - Vite
  - Mantine UI
  - Axios
