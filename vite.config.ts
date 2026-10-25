import { defineConfig } from "vite";

// base relativo: funciona em qualquer subcaminho (GitHub Pages, Vercel, arquivo local).
export default defineConfig({
  base: "./",
  build: { target: "es2022", chunkSizeWarningLimit: 1200 },
});
