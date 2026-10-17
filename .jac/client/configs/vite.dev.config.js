import { defineConfig } from "vite";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import react from "@vitejs/plugin-react";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const buildDir = path.resolve(__dirname, "..");
const projectRoot = path.resolve(__dirname, "../../..");
import jacFastRefresh from "./jac-fast-refresh.js";
import jacDevStatus, { reportClientLoad } from "./jac-dev-status.js";

// Vite plugin: forward client-side runtime errors to the terminal and browser overlay
function jacErrorReporter() {
  const seen = new Map();
  return {
    name: "jac-error-reporter",
    configureServer(server) {
      server.ws.on("jac:client-error", (data) => {
        const key = data.type + ":" + data.message;
        const now = Date.now();
        if (seen.get(key) > now - 2000) return;
        seen.set(key, now);
        let loc = "";
        if (data.source) {
          try {
            var p = new URL(data.source).pathname.slice(1)
              .replace("compiled/", "").replace(".vite/deps/", "");
            if (p.endsWith(".js")) p = p.slice(0, -3) + ".jac";
            loc = " (" + p;
            if (data.line) loc += ":" + data.line;
            if (data.column) loc += ":" + data.column;
            loc += ")";
          } catch(e) {}
        }
        // Timestamped: the log is append-only, so a fixed error otherwise reads as live.
        console.error("[" + new Date(now).toISOString() + "] Client error: " + data.type + ": " + data.message + loc);
        if (data.phase === "load") {
          try { reportClientLoad(data); } catch (e) {}
          server.ws.send({
            type: "error",
            err: {
              message: data.message,
              stack: data.stack || "",
              id: data.source || "compiled/_entry.js",
              frame: "",
              plugin: "jac-error-reporter",
            },
          });
        }
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

// Vite plugin: surface Jac build errors via Vite's native error overlay.
// The jac dev server mirrors build health to .jac-build-error.json; the file
// existing means broken (show overlay), removed means recovered (reload).
function jacBuildErrorOverlay() {
  const statusFile = path.resolve(buildDir, ".jac-build-error.json");
  let lastRaw = null;
  const read = () => {
    try { return fs.readFileSync(statusFile, "utf-8"); } catch (e) { return ; }
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
        let file = "", message = raw;
        try {
          const data = JSON.parse(raw);
          file = data.file || "";
          message = data.message || "Jac build error";
        } catch (e) {}
        server.ws.send({
          type: "error",
          err: { message: message, stack: "", id: file, plugin: "jac" },
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
 * Proxies API routes to Python server at localhost:8001
 */
export default defineConfig({
  base: "/",
  define: {

  },
  plugins: [
    jacErrorReporter(),
    jacPortReporter(),
    jacBuildErrorOverlay(),
    jacDevStatus(),
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
      "/walker": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/function": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/user": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/introspect": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/static": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/docs": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/openapi.json": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/admin": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/graph": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      "/redoc": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
      // Backend serves project assets/ dir in dev; Vite owns /assets/* only at build time.
      "/assets": {
        target: "http://localhost:8001",
        changeOrigin: true,
      },
    },

  },
  resolve: {
    alias: {
      "@jac/runtime": path.resolve(buildDir, "compiled/client_runtime.js"),
      "@jac/desktop": path.resolve(buildDir, "compiled/desktop_api.js"),
      "@jac/mobui": path.resolve(buildDir, "compiled/client_mobui.js"),
      "@jac-client/assets": path.resolve(buildDir, "compiled/assets"),
    },
    extensions: [".mjs", ".js", ".mts", ".ts", ".jsx", ".tsx", ".json"],

  },
});
