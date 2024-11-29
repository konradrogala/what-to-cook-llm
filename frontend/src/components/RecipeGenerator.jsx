import { useState } from 'react';
import { 
  TextInput, 
  Button, 
  Paper, 
  Title, 
  Text, 
  Stack,
  Progress,
  Center
} from '@mantine/core';
import axios from 'axios';

// Create axios instance with default config
const api = axios.create({
  baseURL: 'http://localhost:3001',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
});

const LoadingState = ({ step }) => {
  const steps = [
    { label: 'Generating recipe with AI...', value: 33 },
    { label: 'Parsing recipe data...', value: 66 },
    { label: 'Saving recipe...', value: 100 }
  ];
  
  const currentStep = steps[step] || steps[0];
  
  return (
    <Paper p="xl" radius="md" withBorder>
      <Stack spacing="md">
        <Title order={3} align="center">Please wait</Title>
        <Text align="center" size="lg" color="dimmed">
          {currentStep.label}
        </Text>
        <Progress 
          value={currentStep.value} 
          size="xl" 
          radius="xl" 
          animate
        />
      </Stack>
    </Paper>
  );
};

const RecipeGenerator = () => {
  const [ingredients, setIngredients] = useState('');
  const [recipe, setRecipe] = useState(null);
  const [loading, setLoading] = useState(false);
  const [loadingStep, setLoadingStep] = useState(0);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setRecipe(null);
    setLoadingStep(0);

    try {
      // Simulate step progress since we can't track actual API progress
      setLoadingStep(0); // Generating recipe
      const response = await api.post('/api/v1/recipes', {
        ingredients,
      });
      setLoadingStep(2); // Final step
      setRecipe(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Something went wrong');
    } finally {
      setLoading(false);
      setLoadingStep(0);
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', position: 'relative', minHeight: '400px' }}>
      <Title order={1} align="center" mb="xl">
        Recipe Generator
      </Title>

      <Paper p="md" mb="lg">
        <form onSubmit={handleSubmit}>
          <TextInput
            label="Enter your ingredients"
            placeholder="e.g., chicken, rice, tomatoes"
            value={ingredients}
            onChange={(e) => setIngredients(e.target.value)}
            required
            mb="md"
          />
          <Button 
            type="submit" 
            fullWidth 
            loading={loading}
            disabled={loading}
          >
            {loading ? 'Generating Recipe...' : 'Generate Recipe'}
          </Button>
        </form>
      </Paper>

      {loading && (
        <Center my="xl">
          <LoadingState step={loadingStep} />
        </Center>
      )}

      {error && (
        <Paper p="md" mb="lg" style={{ backgroundColor: '#ffebee' }}>
          <Text color="red">{error}</Text>
        </Paper>
      )}

      {recipe && (
        <Paper p="md">
          <Title order={2} mb="md">{recipe.title}</Title>
          
          <Title order={3} mb="xs">Ingredients:</Title>
          <Text mb="md" component="pre" style={{ whiteSpace: 'pre-wrap' }}>
            {recipe.ingredients}
          </Text>

          <Title order={3} mb="xs">Instructions:</Title>
          <Text component="pre" style={{ whiteSpace: 'pre-wrap' }}>
            {recipe.instructions}
          </Text>
        </Paper>
      )}
    </div>
  );
};

export default RecipeGenerator;
