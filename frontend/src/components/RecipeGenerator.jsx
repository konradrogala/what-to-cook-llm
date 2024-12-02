import { useState } from 'react';
import { 
  TextInput, 
  Button, 
  Paper, 
  Title, 
  Text, 
  Stack,
  Progress,
  Center,
  Badge,
  Group,
  Alert,
  Box,
  List
} from '@mantine/core';
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3001',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
  xsrfCookieName: 'XSRF-TOKEN',
  xsrfHeaderName: 'X-XSRF-TOKEN',
});

const LoadingState = ({ step }) => {
  const steps = [
    { label: 'Generating recipe with AI...', value: 33 },
    { label: 'Parsing recipe data...', value: 66 },
    { label: 'Saving recipe...', value: 100 }
  ];
  
  const currentStep = steps[step] || steps[0];
  
  return (
    <Paper p="xl" radius="md" withBorder shadow="sm" bg="gray.0">
      <Stack spacing="md">
        <Title order={3} align="center" c="gray.8">Please wait</Title>
        <Text align="center" size="lg" c="gray.6">
          {currentStep.label}
        </Text>
        <Progress 
          value={currentStep.value} 
          size="xl" 
          radius="xl" 
          striped
          color="grape"
        />
      </Stack>
    </Paper>
  );
};

const MAX_REQUESTS = 5;
const MAX_INPUT_LENGTH = 1000;

const RecipeGenerator = () => {
  const [ingredients, setIngredients] = useState('');
  const [recipe, setRecipe] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const [loadingStep, setLoadingStep] = useState(0);
  const [remainingRequests, setRemainingRequests] = useState(MAX_REQUESTS);

  const handleInputChange = (event) => {
    const value = event.target.value;
    if (value.length <= MAX_INPUT_LENGTH) {
      setIngredients(value);
      setError(null);
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!ingredients.trim()) {
      setError('Please enter at least one ingredient');
      return;
    }

    setLoading(true);
    setError(null);
    setRecipe(null);
    setLoadingStep(0);

    try {
      setLoadingStep(0);
      const response = await api.post('/api/v1/recipes', {
        ingredients: ingredients.trim(),
      });
      setLoadingStep(2);

      // Zawsze zachowaj przepis jeśli został zwrócony
      if (response.data.recipe) {
        setRecipe(response.data.recipe);
      }

      // Zaktualizuj pozostałe requestsy
      if (typeof response.data.remaining_requests !== 'undefined') {
        setRemainingRequests(response.data.remaining_requests);
      }

      // Ustaw błąd jeśli przekroczono limit
      if (response.data.limit_reached) {
        setError(response.data.message || 'You have reached the maximum number of requests for this session.');
      }
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'An unexpected error occurred';
      setError(errorMessage);
      
      // Jeśli status to 429, ustaw remaining_requests na 0
      if (err.response?.status === 429) {
        setRemainingRequests(0);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box p="xl" maw={800} mx="auto">
      <Title order={1} mb="xl" c="grape.7">
        Recipe Generator
      </Title>

      {/* Alert o przekroczeniu limitu */}
      {remainingRequests <= 0 && (
        <Alert
          color="pink"
          title="Session Limit Reached"
          mb="lg"
          variant="light"
          radius="md"
        >
          <Stack spacing="xs">
            <Text>You have reached the maximum number of requests for this session.</Text>
            <Text size="sm">Please try again in a new session to generate more recipes.</Text>
            <Text size="sm" c="dimmed" mt="md">Session limit: {MAX_REQUESTS} recipes per session</Text>
          </Stack>
        </Alert>
      )}

      {/* Formularz widoczny tylko gdy są dostępne requesty */}
      {remainingRequests > 0 && (
        <Paper p="xl" radius="md" withBorder shadow="sm" bg="pink.0" mb="xl">
          <form onSubmit={handleSubmit}>
            <TextInput
              label="Enter your ingredients"
              description="Separate ingredients with commas (e.g., chicken, rice, tomatoes)"
              placeholder="e.g., chicken, rice, tomatoes"
              value={ingredients}
              onChange={handleInputChange}
              error={error && !loading ? error : null}
              required
              mb="md"
              size="md"
              radius="md"
            />
            <Stack spacing="sm">
              <Button 
                type="submit" 
                fullWidth 
                loading={loading}
                disabled={loading}
                size="md"
                radius="md"
                color="grape"
              >
                {loading ? 'Generating Recipe...' : 'Generate Recipe'}
              </Button>
              <Group position="center" spacing="xs">
                <Text size="sm" c="dimmed">Remaining requests:</Text>
                <Badge 
                  size="lg"
                  variant="light"
                  color="blue"
                >
                  {remainingRequests}
                </Badge>
              </Group>
            </Stack>
          </form>
        </Paper>
      )}

      {/* Stan ładowania */}
      {loading && (
        <Center my="xl">
          <LoadingState step={loadingStep} />
        </Center>
      )}

      {/* Komunikat o błędzie */}
      {error && !loading && remainingRequests > 0 && (
        <Alert 
          color="red" 
          title="Error" 
          mb="lg"
          variant="light"
          radius="md"
        >
          {error}
        </Alert>
      )}

      {/* Wyświetlanie przepisu */}
      {recipe && (
        <Paper p="xl" radius="md" withBorder shadow="sm" bg="cyan.0">
          <Title order={2} mb="md" c="cyan.8">{recipe.title}</Title>
          
          <Title order={3} mb="xs" c="cyan.7">Ingredients:</Title>
          <List spacing="xs" size="md" mb="md">
            {(typeof recipe.ingredients === 'string' ? recipe.ingredients.split('\n') : 
              Array.isArray(recipe.ingredients) ? recipe.ingredients : [recipe.ingredients])
              .filter(Boolean)
              .map((ingredient, index) => (
                <List.Item key={index}>{ingredient}</List.Item>
            ))}
          </List>

          <Title order={3} mb="xs" c="cyan.7">Instructions:</Title>
          <List spacing="sm" size="md">
            {(typeof recipe.instructions === 'string' ? recipe.instructions.split('\n') : 
              Array.isArray(recipe.instructions) ? recipe.instructions : [recipe.instructions])
              .filter(Boolean)
              .map((instruction, index) => (
                <List.Item key={index}>{instruction}</List.Item>
            ))}
          </List>
        </Paper>
      )}
    </Box>
  );
};

export default RecipeGenerator;
