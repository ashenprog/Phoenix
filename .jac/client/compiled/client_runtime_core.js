/* Source: /home/user/.cache/jac/rt/f562f1257227d66d/site/jaclang/client/client_runtime_core.jac */
import {__jacJsx} from "@jac/runtime";
import { SignupResult } from "./auth_contract.js";
import { __endpointKey, __getEndpointEffects as cache___getEndpointEffects, __getCacheState as cache___getCacheState, __isFresh as cache___isFresh, __cacheGet as cache___cacheGet, __cacheSet as cache___cacheSet, __evictOldest as cache___evictOldest, __overlaps as cache___overlaps, __invalidateEndpoint as cache___invalidateEndpoint, __cachedEndpointCall as cache___cachedEndpointCall, __invalidateEffects as cache___invalidateEffects, __jacClearCache as cache___jacClearCache } from "./endpoint_cache.js";
import { _jac } from "@jac/prelude";
class BridgeError extends _jac.exc.Exception {
  constructor(props = {}) {
    super(props);
    this.app = (Object.hasOwn(props, "app") ? props.app : "");
    this.name = (Object.hasOwn(props, "name") ? props.name : "");
    this.detail = (Object.hasOwn(props, "detail") ? props.detail : "");
    this.status = (Object.hasOwn(props, "status") ? props.status : 0);
    this.message = (Object.hasOwn(props, "message") ? props.message : "");
    this.__post_init__();
  }
  __post_init__() {
    this.message = this.detail;
  }
}
class BridgeUnavailable extends BridgeError {}
class BridgeTimeout extends BridgeError {}
class BridgeRejected extends BridgeError {}
function __bridgeErrorFor(status, message, app = "", name = "") {
  if ((((status === 401) || (status === 403)) || (status === 404))) {
    return new BridgeRejected({app: app, name: name, detail: message, status: status});
  }
  return new BridgeError({app: app, name: name, detail: message, status: status});
}
async function __fetchOrRaise(url, init, app, name) {
  try {
    return await fetch(url, init);
  } catch (__jac_e) {
    if (_jac.exc.matches(__jac_e, "Exception")) {
      let fetch_err = __jac_e;
      throw __bridgeErrorFromFetch(fetch_err, app, name);
    } else {
      throw __jac_e;
    }
  }
}
function __bridgeErrorFromFetch(err, app = "", name = "") {
  let message;
  if (_jac.builtin.isinstance(err, BridgeError)) {
    return err;
  }
  message = __errorMessage(err);
  if ((err && ((err.name === "AbortError") || (err.name === "TimeoutError")))) {
    return new BridgeTimeout({app: app, name: name, detail: message});
  }
  return new BridgeUnavailable({app: app, name: name, detail: message});
}
function __bridgeApiBase(opts = null) {
  let base_url;
  let route;
  base_url = __getApiBaseUrl();
  route = ((opts && opts["route"]) ? opts["route"] : "");
  if (route) {
    return `${base_url}${route}`;
  }
  return base_url;
}
function navigate(path) {
  window.history.pushState({}, "", path);
  window.dispatchEvent(Reflect.construct(PopStateEvent, ["popstate"]));
}
function __createJacSchema(zodLib) {
  let handler;
  let dummyFunc;
  handler = {"apply": (target, thisArg, argumentsList) => {
    return zodLib.object.apply(zodLib, argumentsList);
  }, "get": (target, prop, receiver) => {
    return _jac.poly.getitem(zodLib, prop);
  }};
  dummyFunc = schema => {
    return zodLib.object(schema);
  };
  return Reflect.construct(Proxy, [dummyFunc, handler]);
}
async function __jacSpawn(left, right = "", fields = {}, opts = null) {
  let app;
  let endpoint_key;
  let args_key;
  if (((((left === "login") || (left === "signup")) || (left === "logout")) || (left === "refresh_token"))) {
    return await __doWalkerFetch(left, right, fields, opts);
  }
  app = ((opts && opts["app"]) ? opts["app"] : "");
  endpoint_key = __endpointKey("walker", left, opts);
  args_key = `${endpoint_key}:${app}:${right}:${JSON.stringify(fields)}`;
  return await __cachedEndpointCall(endpoint_key, args_key, () => {
    return __doWalkerFetch(left, right, fields, opts);
  });
}
function jacSpawn(left, right = "", fields = {}, opts = null) {
  return __jacSpawn(left, right, fields, opts);
}
async function __jacCallFunction(function_name, args = {}, opts = null) {
  let app;
  let endpoint_key;
  let args_key;
  app = ((opts && opts["app"]) ? opts["app"] : "");
  endpoint_key = __endpointKey("func", function_name, opts);
  args_key = `${endpoint_key}:${app}:${JSON.stringify(args)}`;
  return await __cachedEndpointCall(endpoint_key, args_key, () => {
    return __doFuncFetch(function_name, args, opts);
  });
}
function __normalizeIdentity(x) {
  if (((x != null) && (Object.prototype.toString.call(x) === "[object Object]"))) {
    return x;
  }
  return {"type": "username", "value": x};
}
function __normalizeCredential(x) {
  if (((x != null) && (Object.prototype.toString.call(x) === "[object Object]"))) {
    return x;
  }
  return {"type": "password", "password": x};
}
function __errorMessage(err) {
  if ((err == null)) {
    return "";
  }
  if ((Object.prototype.toString.call(err) === "[object Object]")) {
    return (err["message"] ? err["message"] : "");
  }
  return String(err);
}
async function jacSignup(identities_or_username, credential_or_password, profile = null) {
  let base_url;
  let credential;
  let identities;
  let body;
  let response;
  let body_text;
  let user_id;
  let data;
  let candidate_id;
  let error_text;
  let error_data;
  let message;
  base_url = __getApiBaseUrl();
  credential = __normalizeCredential(credential_or_password);
  identities = (Array.isArray(identities_or_username) ? identities_or_username : [__normalizeIdentity(identities_or_username)]);
  body = {"identities": identities, "credential": credential};
  if ((profile != null)) {
    body["profile"] = profile;
  }
  response = await fetch(`${base_url}/user/register`, {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": JSON.stringify(body)});
  if (response.ok) {
    body_text = await response.text();
    user_id = "";
    try {
      data = JSON.parse(body_text);
      if ((data["data"] && data["data"]["user_id"])) {
        candidate_id = data["data"]["user_id"];
        if (!_jac.builtin.isinstance(candidate_id, _jac.types.str)) {
          return new SignupResult({success: false, error: "Signup response has an invalid user ID"});
        }
        user_id = candidate_id;
      }
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        let e = __jac_e;
        return new SignupResult({success: false, error: `Signup response was not valid JSON: ${e}`});
      } else {
        throw __jac_e;
      }
    }
    if (!user_id) {
      return new SignupResult({success: false, error: "Signup response is missing its user ID"});
    }
    return new SignupResult({success: true, user_id: user_id});
  } else {
    error_text = await response.text();
    try {
      error_data = JSON.parse(error_text);
      message = __errorMessage(error_data["error"]);
      return new SignupResult({success: false, error: (message || "Signup failed"), status: _jac.builtin.int(response.status)});
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        return new SignupResult({success: false, error: error_text, status: _jac.builtin.int(response.status)});
      } else {
        throw __jac_e;
      }
    }
  }
}
async function jacLogin(identity_or_username, credential_or_password) {
  let base_url;
  let identity;
  let credential;
  let response;
  let data;
  let token;
  base_url = __getApiBaseUrl();
  identity = __normalizeIdentity(identity_or_username);
  credential = __normalizeCredential(credential_or_password);
  response = await fetch(`${base_url}/user/login`, {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": JSON.stringify({"identity": identity, "credential": credential})});
  if (response.ok) {
    data = JSON.parse(await response.text());
    token = null;
    try {
      if ((data["data"] && data["data"]["token"])) {
        token = data["data"]["token"];
      }
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        let e = __jac_e;
        console.warn("Failed to extract login token:", e);
      } else {
        throw __jac_e;
      }
    }
    if (token) {
      jacSetToken(token);
      return true;
    }
  }
  return false;
}
function jacLogout() {
  let broker;
  __jacClearCache();
  __removeLocalStorage("jac_token");
  broker = __jacDesktopBroker();
  if (broker) {
    try {
      fetch(`${broker}/session`, {"method": "DELETE"}).catch(e => console.warn("[jac-client] broker session clear failed:", e));
    } catch (__jac_e) {
      if (true) {
        console.warn("[jac-client] broker session clear failed:", e);
      } else {
        throw __jac_e;
      }
    }
  }
}
function jacIsLoggedIn() {
  let token;
  token = __getLocalStorage("jac_token");
  return ((token != null) && (token !== ""));
}
async function jacSsoLogin(platform, api_base = "", operation = "login") {
  let base;
  let broker;
  let start_url;
  let started;
  let token;
  base = (api_base || __getApiBaseUrl());
  broker = __jacDesktopBroker();
  if (broker) {
    start_url = ((`${broker}/oauth/start?platform=${encodeURIComponent(platform)}` + `&operation=${encodeURIComponent(operation)}`) + `&api_base=${encodeURIComponent(base)}`);
    started = await fetch(start_url);
    if (!started.ok) {
      console.warn("[jac-client] oauth/start failed:", started.status);
      return false;
    }
    token = await __jacPollBrokerSession(broker, 300000, 1000);
    if (token) {
      jacSetToken(token);
      return true;
    }
    return false;
  }
  window.location.href = `${base}/sso/${encodeURIComponent(platform)}/${encodeURIComponent(operation)}`;
  return true;
}
function jacSetToken(token) {
  __jacClearCache();
  __setLocalStorage("jac_token", token);
}
function __jacClearCache() {
  cache___jacClearCache();
}
function __jacDesktopBroker() {
  let is_desktop;
  let broker;
  is_desktop = globalThis.__JAC_DESKTOP__;
  broker = globalThis.__JAC_BROKER__;
  if ((is_desktop && broker)) {
    return broker;
  }
  return "";
}
async function __jacPollBrokerSession(broker, timeout_ms, interval_ms) {
  let deadline;
  let resp;
  let data;
  let token;
  deadline = (Date.now() + timeout_ms);
  while ((Date.now() < deadline)) {
    try {
      resp = await fetch(`${broker}/session`);
      if (resp.ok) {
        data = await resp.json();
        token = (data["token"] || "");
        if (token) {
          return token;
        }
      }
    } catch (__jac_e) {
      if (true) {
        console.warn("[jac-client] session poll failed:", e);
      } else {
        throw __jac_e;
      }
    }
    await __jacSleep(interval_ms);
  }
  return "";
}
async function __jacSleep(ms) {
  await Reflect.construct(Promise, [resolve => setTimeout(resolve, ms)]);
}
function __getApiBaseUrl() {
  let base;
  base = globalThis.__JAC_API_BASE_URL__;
  return (base || "");
}
function __getLocalStorage(key) {
  let value;
  if (!globalThis.localStorage) {
    return "";
  }
  value = localStorage.getItem(key);
  return ((value != null) ? value : "");
}
function __setLocalStorage(key, value) {
  if (globalThis.localStorage) {
    localStorage.setItem(key, value);
  }
}
function __removeLocalStorage(key) {
  if (globalThis.localStorage) {
    localStorage.removeItem(key);
  }
}
function __getEndpointEffects() {
  return cache___getEndpointEffects();
}
function __getCacheState() {
  return cache___getCacheState();
}
function __isFresh(entry) {
  return cache___isFresh(entry);
}
function __cacheGet(key) {
  return cache___cacheGet(key);
}
function __cacheSet(key, data, ttl) {
  cache___cacheSet(key, data, ttl);
}
function __evictOldest() {
  cache___evictOldest();
}
async function __doWalkerFetch(walker, nodeId, fields, opts = null) {
  let app;
  let token;
  let base_url;
  let url;
  let headers;
  let response;
  let error_text;
  let walker_name;
  let payload;
  app = ((opts && opts["app"]) ? opts["app"] : "");
  token = __getLocalStorage("jac_token");
  base_url = __bridgeApiBase(opts);
  url = `${base_url}/walker/${walker}`;
  if ((nodeId !== "")) {
    url = `${base_url}/walker/${walker}/${nodeId}`;
  }
  headers = {"Content-Type": "application/json", "Accept": "application/json"};
  if ((opts && opts["contract"])) {
    headers["X-Jac-Endpoint"] = opts["contract"];
  }
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  response = await __fetchOrRaise(url, {"method": "POST", "headers": headers, "body": JSON.stringify(fields)}, app, walker);
  if (!response.ok) {
    if (((response.status === 401) && !app)) {
      __removeLocalStorage("jac_token");
      window.location.reload();
      return {};
    }
    error_text = await response.text();
    walker_name = (nodeId ? `${walker}/${nodeId}` : walker);
    throw __bridgeErrorFor(_jac.builtin.int(response.status), `Walker ${walker_name} failed: ${error_text}`, app, walker);
  }
  payload = await response.json();
  return (payload["data"] ? payload["data"] : {});
}
async function __doFuncFetch(function_name, args, opts = null) {
  let app;
  let token;
  let base_url;
  let headers;
  let response;
  let error_text;
  let payload;
  let error_msg;
  let result;
  app = ((opts && opts["app"]) ? opts["app"] : "");
  token = __getLocalStorage("jac_token");
  base_url = __bridgeApiBase(opts);
  headers = {"Content-Type": "application/json"};
  if ((opts && opts["contract"])) {
    headers["X-Jac-Endpoint"] = opts["contract"];
  }
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  response = await __fetchOrRaise(`${base_url}/function/${function_name}`, {"method": "POST", "headers": headers, "body": JSON.stringify(args)}, app, function_name);
  if (!response.ok) {
    if (((response.status === 401) && !app)) {
      __removeLocalStorage("jac_token");
      window.location.reload();
      return {};
    }
    error_text = await response.text();
    throw __bridgeErrorFor(_jac.builtin.int(response.status), `Function ${function_name} failed: ${error_text}`, app, function_name);
  }
  payload = await response.json();
  if (!payload["ok"]) {
    error_msg = (__errorMessage(payload["error"]) || "Unknown error");
    throw new BridgeError({app: app, name: function_name, detail: `Function ${function_name} failed: ${error_msg}`, status: _jac.builtin.int(response.status)});
  }
  result = null;
  try {
    if ((payload["data"] && _jac.poly.contains(payload["data"], "result"))) {
      result = payload["data"]["result"];
    }
  } catch (__jac_e) {
    if (_jac.exc.matches(__jac_e, "Exception")) {
      let e = __jac_e;
      console.warn(`Failed to extract result for ${function_name}:`, e);
    } else {
      throw __jac_e;
    }
  }
  return result;
}
async function __cachedEndpointCall(endpoint_key, args_key, fetch_fn) {
  return await cache___cachedEndpointCall(endpoint_key, args_key, fetch_fn);
}
function __invalidateEffects(writes) {
  cache___invalidateEffects(writes);
}
function __invalidateEndpoint(endpoint_key) {
  cache___invalidateEndpoint(endpoint_key);
}
function __overlaps(list1, list2) {
  return cache___overlaps(list1, list2);
}
function __jacReportError(message, stack = "", url = "", source = "", componentStack = "") {
  let baseUrl;
  try {
    baseUrl = __getApiBaseUrl();
    fetch(`${baseUrl}/cl/__error__`, {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": JSON.stringify({"message": message, "stack": stack, "url": (url || window.location.href), "source": source, "componentStack": componentStack, "timestamp": Reflect.construct(Date, []).toISOString()})});
  } catch (__jac_e) {
    if (_jac.exc.matches(__jac_e, "Exception")) {} else {
      throw __jac_e;
    }
  }
}
function __jacInstallErrorHandlers() {
  let installed;
  installed = globalThis.__jacErrorHandlersInstalled;
  if (installed) {
    return;
  }
  globalThis["__jacErrorHandlersInstalled"] = true;
  window.addEventListener("error", event => __jacReportError((event.message || "Unknown error"), (event.error ? event.error.stack : ""), (event.filename || ""), "window.onerror"));
  window.addEventListener("unhandledrejection", event => {
    let reason = event.reason;
    let message = "";
    let stack = "";
    if (reason) {
      message = (reason.message || String(reason));
      stack = (reason.stack || "");
    } else {
      message = "Unhandled promise rejection";
    }
    __jacReportError(message, stack, "", "unhandledrejection");
  });
}
function ErrorFallback(props) {
  const {error, resetErrorBoundary} = props;
  return __jacJsx("div", {"role": "alert", "style": {minHeight: "100vh", display: "flex", justifyContent: "center", alignItems: "center", backgroundColor: "#f9fafb", fontFamily: "system-ui, sans-serif"}}, [__jacJsx("div", {"role": "alert", "style": {minHeight: "100vh", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", backgroundColor: "#f9fafb", fontFamily: "system-ui, sans-serif"}}, [__jacJsx("h2", {"style": {color: "#dc2626", marginBottom: "12px"}}, ["🚨 Something went wrong"]), __jacJsx("p", {"style": {color: "#374151", marginBottom: "16px"}}, ["An unexpected error occurred. Please try again."]), __jacJsx("pre", {"style": {color: "#991b1b", background: "#fee2e2", padding: "12px", borderRadius: "8px", fontSize: "14px", overflowX: "auto", marginBottom: "16px"}}, [error.message]), __jacJsx("button", {"onClick": () => resetErrorBoundary(), "style": {backgroundColor: "#2563eb", color: "#fff", padding: "10px 16px", borderRadius: "8px", border: "none", cursor: "pointer", fontSize: "14px"}}, ["🔄 Try again"])])]);
}
function ErrorOverlay(props) {
  const {filePath, errors} = props;
  return __jacJsx("div", {"style": {position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "rgba(0, 0, 0, 0.85)", color: "#fff", fontFamily: "'Monaco', 'Menlo', 'Ubuntu Mono', monospace", fontSize: 14, zIndex: 999999, overflow: "auto", padding: 20, boxSizing: "border-box"}}, [__jacJsx("div", {"style": {maxWidth: 1200, margin: "0 auto"}}, [__jacJsx("div", {"style": {background: "#d32f2f", color: "white", padding: "16px 24px", borderRadius: "8px 8px 0 0", fontSize: 18, fontWeight: "bold"}}, ["⚠️ Compilation Error"]), __jacJsx("div", {"style": {background: "#1e1e1e", padding: 24, borderRadius: "0 0 8px 8px"}}, [__jacJsx("div", {"style": {marginBottom: 16}}, [__jacJsx("div", {"style": {color: "#888", marginBottom: 8}}, ["File:"]), __jacJsx("div", {"style": {color: "#64b5f6", fontWeight: "bold"}}, [filePath])]), __jacJsx("div", {}, [__jacJsx("div", {"style": {color: "#888", marginBottom: 8}}, ["Error:"]), __jacJsx("pre", {"style": {background: "#2d2d2d", padding: 16, borderRadius: 4, overflowX: "auto", margin: 0, borderLeft: "4px solid #d32f2f", lineHeight: 1.6, color: "#ff6b6b"}}, [errors])]), __jacJsx("div", {"style": {marginTop: 24, paddingTop: 16, borderTop: "1px solid #444", color: "#888", fontSize: 13}}, ["💡 Fix the error and save the file to continue development."])])])]);
}
const errorOverlay = ErrorOverlay;
function __jacReactErrorHandler(error, info) {
  let message;
  let stack;
  let componentStack;
  try {
    message = (error ? error.message : "Unknown error");
    stack = (error ? error.stack : "");
    componentStack = (info ? info.componentStack : "");
    __jacReportError(message, stack, "", "ErrorBoundary", componentStack);
  } catch (__jac_e) {
    if (_jac.exc.matches(__jac_e, "Exception")) {} else {
      throw __jac_e;
    }
  }
}
function __unwrapFormSchema(schema) {
  let actualSchema;
  actualSchema = schema;
  try {
    if (!schema.shape) {
      if ((schema._def && schema._def.schema)) {
        actualSchema = schema._def.schema;
      } else if ((schema.def && schema.def.schema)) {
        actualSchema = schema.def.schema;
      }
    }
  } catch (__jac_e) {
    if (_jac.exc.matches(__jac_e, "Exception")) {
      let e = __jac_e;
      console.warn("Failed to unwrap schema:", e);
    } else {
      throw __jac_e;
    }
  }
  return actualSchema;
}
export {BridgeError, BridgeRejected, BridgeTimeout, BridgeUnavailable, ErrorFallback, __bridgeApiBase, __bridgeErrorFor, __bridgeErrorFromFetch, __cacheGet, __cacheSet, __cachedEndpointCall, __createJacSchema, __doFuncFetch, __doWalkerFetch, __errorMessage, __evictOldest, __getApiBaseUrl, __getCacheState, __getEndpointEffects, __getLocalStorage, __invalidateEffects, __invalidateEndpoint, __isFresh, __jacCallFunction, __jacClearCache, __jacDesktopBroker, __jacInstallErrorHandlers, __jacPollBrokerSession, __jacReactErrorHandler, __jacReportError, __jacSleep, __jacSpawn, __normalizeCredential, __normalizeIdentity, __overlaps, __removeLocalStorage, __setLocalStorage, __unwrapFormSchema, errorOverlay, jacIsLoggedIn, jacLogin, jacLogout, jacSetToken, jacSignup, jacSpawn, jacSsoLogin, navigate};
//# sourceMappingURL=client_runtime_core.js.map
