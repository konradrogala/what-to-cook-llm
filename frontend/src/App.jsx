import { MantineProvider } from '@mantine/core';
import RecipeGenerator from './components/RecipeGenerator';

function App() {
  return (
    <MantineProvider>
      <div style={{ padding: '2rem' }}>
        <RecipeGenerator />
      </div>
    </MantineProvider>
  );
}

export default App;
