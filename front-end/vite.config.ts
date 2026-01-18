import { defineConfig } from "vite";
import { compression } from "vite-plugin-compression2";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    compression({
      algorithms: ["gzip", "br"],
    }),
  ],
  build: {
    outDir: "../src/dist",
    rollupOptions: {
      output: {
        // file: 'index.[ext]'
        entryFileNames: "index.js",
        assetFileNames: (assetInfo) => {
          const ext = assetInfo.name?.split(".").pop();
          if (ext === "css") {
            return "index.css";
          }
          if (["png", "jpg", "jpeg", "svg", "webp"].includes(ext!)) {
            return "images/[name].[ext]";
          }
          return "assets/[name].[ext]";
        },
      },
    },
  },
});
