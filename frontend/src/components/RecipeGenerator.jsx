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
  Box
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
  const [loading, setLoading] = useState(false);
  const [loadingStep, setLoadingStep] = useState(0);
  const [error, setError] = useState(null);
  const [remainingRequests, setRemainingRequests] = useState(MAX_REQUESTS);

  const validateInput = (input) => {
    if (!input.trim()) {
      return 'Ingredients cannot be empty';
    }
    if (input.length > MAX_INPUT_LENGTH) {
      return `Input exceeds maximum length of ${MAX_INPUT_LENGTH} characters`;
    }
    if (!/^[a-zA-Z0-9\s,.()\-+'&\n]+$/.test(input)) {
      return 'Input contains invalid characters';
    }
    return null;
  };

  const handleInputChange = (e) => {
    const value = e.target.value;
    setIngredients(value);
    setError(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const validationError = validateInput(ingredients);
    if (validationError) {
      setError(validationError);
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
      setRecipe(response.data.recipe);
      setRemainingRequests(response.data.remaining_requests);
    } catch (err) {
      if (err.response?.status === 429) {
        setError('You have reached the maximum number of requests for this session.');
        setRemainingRequests(0);
      } else {
        const errorMessage = err.response?.data?.error || 'An unexpected error occurred';
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
      setLoadingStep(0);
    }
  };

  return (
    <Box p="xl" maw={800} mx="auto">
      <Title order={1} align="center" mb="xl" c="grape.7">
        Recipe Generator
      </Title>

      {remainingRequests <= 0 ? (
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
      ) : (
        <>
          <Paper p="xl" radius="md" withBorder shadow="sm" bg="pink.0">
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

          {loading && (
            <Center my="xl">
              <LoadingState step={loadingStep} />
            </Center>
          )}

          {error && !loading && (
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
        </>
      )}

      {recipe && (
        <Paper p="xl" radius="md" withBorder shadow="sm" bg="cyan.0">
          <Title order={2} mb="md" c="cyan.8">{recipe.title}</Title>
          
          <Title order={3} mb="xs" c="cyan.7">Ingredients:</Title>
          <Text mb="md" component="pre" style={{ whiteSpace: 'pre-wrap' }}>
            {recipe.ingredients}
          </Text>

          <Title order={3} mb="xs" c="cyan.7">Instructions:</Title>
          <Text component="pre" style={{ whiteSpace: 'pre-wrap' }}>
            {recipe.instructions}
          </Text>
        </Paper>
      )}
    </Box>
  );
};

export default RecipeGenerator;
