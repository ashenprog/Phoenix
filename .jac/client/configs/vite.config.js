import { defineConfig } from "vite";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import react from "@vitejs/plugin-react";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Resolve this configuration relative to its exported workspace.
const buildDir = path.resolve(__dirname, "..");
const projectRoot = path.resolve(__dirname, "../../..");

// Jac source mapper plugin - chains the per-file column maps the Jac client
// compiler writes, so a bundled stack keeps its way back to .jac coordinates.
// It derives no locations of its own: that is the Jac side's job.
function jacSourceMapChain() {
  return {
    name: 'jac-source-map-chain',
    enforce: 'pre',

    transform(code, id) {
      if (id.includes('/compiled/') && id.endsWith('.js')) {
        const mapPath = id + '.map';
        try {
          if (fs.existsSync(mapPath)) {
            const rawMap = JSON.parse(fs.readFileSync(mapPath, 'utf-8'));
            return { code, map: rawMap };
          }
        } catch (e) {}
      }
      return null;
    }
  };
}

/**
 * Vite configuration generated from config.json (in project root)
 * To customize, edit config.json instead of this file.
 */

export default defineConfig({
  base: "/",
  define: {

  },
  plugins: [
    jacSourceMapChain(),
    react()
  ],
  root: buildDir, // base folder (.jac/client/) so vite can find node_modules
  envDir: projectRoot, // Load .env files from project root
    build: {
    sourcemap: true, // Enable source maps for better error messages

    rollupOptions: {
      input: path.resolve(buildDir, "compiled/_entry.js"), // your compiled entry file
      output: {
        entryFileNames: "client.[hash].js", // name of the final js file
        assetFileNames: (assetInfo) => assetInfo.name?.endsWith('.css') ? 'styles.css' : '[name].[ext]',
        sourcemapPathTransform: (relativeSourcePath) => {
          // Transform source map paths to point to original location
          return relativeSourcePath;
        },
      },
    },
    outDir: path.resolve(buildDir, "dist"), // final bundled output
    emptyOutDir: true,
  },
  publicDir: false,
  resolve: {
      alias: {
        "@jac/runtime": path.resolve(buildDir, "compiled/client_runtime.js"),
        "@jac/prelude": path.resolve(buildDir, "compiled/jac_prelude.js"),
      "@jac/desktop": path.resolve(buildDir, "compiled/desktop_api.js"),
      "@jac/mobui": path.resolve(buildDir, "compiled/client_mobui.js"),
        "@jac-client/assets": path.resolve(buildDir, "compiled/assets"),
      },
      extensions: [".mjs", ".js", ".mts", ".ts", ".jsx", ".tsx", ".json"],

  },
});
