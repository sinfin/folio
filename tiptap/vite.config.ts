import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import { resolve } from "path";
import { fileURLToPath, URL } from "node:url";
import { readFileSync, writeFileSync } from "node:fs";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    {
      name: "folio-editor-bundle-eof",
      writeBundle() {
        const bundlePath = fileURLToPath(
          new URL("./dist/assets/folio-tiptap.js", import.meta.url),
        );
        const bundle = readFileSync(bundlePath, "utf8");
        writeFileSync(bundlePath, bundle.replace(/\n*$/, "\n"));
      },
    },
  ],
  resolve: {
    alias: {
      "@": resolve(fileURLToPath(new URL("./src", import.meta.url))),
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: ["global-builtin", "import", "slash-div"],
        quietDeps: true,
      },
    },
  },
  build: {
    outDir: "dist",
    sourcemap: true,
    target: "es2020",
    chunkSizeWarningLimit: 800,
    rolldownOptions: {
      output: {
        entryFileNames: "assets/folio-tiptap.js",
        chunkFileNames: "assets/folio-tiptap-chunk.js",
        assetFileNames: "assets/folio-tiptap.[ext]",
      },
    },
  },
  preview: {
    port: 4173,
  },
});
