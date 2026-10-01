import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          const path = id.replaceAll('\\', '/');
          if (path.includes('/node_modules/lucide-react/')) return 'icons';
          if (path.includes('/node_modules/@supabase/')) return 'supabase';
          if (path.includes('/node_modules/react-router')) return 'router';
          if (/\/node_modules\/(react|react-dom)\//.test(path)) return 'react-vendor';
        },
      },
    },
  },
});
