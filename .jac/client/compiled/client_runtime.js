import "./auth_contract.js";
import * as React from "react";
import { useState as reactUseState, useEffect as reactUseEffect, useRef as reactUseRef, useSyncExternalStore as reactUseSyncExternalStore } from "react";
import { BrowserRouter as ReactRouterBrowserRouter, Routes as ReactRouterRoutes, Route as ReactRouterRoute, Link as ReactRouterLink, Navigate as ReactRouterNavigate, Outlet as ReactRouterOutlet, useNavigate as reactRouterUseNavigate, useLocation as reactRouterUseLocation, useParams as reactRouterUseParams } from "react-router-dom";
import { ErrorBoundary } from "react-error-boundary";
import { useForm } from "@tanstack/react-form";
import { z } from "zod";
import { BridgeError as _BridgeError, BridgeUnavailable as _BridgeUnavailable, BridgeTimeout as _BridgeTimeout, BridgeRejected as _BridgeRejected, __bridgeErrorFor as ___bridgeErrorFor, __bridgeErrorFromFetch as ___bridgeErrorFromFetch, __bridgeApiBase as ___bridgeApiBase, navigate as _navigate, __createJacSchema as ___createJacSchema, __jacSpawn as ___jacSpawn, jacSpawn as _jacSpawn, __jacCallFunction as ___jacCallFunction, __normalizeIdentity as ___normalizeIdentity, __normalizeCredential as ___normalizeCredential, jacSignup as _jacSignup, jacLogin as _jacLogin, jacLogout as _jacLogout, jacIsLoggedIn as _jacIsLoggedIn, jacSsoLogin as _jacSsoLogin, jacSetToken as _jacSetToken, __jacClearCache as ___jacClearCache, __jacDesktopBroker as ___jacDesktopBroker, __jacPollBrokerSession as ___jacPollBrokerSession, __jacSleep as ___jacSleep, __getApiBaseUrl as ___getApiBaseUrl, __getLocalStorage as ___getLocalStorage, __setLocalStorage as ___setLocalStorage, __removeLocalStorage as ___removeLocalStorage, __getEndpointEffects as ___getEndpointEffects, __getCacheState as ___getCacheState, __isFresh as ___isFresh, __cacheGet as ___cacheGet, __cacheSet as ___cacheSet, __evictOldest as ___evictOldest, __doWalkerFetch as ___doWalkerFetch, __doFuncFetch as ___doFuncFetch, __cachedEndpointCall as ___cachedEndpointCall, __invalidateEndpoint as ___invalidateEndpoint, __overlaps as ___overlaps, __jacReportError as ___jacReportError, __jacInstallErrorHandlers as ___jacInstallErrorHandlers, ErrorFallback as ___ErrorFallback, errorOverlay as ___errorOverlay, __jacReactErrorHandler as ___jacReactErrorHandler, __unwrapFormSchema as ___unwrapFormSchema } from "./client_runtime_core.js";
import { _jac } from "@jac/prelude";
let BridgeError = _BridgeError;
let BridgeUnavailable = _BridgeUnavailable;
let BridgeTimeout = _BridgeTimeout;
let BridgeRejected = _BridgeRejected;
let __bridgeErrorFor = ___bridgeErrorFor;
let __bridgeErrorFromFetch = ___bridgeErrorFromFetch;
let __bridgeApiBase = ___bridgeApiBase;
let __createJacSchema = ___createJacSchema;
let __jacSpawn = ___jacSpawn;
let __jacCallFunction = ___jacCallFunction;
let __normalizeIdentity = ___normalizeIdentity;
let __normalizeCredential = ___normalizeCredential;
let __jacClearCache = ___jacClearCache;
let __jacDesktopBroker = ___jacDesktopBroker;
let __jacPollBrokerSession = ___jacPollBrokerSession;
let __jacSleep = ___jacSleep;
let __getApiBaseUrl = ___getApiBaseUrl;
let __getLocalStorage = ___getLocalStorage;
let __setLocalStorage = ___setLocalStorage;
let __removeLocalStorage = ___removeLocalStorage;
let __getEndpointEffects = ___getEndpointEffects;
let __getCacheState = ___getCacheState;
let __isFresh = ___isFresh;
let __cacheGet = ___cacheGet;
let __cacheSet = ___cacheSet;
let __evictOldest = ___evictOldest;
let __doWalkerFetch = ___doWalkerFetch;
let __doFuncFetch = ___doFuncFetch;
let __cachedEndpointCall = ___cachedEndpointCall;
let __invalidateEndpoint = ___invalidateEndpoint;
let __overlaps = ___overlaps;
let __jacReportError = ___jacReportError;
let __jacInstallErrorHandlers = ___jacInstallErrorHandlers;
let ErrorFallback = ___ErrorFallback;
let errorOverlay = ___errorOverlay;
let __jacReactErrorHandler = ___jacReactErrorHandler;
let __unwrapFormSchema = ___unwrapFormSchema;
function navigate(path) {
  _navigate(path);
}
function jacSpawn(left, right = "", fields = {}) {
  return _jacSpawn(left, right, fields);
}
async function jacSignup(identities_or_username, credential_or_password, profile = null) {
  return await _jacSignup(identities_or_username, credential_or_password, profile);
}
async function jacLogin(identity_or_username, credential_or_password) {
  return await _jacLogin(identity_or_username, credential_or_password);
}
function jacLogout() {
  _jacLogout();
}
function jacIsLoggedIn() {
  return _jacIsLoggedIn();
}
async function jacSsoLogin(platform, api_base = "", operation = "login") {
  return await _jacSsoLogin(platform, api_base, operation);
}
function jacSetToken(token) {
  _jacSetToken(token);
}
function __jacJsx(tag, props = {}, children = []) {
  let childrenArray;
  let reactChildren;
  let args;
  if ((tag == null)) {
    tag = React.Fragment;
  }
  childrenArray = [];
  if ((children != null)) {
    if (Array.isArray(children)) {
      childrenArray = children;
    } else {
      childrenArray = [children];
    }
  }
  reactChildren = [];
  for (const child of childrenArray) {
    if (((child == null) || (child === undefined))) {
      continue;
    }
    if ((child.__jacUnsafeHtml !== undefined)) {
      reactChildren.push(React.createElement("span", {"dangerouslySetInnerHTML": {"__html": child.__jacUnsafeHtml}}));
    } else {
      reactChildren.push(child);
    }
  }
  if ((reactChildren.length > 0)) {
    args = [tag, props];
    for (const child of reactChildren) {
      args.push(child);
    }
    return React.createElement.apply(React, args);
  } else {
    return React.createElement(tag, props);
  }
}
function useJacState(initial) {
  let ref;
  let cell;
  let store;
  ref = reactUseRef(null);
  if ((ref.current == null)) {
    cell = {"val": initial, "version": 0, "listeners": []};
    cell["subscribe"] = cb => {
      _jac.poly.call(cell["listeners"], "append", cb);
      return () => {
        let idx = cell["listeners"].indexOf(cb);
        if ((idx > (-1))) {
          cell["listeners"].splice(idx, 1);
        }
      };
    };
    cell["getVersion"] = () => {
      return cell["version"];
    };
    cell["set"] = v => {
      if (Object.is(cell["val"], v)) {
        return;
      }
      cell["val"] = v;
      cell["version"] = (cell["version"] + 1);
      for (const cb of _jac.builtin.iter(cell["listeners"].slice())) {
        cb();
      }
    };
    ref.current = cell;
  }
  store = ref.current;
  reactUseSyncExternalStore(store["subscribe"], store["getVersion"]);
  return store;
}
let useState = reactUseState;
let useEffect = reactUseEffect;
let Router = ReactRouterBrowserRouter;
let Routes = ReactRouterRoutes;
let Route = ReactRouterRoute;
let Link = ReactRouterLink;
let Navigate = ReactRouterNavigate;
let useNavigate = reactRouterUseNavigate;
let useLocation = reactRouterUseLocation;
let useParams = reactRouterUseParams;
let Outlet = ReactRouterOutlet;
let JacClientErrorBoundary = ErrorBoundary;
let JacSchema = __createJacSchema(z);
function useRouter() {
  let navigate;
  let location;
  let params;
  navigate = reactRouterUseNavigate();
  location = reactRouterUseLocation();
  params = reactRouterUseParams();
  return {"navigate": navigate, "location": location, "params": params, "pathname": location.pathname, "search": location.search, "hash": location.hash};
}
function AuthGuard(props) {
  const {redirect: redirect = "/login", children: children = null} = props;
  if (!jacIsLoggedIn()) {
    return __jacJsx(ReactRouterNavigate, {"to": redirect, "replace": true}, []);
  }
  if ((children != null)) {
    return __jacJsx(null, {}, [children]);
  }
  return __jacJsx(ReactRouterOutlet, {}, []);
}
function JacAwaiting(props) {
  return React.createElement(React.Suspense, {"fallback": props["fallback"]}, props["children"]);
}
function useJacForm(form_mode = "onTouched", schema, onSubmit = null) {
  let actualSchema;
  let schemaShape;
  let defaults;
  let validators;
  let opts;
  actualSchema = __unwrapFormSchema(schema);
  schemaShape = (actualSchema.shape || {});
  defaults = {};
  for (const key of _jac.poly.call(Object, "keys", schemaShape)) {
    defaults[key] = "";
  }
  validators = {};
  if ((form_mode === "onChange")) {
    validators["onChange"] = schema;
  } else if ((form_mode === "onSubmit")) {
    validators["onSubmit"] = schema;
  } else if ((form_mode === "onBlur")) {
    validators["onBlur"] = schema;
  } else if ((form_mode === "onTouched")) {
    validators["onChange"] = schema;
  } else {
    console.warn(`Unknown validateMode '${form_mode}'; falling back to onBlur`);
    validators["onBlur"] = schema;
  }
  opts = {"defaultValues": defaults, "validators": validators};
  if (onSubmit) {
    opts["onSubmit"] = args => {
      return onSubmit(args.value);
    };
  }
  return useForm(opts);
}
function JacForm(props) {
  let schema;
  let onSubmit;
  let layout;
  let field_config;
  let submitLabel;
  let submitClassName;
  let gridColumns;
  let validateMode;
  let className;
  let actualSchema;
  let schemaShape;
  let fieldNames;
  let form;
  let passwordVisible;
  let setPasswordVisible;
  let fields;
  let layoutStyle;
  let formClassName;
  let buttonClassName;
  schema = props["schema"];
  onSubmit = props["onSubmit"];
  layout = (props["layout"] || "vertical");
  field_config = (props["field_config"] || {});
  submitLabel = (props["submitLabel"] || "Submit");
  submitClassName = (props["submitClassName"] || "");
  gridColumns = (props["gridColumns"] || 2);
  validateMode = (props["validateMode"] || "onTouched");
  className = (props["className"] || "");
  actualSchema = __unwrapFormSchema(schema);
  schemaShape = (actualSchema.shape || {});
  fieldNames = _jac.poly.call(Object, "keys", schemaShape);
  form = useJacForm(validateMode, schema, onSubmit);
  [passwordVisible, setPasswordVisible] = useState({});
  function unwrapZodSchema(schema, depth = 0) {
    let maxDepth = 10;
    if ((depth >= maxDepth)) {
      return schema;
    }
    try {
      if (schema.unwrap) {
        return unwrapZodSchema(schema.unwrap(), (depth + 1));
      }
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {} else {
        throw __jac_e;
      }
    }
    if (!schema._def) {
      return schema;
    }
    let typeValue = schema._def.type;
    if (((typeValue === "optional") && schema._def.innerType)) {
      return unwrapZodSchema(schema._def.innerType, (depth + 1));
    }
    if (((typeValue === "default") && schema._def.innerType)) {
      return unwrapZodSchema(schema._def.innerType, (depth + 1));
    }
    if ((schema._def.checks && schema._def.schema)) {
      return unwrapZodSchema(schema._def.schema, (depth + 1));
    }
    return schema;
  }
  function RenderError(props) {
    const {errors, isTouched} = props;
    if (((validateMode === "onTouched") && !isTouched)) {
      return null;
    }
    if ((!_jac.builtin.bool(errors) || (errors.length === 0))) {
      return null;
    }
    return __jacJsx("p", {"style": {color: "#ef4444", fontSize: "0.85rem", marginTop: "0.25rem"}}, ["⚠️", errors[0].message]);
  }
  const renderError = RenderError;
  function getEnumOptions(fieldSchema) {
    let unwrapped = unwrapZodSchema(fieldSchema);
    if ((unwrapped.options && Array.isArray(unwrapped.options))) {
      return unwrapped.options;
    }
    if (unwrapped.enum) {
      return _jac.poly.call(Object, "keys", unwrapped.enum);
    }
    if ((unwrapped._def && unwrapped._def.entries)) {
      return _jac.poly.call(Object, "keys", unwrapped._def.entries);
    }
    if ((unwrapped.def && unwrapped.def.entries)) {
      return _jac.poly.call(Object, "keys", unwrapped.def.entries);
    }
    return [];
  }
  function RenderInput(props) {
    const {fieldType, field, config, fieldSchema, fieldName} = props;
    let options;
    let rows;
    let isVisible;
    let inputClassName = (config["inputClassName"] || "");
    let labelClassName = (config["labelClassName"] || "");
    let placeholder = (config["placeholder"] || "");
    let label = (config["label"] || fieldName);
    let hasError = ((field.state.meta.errors && field.state.meta.errors.length) && ((validateMode !== "onTouched") || field.state.meta.isTouched));
    if ((fieldType === "checkbox")) {
      return __jacJsx("label", {"style": {cursor: "pointer", display: "flex", alignItems: "center", gap: "0.5rem"}}, [__jacJsx("input", {"type": "checkbox", "name": fieldName, "checked": (field.state.value || false), "onChange": e => field.handleChange(e.target.checked), "onBlur": field.handleBlur, "className": inputClassName, "style": {cursor: "pointer"}}, []), __jacJsx("span", {"className": labelClassName}, [label])]);
    }
    if ((fieldType === "select")) {
      options = getEnumOptions(fieldSchema);
      return __jacJsx("select", {"name": fieldName, "value": (field.state.value || ""), "onChange": e => field.handleChange(e.target.value), "onBlur": field.handleBlur, "className": inputClassName, "style": {width: "100%", boxSizing: "border-box"}}, [__jacJsx("option", {"value": ""}, [(placeholder || `Select ${label}`)]), options.map(opt => __jacJsx("option", {"value": opt, "key": opt}, [opt]))]);
    }
    if ((fieldType === "radio")) {
      options = getEnumOptions(fieldSchema);
      return __jacJsx("div", {"style": {display: "flex", flexDirection: "column", gap: "0.5rem"}}, [options.map(opt => __jacJsx("label", {"key": opt, "style": {cursor: "pointer", display: "flex", alignItems: "center", gap: "0.5rem"}}, [__jacJsx("input", {"type": "radio", "name": fieldName, "value": opt, "checked": (field.state.value === opt), "onChange": e => field.handleChange(e.target.value), "onBlur": field.handleBlur, "className": inputClassName, "style": {cursor: "pointer"}}, []), __jacJsx("span", {}, [opt])]))]);
    }
    if ((fieldType === "textarea")) {
      rows = (config["rows"] || 4);
      return __jacJsx("textarea", {"name": fieldName, "placeholder": placeholder, "rows": rows, "value": field.state.value, "onChange": e => field.handleChange(e.target.value), "onBlur": field.handleBlur, "className": inputClassName, "style": {width: "100%", boxSizing: "border-box", border: (hasError ? "2px solid #ef4444" : "2px solid #e5e7eb"), padding: "0.5rem", fontFamily: "inherit", fontSize: "inherit", resize: "vertical"}}, []);
    }
    if (((fieldType === "password") && config["showPasswordToggle"])) {
      isVisible = _jac.builtin.bool(_jac.poly.getitem(passwordVisible, fieldName));
      return __jacJsx("div", {}, [__jacJsx("div", {"style": {position: "relative"}}, [__jacJsx("input", {"type": (isVisible ? "text" : "password"), "name": fieldName, "placeholder": placeholder, "value": field.state.value, "onChange": e => field.handleChange(e.target.value), "onBlur": field.handleBlur, "className": inputClassName, "style": {width: "100%", boxSizing: "border-box", border: (hasError ? "2px solid #ef4444" : "2px solid #e5e7eb"), paddingRight: "2.5rem"}}, [])]), __jacJsx("label", {"style": {cursor: "pointer", display: "flex", alignItems: "center", gap: "0.5rem", marginTop: "0.5rem", fontSize: "0.875rem", color: "#6b7280"}}, [__jacJsx("input", {"type": "checkbox", "checked": isVisible, "onChange": e => setPasswordVisible(prev => {
        let newState = {};
        Object.assign(newState, prev);
        newState[fieldName] = !isVisible;
        return newState;
      }), "style": {cursor: "pointer"}}, []), __jacJsx("span", {}, ["Show password"])])]);
    }
    return __jacJsx("input", {"type": fieldType, "name": fieldName, "placeholder": placeholder, "value": field.state.value, "onChange": e => field.handleChange(((fieldType === "number") ? parseFloat(e.target.value) : e.target.value)), "onBlur": field.handleBlur, "className": inputClassName, "style": {width: "100%", boxSizing: "border-box", border: (hasError ? "2px solid #ef4444" : "2px solid #e5e7eb")}}, []);
  }
  const renderInput = RenderInput;
  function RenderField(props) {
    const {fieldName} = props;
    let fieldSchema = schemaShape[fieldName];
    let config = (field_config[fieldName] ? field_config[fieldName] : {});
    let fieldType = (config["type"] || "text");
    let label = (config["label"] || fieldName);
    let fieldClassName = (config["className"] || "");
    let labelClassName = (config["labelClassName"] || "");
    return __jacJsx(form.Field, {"name": fieldName, "key": fieldName}, [field => {
      return __jacJsx("div", {"className": fieldClassName, "style": {marginBottom: "1rem"}}, [__jacJsx("label", {"className": labelClassName, "style": {display: "block", marginBottom: "0.5rem"}}, [label]), renderInput({fieldType: fieldType, field: field, config: config, fieldSchema: fieldSchema, fieldName: fieldName}), renderError({errors: field.state.meta.errors, isTouched: field.state.meta.isTouched})]);
    }]);
  }
  const renderField = RenderField;
  function getLayoutStyle() {
    if ((layout === "grid")) {
      return {display: "grid", gridTemplateColumns: `repeat(${gridColumns}, 1fr)`, gap: "1rem"};
    } else if ((layout === "horizontal")) {
      return {display: "flex", gap: "1rem", flexWrap: "wrap", alignItems: "flex-start"};
    } else if ((layout === "inline")) {
      return {display: "flex", gap: "0.5rem", alignItems: "flex-end"};
    } else {
      return {};
    }
  }
  fields = [];
  for (const fieldName of fieldNames) {
    fields.push(renderField({fieldName: fieldName}));
  }
  layoutStyle = getLayoutStyle();
  formClassName = (className || "");
  buttonClassName = (submitClassName || "");
  return __jacJsx("form", {"onSubmit": e => {
    e.preventDefault();
    e.stopPropagation();
    form.handleSubmit();
  }, "className": formClassName}, [__jacJsx("div", {"style": layoutStyle}, [fields]), __jacJsx(form.Subscribe, {"selector": s => {
    return {isDirty: s.isDirty, isValid: s.isValid, isTouched: s.isTouched, isSubmitting: s.isSubmitting};
  }}, [fs => {
    let btnEffectiveIsValid = (((validateMode === "onTouched") && !fs.isTouched) ? true : fs.isValid);
    let btnDisabled = ((fs.isSubmitting || !fs.isDirty) || !btnEffectiveIsValid);
    return __jacJsx("button", {"type": "submit", "disabled": btnDisabled, "className": buttonClassName, "style": {width: "100%", cursor: (btnDisabled ? "not-allowed" : "pointer")}}, [(fs.isSubmitting && "Submitting..."), (!fs.isSubmitting && submitLabel)]);
  }])]);
}
export {AuthGuard, BridgeError, BridgeRejected, BridgeTimeout, BridgeUnavailable, ErrorFallback, JacAwaiting, JacClientErrorBoundary, JacForm, JacSchema, Link, Navigate, Outlet, Route, Router, Routes, __bridgeApiBase, __bridgeErrorFor, __bridgeErrorFromFetch, __cacheGet, __cacheSet, __cachedEndpointCall, __createJacSchema, __doFuncFetch, __doWalkerFetch, __evictOldest, __getApiBaseUrl, __getCacheState, __getEndpointEffects, __getLocalStorage, __invalidateEndpoint, __isFresh, __jacCallFunction, __jacClearCache, __jacDesktopBroker, __jacInstallErrorHandlers, __jacJsx, __jacPollBrokerSession, __jacReactErrorHandler, __jacReportError, __jacSleep, __jacSpawn, __normalizeCredential, __normalizeIdentity, __overlaps, __removeLocalStorage, __setLocalStorage, __unwrapFormSchema, errorOverlay, jacIsLoggedIn, jacLogin, jacLogout, jacSetToken, jacSignup, jacSpawn, jacSsoLogin, navigate, useEffect, useJacForm, useJacState, useLocation, useNavigate, useParams, useRouter, useState};
//# sourceMappingURL=client_runtime.js.map
