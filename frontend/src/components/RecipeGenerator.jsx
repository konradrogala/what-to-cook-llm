import { useState } from 'react';
import { TextInput, Button, Paper, Title, Text, LoadingOverlay } from '@mantine/core';
import axios from 'axios';

// Create axios instance with default config
const api = axios.create({
  baseURL: 'http://localhost:3001',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
});

const RecipeGenerator = () => {
  const [ingredients, setIngredients] = useState('');
  const [recipe, setRecipe] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setRecipe(null);

    try {
      const response = await api.post('/api/v1/recipes', {
        ingredients,
      });
      setRecipe(response.data);
    } catch (err) {
      setError(err.response?.data?.error || 'Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto' }}>
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
          <Button type="submit" fullWidth loading={loading}>
            Generate Recipe
          </Button>
        </form>
      </Paper>

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

      <LoadingOverlay visible={loading} />
    </div>
  );
};

export default RecipeGenerator;
