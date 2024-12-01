# What to Cook - Recipe Generator

A web application that generates recipes based on available ingredients using AI. The application consists of a Rails API backend and a React frontend.

## Prerequisites

- Ruby 3.x
- Node.js 16+
- PostgreSQL
- OpenAI API Key
- Docker (for production deployment)

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
5. Set up your environment variables by copying the example file:
   ```bash
   cp env.example .env
   ```
   Then edit `.env` and add your OpenAI API key and organization ID (optional)

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

## Production Deployment

The application is configured for deployment using Docker and Kamal. To build and run the Docker container:

```bash
# Build the image
docker build -t what_to_cook_llm .

# Run the container
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<your-master-key> --name what_to_cook_llm what_to_cook_llm
```

For production deployment using Kamal, refer to the deployment configuration in the `.kamal` directory.

## Technologies Used

- Backend:
  - Ruby on Rails (API mode)
  - PostgreSQL
  - OpenAI API
  - RSpec for testing
  - Docker & Kamal for deployment

- Frontend:
  - React
  - Vite
  - Mantine UI
  - Axios
