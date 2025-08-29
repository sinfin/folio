import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import { resolve } from 'path'
import { fileURLToPath, URL } from 'node:url'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": resolve(fileURLToPath(new URL('./src', import.meta.url))),
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: ['global-builtin', 'import', 'slash-div'],
        quietDeps: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'esbuild',
    target: 'es2020',
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        manualChunks: undefined,
        entryFileNames: 'assets/folio-tiptap.js',
        chunkFileNames: 'assets/folio-tiptap-chunk.js',
        assetFileNames: 'assets/folio-tiptap.[ext]'
      }
    }
  },
  preview: {
    port: 4173
  }
})
