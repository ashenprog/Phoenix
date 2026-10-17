/* Source: /home/user/.cache/jac/rt/f562f1257227d66d/site/jaclang/client/endpoint_cache.jac */
import { _jac } from "@jac/prelude";
function __getEndpointEffects() {
  let initEl;
  let data;
  let effects = globalThis.__jacEndpointEffects__;
  if (effects) {
    return effects;
  }
  let seed_fn = globalThis.__jacSeedEndpointEffects__;
  if (seed_fn) {
    effects = seed_fn();
    globalThis.__jacEndpointEffects__ = effects;
    return effects;
  }
  let initText = null;
  if (globalThis.document) {
    try {
      initEl = document.getElementById("__jac_init__");
      if (_jac.builtin.isinstance(initEl, HTMLElement)) {
        initText = initEl.textContent;
      }
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        let e = __jac_e;
        console.warn("[jac-client] Failed to find __jac_init__ element:", e);
      } else {
        throw __jac_e;
      }
    }
  }
  if (initText) {
    try {
      data = JSON.parse(initText);
      effects = (data["endpointEffects"] || {});
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        let e = __jac_e;
        console.warn("[jac-client] Failed to parse __jac_init__ data, using empty effects:", e);
        effects = {};
      } else {
        throw __jac_e;
      }
    }
  } else {
    effects = {};
  }
  globalThis.__jacEndpointEffects__ = effects;
  return effects;
}
function __getCacheState() {
  let state = globalThis.__jacCacheState__;
  if (!state) {
    state = {"cache": {}, "order": [], "pending": {}, "generations": {}, "epoch": 0, "activeWrites": 0, "config": {"maxEntries": 500, "defaultTtlMs": 60000}};
    globalThis.__jacCacheState__ = state;
  }
  return state;
}
function __isFresh(entry) {
  if (!_jac.builtin.bool(entry)) {
    return false;
  }
  let age = (Date.now() - entry["timestamp"]);
  return (age < entry["ttl"]);
}
function __cacheGet(key) {
  let state = __getCacheState();
  let entry = _jac.poly.getitem(state["cache"], key);
  if (!entry) {
    return null;
  }
  let idx = state["order"].indexOf(key);
  if ((idx > (-1))) {
    state["order"].splice(idx, 1);
  }
  state["order"].push(key);
  return entry;
}
function __cacheSet(key, data, ttl) {
  let idx;
  let state = __getCacheState();
  if (_jac.poly.getitem(state["cache"], key)) {
    idx = state["order"].indexOf(key);
    if ((idx > (-1))) {
      state["order"].splice(idx, 1);
    }
  }
  while ((_jac.builtin.len(state["order"]) >= state["config"]["maxEntries"])) {
    __evictOldest();
  }
  state["cache"][key] = {"data": data, "timestamp": Date.now(), "ttl": ttl};
  state["order"].push(key);
}
function __evictOldest() {
  let oldest;
  let state = __getCacheState();
  if ((_jac.builtin.len(state["order"]) > 0)) {
    oldest = state["order"].shift();
    if ((oldest && _jac.poly.getitem(state["cache"], oldest))) {
      Reflect.deleteProperty(state["cache"], oldest);
    }
  }
}
function __overlaps(list1, list2) {
  if ((list1.includes("*") || list2.includes("*"))) {
    return (_jac.builtin.bool(list1) && _jac.builtin.bool(list2));
  }
  for (const item of list1) {
    if (list2.includes(item)) {
      return true;
    }
  }
  return false;
}
function __invalidateEndpoint(endpoint_key) {
  let idx;
  let state = __getCacheState();
  state["generations"][endpoint_key] = ((_jac.poly.getitem(state["generations"], endpoint_key) || 0) + 1);
  let keys_to_delete = [];
  for (const key of _jac.poly.call(Object, "keys", state["cache"])) {
    if (key.startsWith((endpoint_key + ":"))) {
      keys_to_delete.push(key);
    }
  }
  for (const key of keys_to_delete) {
    Reflect.deleteProperty(state["cache"], key);
    idx = state["order"].indexOf(key);
    if ((idx > (-1))) {
      state["order"].splice(idx, 1);
    }
  }
}
async function __cachedEndpointCall(endpoint_key, args_key, fetch_fn) {
  let cached;
  let pending;
  let fetch_promise;
  let request;
  let data;
  let effects = __getEndpointEffects();
  let info = effects[endpoint_key];
  let state = __getCacheState();
  let generation = (_jac.poly.getitem(state["generations"], endpoint_key) || 0);
  let epoch = state["epoch"];
  if ((((info && !info["unknown"]) && (_jac.builtin.len(info["writes"]) === 0)) && (state["activeWrites"] === 0))) {
    cached = __cacheGet(args_key);
    if ((cached && __isFresh(cached))) {
      return cached["data"];
    }
    pending = _jac.poly.getitem(state["pending"], args_key);
    if (((pending && (pending["generation"] === generation)) && (pending["epoch"] === epoch))) {
      return await pending["promise"];
    }
    fetch_promise = fetch_fn();
    request = {"promise": fetch_promise, "generation": generation, "epoch": epoch};
    state["pending"][args_key] = request;
    try {
      data = await fetch_promise;
      if ((((state["epoch"] === epoch) && ((_jac.poly.getitem(state["generations"], endpoint_key) || 0) === generation)) && (state["activeWrites"] === 0))) {
        __cacheSet(args_key, data, state["config"]["defaultTtlMs"]);
      }
      return data;
    } finally {
      if ((_jac.poly.getitem(state["pending"], args_key) === request)) {
        Reflect.deleteProperty(state["pending"], args_key);
      }
    }
  }
  if (((!info || info["unknown"]) || (_jac.builtin.len(info["writes"]) > 0))) {
    state["activeWrites"] += 1;
    __invalidateEffects((info ? info["writes"] : ["*"]));
    try {
      return await fetch_fn();
    } finally {
      __invalidateEffects((info ? info["writes"] : ["*"]));
      state["activeWrites"] -= 1;
    }
  }
  return await fetch_fn();
}
function __invalidateEffects(writes) {
  let reader;
  let effects = __getEndpointEffects();
  for (const endpoint_name of _jac.poly.call(Object, "keys", effects)) {
    reader = effects[endpoint_name];
    if ((((reader && !reader["unknown"]) && (_jac.builtin.len(reader["writes"]) === 0)) && __overlaps(reader["reads"], writes))) {
      __invalidateEndpoint(endpoint_name);
    }
  }
}
function __jacClearCache() {
  let state = __getCacheState();
  state["epoch"] += 1;
  state["pending"] = {};
  for (const key of _jac.poly.call(Object, "keys", state["cache"])) {
    Reflect.deleteProperty(state["cache"], key);
  }
  state["order"].splice(0, state["order"].length);
}
function __endpointKey(kind, name, opts) {
  let info;
  let app = ((opts && opts["app"]) ? opts["app"] : "");
  let module = ((opts && opts["module"]) ? opts["module"] : "");
  let effects = __getEndpointEffects();
  if ((opts && opts["contract"])) {
    return opts["contract"];
  }
  let matches = [];
  for (const key of _jac.poly.call(Object, "keys", effects)) {
    info = effects[key];
    if (((((info["kind"] === kind) && (info["name"] === name)) && (!app || (info["app"] === app))) && (!module || (info["module"] === module)))) {
      matches.push(key);
    }
  }
  if ((matches.length > 1)) {
    throw new Error(((("Ambiguous endpoint contract: " + kind) + ":") + name));
  }
  if ((matches.length === 1)) {
    return matches[0];
  }
  return JSON.stringify([app, module, kind, name]);
}
export {__cacheGet, __cacheSet, __cachedEndpointCall, __endpointKey, __evictOldest, __getCacheState, __getEndpointEffects, __invalidateEffects, __invalidateEndpoint, __isFresh, __jacClearCache, __overlaps};
//# sourceMappingURL=endpoint_cache.js.map
