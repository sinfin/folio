import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from "path"

const root = path.resolve(__dirname, "src");

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": root, // Map @ to ./src
    },
  },
})
