// jac-dev-status.js (generated) - Vite-layer + browser-load-layer build health.
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const statusFile = path.resolve(__dirname, "..", ".jac-dev-status.json");

const state = { vite: null, client: null };

function flush() {
  try {
    if (!state.vite && !state.client) {
      if (fs.existsSync(statusFile)) fs.unlinkSync(statusFile);
      return;
    }
    fs.writeFileSync(statusFile, JSON.stringify(state), "utf-8");
  } catch (e) {}
}

// Called by jacErrorReporter when the browser reports a load-phase failure
// (module link/eval errors that Vite serves with 200 and never sees).
export function reportClientLoad(data) {
  state.client = {
    message: String((data && data.message) || "client module load failed"),
    file: String((data && data.source) || ""),
  };
  flush();
}

export default function jacDevStatus() {
  return {
    name: "jac-dev-status",
    apply: "serve",
    configureServer(server) {
      flush(); // both slots start null: removes stale state from a prior run

      // Vite announces every transform/resolve failure on its HMR channel
      // (the payload that drives its own error overlay), and update/full-reload
      // on recovery. Mirror exactly those semantics into the vite slot.
      const wrap = (chan) => {
        if (!chan || typeof chan.send !== "function" || chan.__jacDevStatus) return;
        chan.__jacDevStatus = true;
        const orig = chan.send.bind(chan);
        chan.send = (...args) => {
          try {
            const payload = args[0];
            if (payload && payload.type === "error" && payload.err) {
              // jac* payloads are the Jac and browser layers, tracked elsewhere
              if (!String(payload.err.plugin || "").startsWith("jac")) {
                state.vite = {
                  message: String(payload.err.message || "Vite error"),
                  file: String(payload.err.id || ""),
                };
                flush();
              }
            } else if (
              payload
              && (payload.type === "update" || payload.type === "full-reload")
              && state.vite
              // Jac-recovery reloads (jacBuildErrorOverlay) say nothing about
              // the Vite layer; with no client connected nothing will re-arm
              // a still-broken module, so keep the error latched.
              && !payload.jacTriggered
              && server.ws.clients
              && server.ws.clients.size > 0
            ) {
              state.vite = null;
              flush();
            }
          } catch (e) {}
          return orig(...args);
        };
      };
      wrap(server.ws);
      wrap(server.hot);

      // The dev index.html sends this after the entry module loads cleanly:
      // the only reliable "browser recovered" signal a server can get.
      const onReady = () => {
        if (state.client) {
          state.client = null;
          flush();
        }
      };
      server.ws.on("jac:client-ready", onReady);
      // mirror wrap(): register on the HMR channel too if it is distinct
      if (server.hot && server.hot !== server.ws && typeof server.hot.on === "function") {
        try { server.hot.on("jac:client-ready", onReady); } catch (e) {}
      }
    },
  };
}
