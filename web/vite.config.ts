import { defineConfig } from "vite";
import preact from "@preact/preset-vite";
import { compression } from "vite-plugin-compression2";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    preact(),
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
