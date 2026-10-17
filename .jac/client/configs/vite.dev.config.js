import { defineConfig } from "vite";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import react from "@vitejs/plugin-react";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const buildDir = path.resolve(__dirname, "..");
const projectRoot = path.resolve(__dirname, "../../..");
import jacFastRefresh from "./jac-fast-refresh.js";
import jacClientEvents, { recordClientEvent } from "./jac-client-events.js";

// Vite plugin: hand the browser's RAW error payload to the Jac process.
// No path rewriting, no file derivation, no terminal rendering here: the Jac
// side owns resolving a compiled coordinate back to a .jac location, and it
// is the only place a client failure is printed.
function jacErrorReporter() {
  const seen = new Map();
  return {
    name: "jac-error-reporter",
    configureServer(server) {
      server.ws.on("jac:client-error", (data) => {
        const key = String(data.type) + ":" + String(data.message);
        const now = Date.now();
        if (seen.get(key) > now - 2000) return;
        seen.set(key, now);
        try { recordClientEvent(data); } catch (e) {}
      });
    },
  };
}

// Vite plugin: write the bound dev-server port for the jac CLI to read
function jacPortReporter() {
  return {
    name: "jac-port-reporter",
    configureServer(server) {
      server.httpServer?.once("listening", () => {
        const addr = server.httpServer.address();
        if (addr && typeof addr === "object") {
          fs.writeFileSync(path.resolve(buildDir, ".dev-port"), String(addr.port));
        }
      });
    },
  };
}

// Vite plugin: full-reload on demand. Fast Refresh boundaries swallow edits
// that change a module's export set (e.g. removing `:pub`), running stale code
// with no signal. The jac dev server detects the change and bumps
// .jac-force-reload; this reload re-runs the app so the real link error
// surfaces at load (overlay). jacTriggered keeps the dev-status vite slot intact.
function jacForceReload() {
  const signalFile = path.resolve(buildDir, ".jac-force-reload");
  return {
    name: "jac-force-reload",
    configureServer(server) {
      // Create the file so the watch attaches to an existing path; each reload
      // request bumps its contents, firing a "change" the watcher delivers.
      // Reloads fire only when the nonce content actually advances, so a
      // watcher replay of the boot-time value can never cause a spurious reload.
      let lastNonce = "0";
      try { fs.writeFileSync(signalFile, lastNonce); } catch (e) {}
      try { server.watcher.add(signalFile); } catch (e) {}
      const onSig = (f) => {
        if (path.resolve(f) !== signalFile) return;
        let nonce;
        try { nonce = fs.readFileSync(signalFile, "utf-8"); } catch (e) { return; }
        if (nonce === lastNonce) return;
        lastNonce = nonce;
        server.ws.send({ type: "full-reload", path: "*", jacTriggered: true });
      };
      server.watcher.on("add", onSig);
      server.watcher.on("change", onSig);
    },
  };
}

// Vite plugin: surface Jac diagnostics via Vite's native error overlay.
// The jac dev server owns .jac-status.json; the file existing means broken
// (show the rendered diagnostic), removed means recovered (reload).
function jacBuildErrorOverlay() {
  const statusFile = path.resolve(buildDir, ".jac-status.json");
  let lastRaw = null;
  const read = () => {
    try { return fs.readFileSync(statusFile, "utf-8"); } catch (e) { return ""; }
  };
  return {
    name: "jac-build-error-overlay",
    configureServer(server) {
      const push = (raw) => {
        if (raw === lastRaw) return;
        // lastRaw is the last KNOWN state, not the last sent one: record it
        // before any skip, or a recovery that happens with zero clients would
        // leave the old error latched here and dedup-suppress an identical
        // error recurring later.
        lastRaw = raw;
        // No live clients: skip the broadcast (Vite would buffer it and replay
        // stale state to the first client; the connection handler replays the
        // CURRENT state instead).
        if (server.ws.clients && server.ws.clients.size === 0) return;
        if (!raw) {
          server.ws.send({ type: "full-reload", path: "*", jacTriggered: true });
          return;
        }
        // The Jac process already rendered the diagnostic; the overlay shows the
        // headline as the message and the rendered block (location, snippet,
        // help) as the frame.
        let file = "", message = raw, frame = "", stack = "", loc = null;
        try {
          const data = JSON.parse(raw);
          const all = data.diagnostics || [];
          const diag = all[0] || {};
          const more = all.length > 1 ? " (+" + (all.length - 1) + " more)" : "";
          file = diag.file || "";
          message = (diag.code ? diag.code + ": " : "")
            + (diag.message || "Jac build error") + more;
          frame = diag.rendered || "";
          stack = diag.stack || "";
          if (diag.line) loc = { file: file, line: diag.line, column: diag.column || 0 };
        } catch (e) {}
        server.ws.send({
          type: "error",
          err: { message: message, stack: stack, id: file, loc: loc, frame: frame, plugin: "jac" },
        });
      };
      try { server.watcher.add(statusFile); } catch (e) {}
      const onWrite = (f) => { if (path.resolve(f) === statusFile) push(read()); };
      server.watcher.on("add", onWrite);
      server.watcher.on("change", onWrite);
      server.watcher.on("unlink", (f) => {
        const abs = path.resolve(f);
        if (abs === statusFile) {
          push("");
          return;
        }
        // A served module was deleted (e.g. its Jac source was removed while
        // still imported). Importers keep a cached transform pointing at the
        // dead file, which 404s into a blank page with no overlay. Invalidate
        // them and reload so the fresh transform surfaces Vite's own
        // "Failed to resolve import" error overlay.
        try {
          const mods = server.moduleGraph.getModulesByFile(abs);
          if (mods && mods.size) {
            let hadImporters = false;
            for (const mod of mods) {
              for (const importer of mod.importers) {
                hadImporters = true;
                server.moduleGraph.invalidateModule(importer);
              }
              server.moduleGraph.invalidateModule(mod);
            }
            if (hadImporters) {
              server.ws.send({ type: "full-reload", path: "*", jacTriggered: true });
            }
          }
        } catch (e) {}
      });
      // A browser opened (or reloaded) while broken gets the overlay immediately
      server.ws.on("connection", () => {
        const raw = read();
        if (raw) { lastRaw = null; push(raw); }
      });
    },
  };
}

/**
 * Vite DEV configuration for HMR mode
 * Proxies API routes to Python server at localhost:8002
 */
export default defineConfig({
  base: "/",
  define: {

  },
  plugins: [
    jacErrorReporter(),
    jacPortReporter(),
    jacBuildErrorOverlay(),
    jacClientEvents(),
    jacForceReload(),
    jacFastRefresh(),
    react()
  ],
  root: buildDir,
  envDir: projectRoot, // Load .env files from project root
  publicDir: false,
  appType: 'spa',
  build: {
    sourcemap: true, // Enable source maps for better error messages
  },
  server: {
    host: true,
    watch: {
      usePolling: true,
      interval: 100,
      // Runtime state (the desktop SQLite anchor store lives under
      // <root>/.jac/data/ and mutates on every DB write, WAL/SHM included)
      // must not retrigger HMR, or a --dev app that touches its DB reloads
      // in a loop.
      ignored: [
        "**/.jac/data/**",
        "**/*.sqlite",
        "**/*.sqlite3",
        "**/*.db",
        "**/*.db-wal",
        "**/*.db-shm",
      ],
    },
    proxy: {
      "/api": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/walker": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/function": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/user": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/introspect": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/static": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/docs": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/openapi.json": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/healthz": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/admin": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/graph": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/redoc": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
      "/assets": {
        target: "http://localhost:8002",
        changeOrigin: true,
      },
    },

  },
  resolve: {
    alias: {
      "@jac/runtime": path.resolve(buildDir, "phoenix/compiled/client_runtime.js"),
      "@jac/prelude": path.resolve(buildDir, "phoenix/compiled/jac_prelude.js"),
      "@jac/desktop": path.resolve(buildDir, "phoenix/compiled/desktop_api.js"),
      "@jac/mobui": path.resolve(buildDir, "phoenix/compiled/client_mobui.js"),
      "@jac-client/assets": path.resolve(buildDir, "phoenix/compiled/assets"),
    },
    extensions: [".mjs", ".js", ".mts", ".ts", ".jsx", ".tsx", ".json"],

  },
});
