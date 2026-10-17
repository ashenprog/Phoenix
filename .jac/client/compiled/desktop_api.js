import { _jac } from "@jac/prelude";
async function _invoke(plugin, command, args) {
  let resp;
  let raw;
  let parsed;
  let msg;
  let broker = globalThis.__JAC_BROKER__;
  if (broker) {
    resp = await fetch(`${broker}/invoke`, {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": JSON.stringify([plugin, command, args])});
    raw = await resp.text();
    parsed = JSON.parse(raw);
    if (parsed["ok"]) {
      return parsed["data"];
    }
    msg = "desktop invoke failed";
    try {
      msg = String(parsed["error"]["message"]);
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {} else {
        throw __jac_e;
      }
    }
    throw new _jac.exc.Exception(msg);
  }
  if ((globalThis.__jac && globalThis.__jac.invoke)) {
    return await globalThis.__jac.invoke(plugin, command, args);
  }
  throw new _jac.exc.Exception("@jac/desktop: no broker (/__jac) and window.__jac.invoke is missing");
}
class fs {
  static async read_file(path, encoding = "utf-8") {
    let r = await _invoke("jac.fs", "read_file", {"path": path, "encoding": encoding});
    return r["content"];
  }
  static async write_file(path, content) {
    await _invoke("jac.fs", "write_file", {"path": path, "content": content});
  }
  static async list_dir(path) {
    let r = await _invoke("jac.fs", "list_dir", {"path": path});
    return r["entries"];
  }
  static async exists(path) {
    let r = await _invoke("jac.fs", "exists", {"path": path});
    return r["exists"];
  }
  static async mkdir(path) {
    await _invoke("jac.fs", "mkdir", {"path": path});
  }
  static async remove(path) {
    await _invoke("jac.fs", "remove", {"path": path});
  }
  static async stat(path) {
    return await _invoke("jac.fs", "stat", {"path": path});
  }
}
class dialog {
  static async open_file(title = "Open File") {
    return await _invoke("jac.dialog", "open_file", {"title": title});
  }
  static async save_file(title = "Save File", default_name = "") {
    return await _invoke("jac.dialog", "save_file", {"title": title, "default_name": default_name});
  }
  static async message(title, body, kind = "info") {
    await _invoke("jac.dialog", "message", {"title": title, "body": body, "kind": kind});
  }
}
class clipboard {
  static async read() {
    let r = await _invoke("jac.clipboard", "read", {});
    return r["text"];
  }
  static async write(text) {
    await _invoke("jac.clipboard", "write", {"text": text});
  }
}
class notification {
  static async send(title, body = "") {
    await _invoke("jac.notification", "send", {"title": title, "body": body});
  }
}
class app_window {
  static async set_title(title) {
    await _invoke("jac.window", "set_title", {"title": title});
  }
  static async set_size(width, height, hint = 0) {
    await _invoke("jac.window", "set_size", {"width": width, "height": height, "hint": hint});
  }
  static async fullscreen() {
    await _invoke("jac.window", "fullscreen", {});
  }
  static async terminate() {
    await _invoke("jac.window", "terminate", {});
  }
}
class shell {
  static async exec(command, timeout = 30, cwd = "") {
    let args = {"command": command, "timeout": timeout};
    if (cwd) {
      args["cwd"] = cwd;
    }
    return await _invoke("jac.shell", "exec", args);
  }
}
class path {
  static async home() {
    let r = await _invoke("jac.path", "home", {});
    return r["path"];
  }
  static async data() {
    let r = await _invoke("jac.path", "data", {});
    return r["path"];
  }
  static async config() {
    let r = await _invoke("jac.path", "config", {});
    return r["path"];
  }
  static async cache() {
    let r = await _invoke("jac.path", "cache", {});
    return r["path"];
  }
  static async temp() {
    let r = await _invoke("jac.path", "temp", {});
    return r["path"];
  }
  static async resolve(p) {
    let r = await _invoke("jac.path", "resolve", {"path": p});
    return r["path"];
  }
}
export {app_window, clipboard, dialog, fs, notification, path, shell};

//# sourceMappingURL=desktop_api.js.map
