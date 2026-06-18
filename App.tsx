import React from 'react';
import './src/i18n'; // Initialize i18n
import { AppProvider } from './src/services/store';
import HomeScreen from './src/screens/HomeScreen';

export default function App() {
  return (
    <AppProvider>
      <HomeScreen />
    </AppProvider>
  );
}
