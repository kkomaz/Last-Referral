/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          light: '#7b68ee',
          dark: '#9f8fff'
        },
        secondary: {
          light: '#2b2d42',
          dark: '#1a1b2e'  // Darker shade for dark mode
        },
        background: {
          light: '#f7f9fb',
          dark: '#0f1117'  // Darker background
        },
        card: {
          light: '#ffffff',
          dark: '#1a1b2e'  // Darker card background
        },
        border: {
          light: '#e2e8f0',
          dark: '#2e2e45'  // Darker border color
        },
        text: {
          light: '#2b2d42',
          dark: '#e2e8f0'
        },
        muted: {
          light: '#64748b',
          dark: '#94a3b8'
        }
      }
    },
  },
  plugins: [],
};