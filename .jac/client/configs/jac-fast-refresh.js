// jac-fast-refresh.js (generated) - React Fast Refresh for Jac's compiled modules.
export default function jacFastRefresh() {
  return {
    name: "jac-fast-refresh",
    apply: "serve",
    transform(code, id) {
      const clean = id.split("?")[0];
      if (!clean.includes("/compiled/")) return null;
      if (!clean.endsWith(".js")) return null;
      if (code.indexOf("/*jac-fr*/") !== -1) return null;
      // The compiler stamps modules whose every export is a component; anything
      // unstamped (globs, helpers, router wiring) keeps full-reload semantics.
      if (code.indexOf("/*jac:refresh-boundary*/") === -1) return null;

      const modId = JSON.stringify(clean);
      // same self-accepting boundary @vitejs/plugin-react appends to JSX modules
      const header = '/*jac-fr*/import * as RefreshRuntime from "/@react-refresh";\n';

      const footer =
        "\nif (import.meta.hot) {" +
        "RefreshRuntime.__hmr_import(import.meta.url).then(function (currentExports) {" +
        "RefreshRuntime.registerExportsForReactRefresh(" + modId + ", currentExports);" +
        "import.meta.hot.accept(function (nextExports) {" +
        "if (!nextExports) return;" +
        "const inv = RefreshRuntime.validateRefreshBoundaryAndEnqueueUpdate(" + modId + ", currentExports, nextExports);" +
        "if (inv) import.meta.hot.invalidate(inv);" +
        "});" +
        "});" +
        "}\n";

      // header is exactly one line, so one empty mapping row keeps the sourcemap chain
      let map = null;
      try {
        map = this.getCombinedSourcemap();
        map.mappings = ";" + map.mappings;
      } catch (e) {
        map = null;
      }
      return { code: header + code + footer, map: map };
    }
  };
}
