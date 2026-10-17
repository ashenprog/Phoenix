/* Source: /mnt/c/Users/User/Documents/My Projects/JAC/api.jac */
import { _jac } from "@jac/prelude";
class HealthStatus {
  constructor(props = {}) {
    this.ok = (Object.hasOwn(props, "ok") ? props.ok : null);
    this.service = (Object.hasOwn(props, "service") ? props.service : null);
  }
}
class Health {
  constructor(props = {}) {
    this.reports = (Object.hasOwn(props, "reports") ? props.reports : []);
  }
  check(__other) {
    const here = __other;
    const visitor = this;
    __ospC.osp_report(new HealthStatus({ok: true, service: "phoenix"}));
  }
}
let UNTYPED = (-1);
class OspSlot {
  constructor(props = {}) {
    this.trig_tag = (Object.hasOwn(props, "trig_tag") ? props.trig_tag : null);
    this.fn = (Object.hasOwn(props, "fn") ? props.fn : null);
  }
}
class OspPlan {
  constructor(props = {}) {
    this.ctag = (Object.hasOwn(props, "ctag") ? props.ctag : null);
    this.w_entry = (Object.hasOwn(props, "w_entry") ? props.w_entry : null);
    this.n_entry_u = (Object.hasOwn(props, "n_entry_u") ? props.n_entry_u : null);
    this.n_entry_t = (Object.hasOwn(props, "n_entry_t") ? props.n_entry_t : null);
    this.n_exit_t = (Object.hasOwn(props, "n_exit_t") ? props.n_exit_t : null);
    this.n_exit_u = (Object.hasOwn(props, "n_exit_u") ? props.n_exit_u : null);
    this.w_exit = (Object.hasOwn(props, "w_exit") ? props.w_exit : null);
  }
}
class OspWalkerDesc {
  constructor(props = {}) {
    this.type_tag = (Object.hasOwn(props, "type_tag") ? props.type_tag : null);
    this.entry = (Object.hasOwn(props, "entry") ? props.entry : null);
    this.exit = (Object.hasOwn(props, "exit") ? props.exit : null);
    this.plans = (Object.hasOwn(props, "plans") ? props.plans : null);
  }
}
class OspNodeDesc {
  constructor(props = {}) {
    this.type_tag = (Object.hasOwn(props, "type_tag") ? props.type_tag : null);
    this.entry = (Object.hasOwn(props, "entry") ? props.entry : null);
    this.exit = (Object.hasOwn(props, "exit") ? props.exit : null);
  }
}
class OspFrame {
  constructor(props = {}) {
    this.loc = (Object.hasOwn(props, "loc") ? props.loc : null);
    this.phase = (Object.hasOwn(props, "phase") ? props.phase : 0);
    this.band = (Object.hasOwn(props, "band") ? props.band : 0);
    this.idx = (Object.hasOwn(props, "idx") ? props.idx : 0);
    this.budget = (Object.hasOwn(props, "budget") ? props.budget : 0);
    this.plan = (Object.hasOwn(props, "plan") ? props.plan : null);
  }
}
class OspWalkScope {
  constructor(props = {}) {
    this.wlk = (Object.hasOwn(props, "wlk") ? props.wlk : null);
    this.path = (Object.hasOwn(props, "path") ? props.path : null);
    this.next = (Object.hasOwn(props, "next") ? props.next : null);
    this.front = (Object.hasOwn(props, "front") ? props.front : null);
    this.ignores = (Object.hasOwn(props, "ignores") ? props.ignores : null);
    this.reports = (Object.hasOwn(props, "reports") ? props.reports : null);
    this.disengaged = (Object.hasOwn(props, "disengaged") ? props.disengaged : false);
    this.next_head = (Object.hasOwn(props, "next_head") ? props.next_head : 0);
    this.nested = (Object.hasOwn(props, "nested") ? props.nested : false);
    this.fenced = (Object.hasOwn(props, "fenced") ? props.fenced : false);
    this.pending_fence = (Object.hasOwn(props, "pending_fence") ? props.pending_fence : 0);
    this.skip_node = (Object.hasOwn(props, "skip_node") ? props.skip_node : false);
    this.stage = (Object.hasOwn(props, "stage") ? props.stage : 0);
    this.sidx = (Object.hasOwn(props, "sidx") ? props.sidx : 0);
    this.frames = (Object.hasOwn(props, "frames") ? props.frames : null);
    this.cur_a = (Object.hasOwn(props, "cur_a") ? props.cur_a : null);
    this.cur_b = (Object.hasOwn(props, "cur_b") ? props.cur_b : null);
    this.held = (Object.hasOwn(props, "held") ? props.held : []);
  }
}
class OspRuntime {
  constructor(props = {}) {
    this.tag_of = (Object.hasOwn(props, "tag_of") ? props.tag_of : null);
    this.is_a = (Object.hasOwn(props, "is_a") ? props.is_a : null);
    this.node_desc = (Object.hasOwn(props, "node_desc") ? props.node_desc : null);
    this.on_complete = (Object.hasOwn(props, "on_complete") ? props.on_complete : null);
  }
}
let _descs = {};
function osp_register_desc(tag, desc) {
  _descs[tag] = desc;
}
function osp_has_desc(tag) {
  return (tag in _descs);
}
function osp_node_desc(tag) {
  let found;
  if ((tag in _descs)) {
    found = _descs[tag];
    return found;
  }
  return new OspNodeDesc({type_tag: tag, entry: [], exit: []});
}
function _new_plans() {
  let out = {};
  return out;
}
function _plan_for(rt, wdesc, wtag, ndesc, ctag) {
  let plan = new OspPlan({ctag: ctag, w_entry: [], n_entry_u: [], n_entry_t: [], n_exit_t: [], n_exit_u: [], w_exit: []});
  for (const s of wdesc.entry) {
    if (((s.trig_tag !== UNTYPED) && rt.is_a(ctag, s.trig_tag))) {
      plan.w_entry.push(s);
    }
  }
  for (const s of wdesc.exit) {
    if (((s.trig_tag !== UNTYPED) && rt.is_a(ctag, s.trig_tag))) {
      plan.w_exit.push(s);
    }
  }
  for (const s of ndesc.entry) {
    if ((s.trig_tag === UNTYPED)) {
      plan.n_entry_u.push(s);
    } else if (rt.is_a(wtag, s.trig_tag)) {
      plan.n_entry_t.push(s);
    }
  }
  for (const s of ndesc.exit) {
    if ((s.trig_tag === UNTYPED)) {
      plan.n_exit_u.push(s);
    } else if (rt.is_a(wtag, s.trig_tag)) {
      plan.n_exit_t.push(s);
    }
  }
  return plan;
}
function _dequeue(scope) {
  let candidate;
  while (_jac.builtin.bool(scope.front)) {
    candidate = scope.front.pop();
    if ((!_jac.builtin.bool(scope.ignores) || !scope.ignores.includes(candidate))) {
      return candidate;
    }
  }
  while ((scope.next_head < scope.next.length)) {
    candidate = scope.next.at(scope.next_head);
    scope.next_head += 1;
    if ((!_jac.builtin.bool(scope.ignores) || !scope.ignores.includes(candidate))) {
      return candidate;
    }
  }
  if ((scope.next_head > 0)) {
    scope.next.length = 0;
    scope.next_head = 0;
  }
  return null;
}
class OspEngine {
  constructor(props = {}) {
    this.stack = (Object.hasOwn(props, "stack") ? props.stack : null);
    this.pin_refs = (Object.hasOwn(props, "pin_refs") ? props.pin_refs : false);
    this.acquired = (Object.hasOwn(props, "acquired") ? props.acquired : []);
    this.released = (Object.hasOwn(props, "released") ? props.released : []);
  }
  scope_of(wlk) {
    let sc;
    let i = (this.stack.length - 1);
    while ((i >= 0)) {
      sc = this.stack.at(i);
      if ((sc.wlk === wlk)) {
        return sc;
      }
      i -= 1;
    }
    return null;
  }
  current() {
    let found;
    if (_jac.builtin.bool(this.stack)) {
      found = this.stack.at((-1));
      return found;
    }
    return null;
  }
  visit(targets, insert_loc = (-1)) {
    let kept;
    let scope = this.current();
    if ((scope == null)) {
      return false;
    }
    let filtered = targets;
    if (_jac.builtin.bool(scope.ignores)) {
      kept = [];
      for (const t of targets) {
        if (!scope.ignores.includes(t)) {
          kept.push(t);
        }
      }
      filtered = kept;
    }
    if (!_jac.builtin.bool(filtered)) {
      return false;
    }
    if (this.pin_refs) {
      this.acquired.push(...filtered);
      scope.held.push(...filtered);
    }
    if ((insert_loc === (-1))) {
      scope.next.push(...filtered);
      return true;
    }
    if ((insert_loc === 0)) {
      scope.front.push(...[...filtered].reverse());
      scope.fenced = true;
      scope.pending_fence += filtered.length;
      return true;
    }
    let logical = [];
    let i = (scope.front.length - 1);
    while ((i >= 0)) {
      logical.push(scope.front.at(i));
      i -= 1;
    }
    let j = scope.next_head;
    while ((j < scope.next.length)) {
      logical.push(scope.next.at(j));
      j += 1;
    }
    let pos = insert_loc;
    if ((pos < (-logical.length))) {
      pos = 0;
    } else if ((pos < 0)) {
      pos = ((pos + logical.length) + 1);
    }
    scope.front = [];
    scope.next = [...[...logical.slice(0, pos), ...filtered], ...logical.slice(pos)];
    scope.next_head = 0;
    return true;
  }
  forget(target) {
    for (const scope of this.stack) {
      if (!scope.ignores.includes(target)) {
        scope.ignores.push(target);
      }
    }
  }
  disengage() {
    let scope = this.current();
    if ((scope != null)) {
      scope.disengaged = true;
    }
  }
  skip_rest() {
    let scope = this.current();
    if ((scope != null)) {
      scope.skip_node = true;
    }
  }
  report(val) {
    let scope = this.current();
    if ((scope != null)) {
      scope.reports.push(val);
    }
  }
  begin(wlk, starts) {
    let scope = new OspWalkScope({wlk: wlk, path: [], next: Array.from(_jac.builtin.iter(starts)), front: [], ignores: [], reports: [], nested: (this.stack.length > 0), held: []});
    scope.frames = [];
    this.stack.push(scope);
    return scope;
  }
  finish(scope, ok, rt) {
    let outer;
    this.stack.pop();
    if (_jac.builtin.bool(scope.held)) {
      this.released.push(...scope.held);
      scope.held = [];
    }
    if (_jac.builtin.bool((scope.nested && this.stack))) {
      outer = this.stack.at((-1));
      for (const r of scope.reports) {
        outer.reports.push(r);
      }
    }
    rt.on_complete(scope, ok);
  }
  next_slot(rt, scope, wdesc, run = false) {
    let s;
    let nxt;
    let f;
    let ctag;
    let plans;
    let ndesc;
    let plan;
    let budget;
    let found;
    let child;
    let candidate;
    let parent;
    if ((scope.frames == null)) {
      scope.frames = [];
    }
    let frames = scope.frames;
    while (true) {
      if ((scope.stage === 0)) {
        if (((scope.disengaged || scope.skip_node) || !_jac.builtin.bool(scope.next))) {
          scope.stage = 1;
          continue;
        }
        if ((scope.sidx === 0)) {
          scope.cur_b = scope.next[0];
        }
        while ((scope.sidx < wdesc.entry.length)) {
          s = wdesc.entry.at(scope.sidx);
          scope.sidx += 1;
          if ((s.trig_tag === UNTYPED)) {
            scope.cur_a = scope.wlk;
            if (run) {
              s.fn(scope.cur_a, scope.cur_b);
              if (((scope.disengaged || scope.skip_node) || !_jac.builtin.bool(scope.next))) {
                break;
              }
              continue;
            }
            return s;
          }
        }
        scope.stage = 1;
      } else if ((scope.stage === 1)) {
        if (scope.disengaged) {
          scope.stage = 3;
          return null;
        }
        if (!_jac.builtin.bool(frames)) {
          nxt = _dequeue(scope);
          if ((nxt == null)) {
            scope.stage = 2;
            scope.sidx = 0;
            continue;
          }
          frames.push(new OspFrame({loc: nxt}));
          continue;
        }
        f = frames.at((-1));
        if ((f.phase === 0)) {
          if ((f.plan == null)) {
            scope.path.push(f.loc);
            ctag = rt.tag_of(f.loc);
            if ((wdesc.plans == null)) {
              wdesc.plans = _new_plans();
            }
            plans = wdesc.plans;
            if ((ctag in plans)) {
              f.plan = plans[ctag];
            } else {
              ndesc = rt.node_desc(ctag);
              f.plan = _plan_for(rt, wdesc, wdesc.type_tag, ndesc, ctag);
              plans[ctag] = f.plan;
            }
            scope.pending_fence = 0;
          }
          plan = f.plan;
          if (run) {
            for (const s of plan.w_entry) {
              scope.cur_a = scope.wlk;
              scope.cur_b = f.loc;
              s.fn(scope.cur_a, scope.cur_b);
              if (scope.disengaged) {
                scope.stage = 3;
                return null;
              }
              if (scope.skip_node) {
                break;
              }
            }
            if (!scope.skip_node) {
              for (const s of plan.n_entry_u) {
                scope.cur_a = f.loc;
                scope.cur_b = scope.wlk;
                s.fn(scope.cur_a, scope.cur_b);
                if (scope.disengaged) {
                  scope.stage = 3;
                  return null;
                }
                if (scope.skip_node) {
                  break;
                }
              }
            }
            if (!scope.skip_node) {
              for (const s of plan.n_entry_t) {
                scope.cur_a = f.loc;
                scope.cur_b = scope.wlk;
                s.fn(scope.cur_a, scope.cur_b);
                if (scope.disengaged) {
                  scope.stage = 3;
                  return null;
                }
                if (scope.skip_node) {
                  break;
                }
              }
            }
            scope.skip_node = false;
            f.phase = 1;
            f.band = 0;
            f.idx = 0;
            f.budget = scope.pending_fence;
            continue;
          }
          if ((f.band === 0)) {
            if (((f.idx > 0) && scope.skip_node)) {
              f.idx = 0;
              f.band = 1;
              continue;
            }
            if ((f.idx < plan.w_entry.length)) {
              s = plan.w_entry.at(f.idx);
              f.idx += 1;
              scope.cur_a = scope.wlk;
              scope.cur_b = f.loc;
              return s;
            }
            f.idx = 0;
            f.band = 1;
            continue;
          }
          if ((f.band === 1)) {
            if (scope.skip_node) {
              f.idx = 0;
              f.band = 2;
              continue;
            }
            if ((f.idx < plan.n_entry_u.length)) {
              s = plan.n_entry_u.at(f.idx);
              f.idx += 1;
              scope.cur_a = f.loc;
              scope.cur_b = scope.wlk;
              return s;
            }
            f.idx = 0;
            f.band = 2;
            continue;
          }
          if (scope.skip_node) {
            f.idx = 0;
          } else if ((f.idx < plan.n_entry_t.length)) {
            s = plan.n_entry_t.at(f.idx);
            f.idx += 1;
            scope.cur_a = f.loc;
            scope.cur_b = scope.wlk;
            return s;
          } else {
            f.idx = 0;
          }
          scope.skip_node = false;
          f.phase = 1;
          f.band = 0;
          f.budget = scope.pending_fence;
          continue;
        } else if ((f.phase === 1)) {
          if (scope.fenced) {
            budget = f.budget;
            found = false;
            child = f.loc;
            while (((budget > 0) && !found)) {
              if (_jac.builtin.bool(scope.front)) {
                candidate = scope.front.pop();
                budget -= 1;
                if ((!_jac.builtin.bool(scope.ignores) || !scope.ignores.includes(candidate))) {
                  child = candidate;
                  found = true;
                }
              } else {
                budget = 0;
              }
            }
            f.budget = budget;
            if (found) {
              frames.push(new OspFrame({loc: child}));
            } else {
              f.phase = 2;
              scope.pending_fence = 0;
            }
          } else {
            nxt = _dequeue(scope);
            if ((nxt != null)) {
              if (((((f.plan != null) && !_jac.builtin.bool(f.plan.n_exit_t)) && !_jac.builtin.bool(f.plan.n_exit_u)) && !_jac.builtin.bool(f.plan.w_exit))) {
                f.loc = nxt;
                f.phase = 0;
                f.band = 0;
                f.idx = 0;
                f.budget = 0;
                f.plan = null;
              } else {
                frames.push(new OspFrame({loc: nxt}));
              }
            } else {
              f.phase = 2;
              scope.pending_fence = 0;
            }
          }
          continue;
        } else {
          if ((f.plan == null)) {
            frames.pop();
            continue;
          }
          plan = f.plan;
          if (run) {
            for (const s of plan.n_exit_t) {
              scope.cur_a = f.loc;
              scope.cur_b = scope.wlk;
              s.fn(scope.cur_a, scope.cur_b);
              if (scope.disengaged) {
                scope.stage = 3;
                return null;
              }
              if (scope.skip_node) {
                break;
              }
            }
            if (!scope.skip_node) {
              for (const s of plan.n_exit_u) {
                scope.cur_a = f.loc;
                scope.cur_b = scope.wlk;
                s.fn(scope.cur_a, scope.cur_b);
                if (scope.disengaged) {
                  scope.stage = 3;
                  return null;
                }
                if (scope.skip_node) {
                  break;
                }
              }
            }
            if (!scope.skip_node) {
              for (const s of plan.w_exit) {
                scope.cur_a = scope.wlk;
                scope.cur_b = f.loc;
                s.fn(scope.cur_a, scope.cur_b);
                if (scope.disengaged) {
                  scope.stage = 3;
                  return null;
                }
                if (scope.skip_node) {
                  break;
                }
              }
            }
            scope.skip_node = false;
            frames.pop();
            if (_jac.builtin.bool(((scope.fenced && (scope.pending_fence > 0)) && frames))) {
              parent = frames.at((-1));
              parent.budget += scope.pending_fence;
            }
            continue;
          }
          if ((f.band === 0)) {
            if (((f.idx > 0) && scope.skip_node)) {
              f.idx = 0;
              f.band = 1;
              continue;
            }
            if ((f.idx < plan.n_exit_t.length)) {
              s = plan.n_exit_t.at(f.idx);
              f.idx += 1;
              scope.cur_a = f.loc;
              scope.cur_b = scope.wlk;
              return s;
            }
            f.idx = 0;
            f.band = 1;
            continue;
          }
          if ((f.band === 1)) {
            if (scope.skip_node) {
              f.idx = 0;
              f.band = 2;
              continue;
            }
            if ((f.idx < plan.n_exit_u.length)) {
              s = plan.n_exit_u.at(f.idx);
              f.idx += 1;
              scope.cur_a = f.loc;
              scope.cur_b = scope.wlk;
              return s;
            }
            f.idx = 0;
            f.band = 2;
            continue;
          }
          if (scope.skip_node) {
            f.idx = 0;
          } else if ((f.idx < plan.w_exit.length)) {
            s = plan.w_exit.at(f.idx);
            f.idx += 1;
            scope.cur_a = scope.wlk;
            scope.cur_b = f.loc;
            return s;
          } else {
            f.idx = 0;
          }
          scope.skip_node = false;
          frames.pop();
          if (_jac.builtin.bool(((scope.fenced && (scope.pending_fence > 0)) && frames))) {
            parent = frames.at((-1));
            parent.budget += scope.pending_fence;
          }
          continue;
        }
      } else if ((scope.stage === 2)) {
        if ((scope.disengaged || !_jac.builtin.bool(scope.path))) {
          scope.stage = 3;
          return null;
        }
        if (((scope.sidx > 0) && scope.skip_node)) {
          scope.stage = 3;
          return null;
        }
        while ((scope.sidx < wdesc.exit.length)) {
          s = wdesc.exit.at(scope.sidx);
          scope.sidx += 1;
          if ((s.trig_tag === UNTYPED)) {
            scope.cur_a = scope.wlk;
            scope.cur_b = scope.path.at((-1));
            if (run) {
              s.fn(scope.cur_a, scope.cur_b);
              if ((scope.disengaged || scope.skip_node)) {
                break;
              }
              continue;
            }
            return s;
          }
        }
        scope.stage = 3;
        return null;
      } else {
        return null;
      }
    }
    return null;
  }
  spawn(rt, wlk, wdesc, starts) {
    let scope = this.begin(wlk, starts);
    let ok = false;
    try {
      this.next_slot(rt, scope, wdesc, true);
      ok = true;
    } finally {
      this.finish(scope, ok, rt);
    }
    return wlk;
  }
}
let DEFAULT = new OspEngine({stack: []});
function scope_of(wlk) {
  return DEFAULT.scope_of(wlk);
}
function _current_scope() {
  return DEFAULT.current();
}
function osp_visit(targets, insert_loc = (-1)) {
  return DEFAULT.visit(targets, insert_loc);
}
function osp_kernel_pin_refs() {
  DEFAULT.pin_refs = true;
}
function osp_kernel_pending() {
  return (DEFAULT.acquired.length + DEFAULT.released.length);
}
function osp_take_acquired() {
  let out = DEFAULT.acquired;
  DEFAULT.acquired = [];
  return out;
}
function osp_take_released() {
  let out = DEFAULT.released;
  DEFAULT.released = [];
  return out;
}
function osp_forget(target) {
  DEFAULT.forget(target);
}
function osp_forget_all(targets) {
  let i = 0;
  while ((i < targets.length)) {
    DEFAULT.forget(targets.at(i));
    i += 1;
  }
}
function osp_disengage() {
  DEFAULT.disengage();
}
function osp_skip_rest() {
  DEFAULT.skip_rest();
}
function osp_report(val) {
  DEFAULT.report(val);
}
function osp_spawn(rt, wlk, wdesc, starts) {
  return DEFAULT.spawn(rt, wlk, wdesc, starts);
}
let _isa = {};
let _has_subs = new Set();
function osp_register_type(tag, bases) {
  let banc;
  let old;
  let same;
  let anc = new Set();
  anc.add(tag);
  for (const b of bases) {
    if ((b in _isa)) {
      banc = _isa[b];
      for (const t of banc) {
        anc.add(t);
      }
    } else {
      anc.add(b);
    }
  }
  if ((tag in _isa)) {
    old = _isa[tag];
    same = (old.size === anc.size);
    if (same) {
      for (const t of anc) {
        if (!old.has(t)) {
          same = false;
        }
      }
    }
    return (same ? 1 : 0);
  }
  _isa[tag] = anc;
  for (const t of anc) {
    if ((t !== tag)) {
      _has_subs.add(t);
    }
  }
  return 1;
}
function osp_is_a(tag, base) {
  let anc;
  if ((tag === base)) {
    return true;
  }
  if ((tag in _isa)) {
    anc = _isa[tag];
    return anc.has(base);
  }
  return false;
}
class OspEdgeTypeDesc {
  constructor(props = {}) {
    this.tag = (Object.hasOwn(props, "tag") ? props.tag : null);
    this.factory = (Object.hasOwn(props, "factory") ? props.factory : null);
  }
}
let _edge_types = {};
function osp_register_edge_type(name, tag, factory) {
  _edge_types[name] = new OspEdgeTypeDesc({tag: tag, factory: factory});
}
function osp_edge_type(name) {
  let desc = _jac.dict.get(_edge_types, name);
  if ((desc == null)) {
    throw new _jac.exc.TypeError("graph operation requires a registered edge type");
  }
  return desc;
}
function osp_new_edge(desc) {
  return desc.factory();
}
let _NO_ROWS = [];
class OspEdgeRow {
  constructor(props = {}) {
    this.src = (Object.hasOwn(props, "src") ? props.src : null);
    this.tgt = (Object.hasOwn(props, "tgt") ? props.tgt : null);
    this.tag = (Object.hasOwn(props, "tag") ? props.tag : null);
    this.handle = (Object.hasOwn(props, "handle") ? props.handle : null);
    this.undirected = (Object.hasOwn(props, "undirected") ? props.undirected : false);
    this.live = (Object.hasOwn(props, "live") ? props.live : true);
    this.pos_out = (Object.hasOwn(props, "pos_out") ? props.pos_out : (-1));
    this.pos_in = (Object.hasOwn(props, "pos_in") ? props.pos_in : (-1));
  }
}
class OspAdj {
  constructor(props = {}) {
    this.rows_out = (Object.hasOwn(props, "rows_out") ? props.rows_out : null);
    this.rows_in = (Object.hasOwn(props, "rows_in") ? props.rows_in : null);
    this.out = (Object.hasOwn(props, "out") ? props.out : null);
    this.inn = (Object.hasOwn(props, "inn") ? props.inn : null);
  }
}
class OspGraph {
  constructor(props = {}) {
    this.adj = (Object.hasOwn(props, "adj") ? props.adj : null);
    this.rows = (Object.hasOwn(props, "rows") ? props.rows : null);
    this.free_rows = (Object.hasOwn(props, "free_rows") ? props.free_rows : null);
    this.row_of = (Object.hasOwn(props, "row_of") ? props.row_of : null);
    this.dead = (Object.hasOwn(props, "dead") ? props.dead : null);
    this.regions = (Object.hasOwn(props, "regions") ? props.regions : null);
    this.index_at = (Object.hasOwn(props, "index_at") ? props.index_at : 8);
    this.tags_out = (Object.hasOwn(props, "tags_out") ? props.tags_out : {});
    this.tags_in = (Object.hasOwn(props, "tags_in") ? props.tags_in : {});
    this.holes_out = (Object.hasOwn(props, "holes_out") ? props.holes_out : {});
    this.holes_in = (Object.hasOwn(props, "holes_in") ? props.holes_in : {});
    this.pin_refs = (Object.hasOwn(props, "pin_refs") ? props.pin_refs : false);
    this.unpinned = (Object.hasOwn(props, "unpinned") ? props.unpinned : []);
  }
  adj_of(h) {
    let found;
    if ((h in this.adj)) {
      found = this.adj[h];
      return found;
    }
    let made = new OspAdj({rows_out: [], rows_in: [], out: null, inn: null});
    this.adj[h] = made;
    return made;
  }
  light_out(a) {
    let made;
    let d = a.out;
    if ((d == null)) {
      made = {};
      a.out = made;
      return made;
    }
    return d;
  }
  light_in(a) {
    let made;
    let d = a.inn;
    if ((d == null)) {
      made = {};
      a.inn = made;
      return made;
    }
    return d;
  }
  has_light(h) {
    let peers;
    let srcs;
    if (!(h in this.adj)) {
      return false;
    }
    let a = this.adj[h];
    let outs = a.out;
    if ((outs != null)) {
      for (const k of Object.keys(outs)) {
        peers = outs[k];
        if (_jac.builtin.bool(peers)) {
          return true;
        }
      }
    }
    let inns = a.inn;
    if ((inns != null)) {
      for (const k of Object.keys(inns)) {
        srcs = inns[k];
        if (_jac.builtin.bool(srcs)) {
          return true;
        }
      }
    }
    return false;
  }
  connect_light(src, tgt, tag, one_sided) {
    let outs;
    let td;
    let inns;
    if (((src in this.dead) || (tgt in this.dead))) {
      return (-1);
    }
    let sa = this.adj_of(src);
    let ta = this.adj_of(tgt);
    let sd = this.light_out(sa);
    if ((tag in sd)) {
      outs = sd[tag];
      outs.push(tgt);
    } else {
      sd[tag] = [tgt];
    }
    if (!one_sided) {
      td = this.light_in(ta);
      if ((tag in td)) {
        inns = td[tag];
        inns.push(src);
      } else {
        td[tag] = [src];
      }
    }
    return tgt;
  }
  light_remove_one(src, tgt, tag) {
    let ta;
    let td;
    let inns;
    if (!(src in this.adj)) {
      return false;
    }
    let sa = this.adj[src];
    let sd = sa.out;
    if (((sd == null) || !(tag in sd))) {
      return false;
    }
    let outs = sd[tag];
    if (!this._drop_handle(outs, tgt)) {
      return false;
    }
    if ((tgt in this.adj)) {
      ta = this.adj[tgt];
      td = ta.inn;
      if (((td != null) && (tag in td))) {
        inns = td[tag];
        this._drop_handle(inns, src);
      }
    }
    return true;
  }
  light_pairs(h, outgoing) {
    let peers;
    let out = [];
    if (!(h in this.adj)) {
      return out;
    }
    let a = this.adj[h];
    let d = (outgoing ? a.out : a.inn);
    if ((d != null)) {
      for (const k of Object.keys(d)) {
        peers = d[k];
        for (const p of peers) {
          out.push(k);
          out.push(p);
        }
      }
    }
    return out;
  }
  light_detach(h) {
    let peers;
    let pa;
    let pd;
    let inns;
    let srcs;
    let sa;
    let sd;
    let outs;
    if (!(h in this.adj)) {
      return 0;
    }
    let a = this.adj[h];
    let n = 0;
    let ad = a.out;
    if ((ad != null)) {
      for (const k of Object.keys(ad)) {
        peers = ad[k];
        for (const p of peers) {
          if ((p in this.adj)) {
            pa = this.adj[p];
            pd = pa.inn;
            if (((pd != null) && (k in pd))) {
              inns = pd[k];
              this._drop_handle(inns, h);
            }
          }
          n += 1;
        }
      }
      _jac.dict.clear(ad);
    }
    let ai = a.inn;
    if ((ai != null)) {
      for (const k of Object.keys(ai)) {
        srcs = ai[k];
        for (const s of srcs) {
          if ((s in this.adj)) {
            sa = this.adj[s];
            sd = sa.out;
            if (((sd != null) && (k in sd))) {
              outs = sd[k];
              this._drop_handle(outs, h);
            }
          }
          n += 1;
        }
      }
      _jac.dict.clear(ai);
    }
    return n;
  }
  _drop_handle(lst, h) {
    let i = 0;
    let n = lst.length;
    while ((i < n)) {
      if ((lst.at(i) === h)) {
        lst.splice(i, 1)[0];
        return true;
      }
      i += 1;
    }
    return false;
  }
  is_dead(h) {
    return (h in this.dead);
  }
  has_edge(eobj) {
    return (eobj in this.row_of);
  }
  _row_alloc(src, tgt, tag, eobj, undirected) {
    let rid;
    let row;
    if (_jac.builtin.bool(this.free_rows)) {
      rid = this.free_rows.pop();
      row = this.rows.at(rid);
      row.src = src;
      row.tgt = tgt;
      row.tag = tag;
      row.handle = eobj;
      row.undirected = undirected;
      row.live = true;
      this.row_of[eobj] = rid;
      return rid;
    }
    rid = this.rows.length;
    this.rows.push(new OspEdgeRow({src: src, tgt: tgt, tag: tag, handle: eobj, undirected: undirected}));
    this.row_of[eobj] = rid;
    return rid;
  }
  _row_retire(rid) {
    let row = this.rows.at(rid);
    if ((this.pin_refs && row.live)) {
      this.unpinned.push(row.src);
      this.unpinned.push(row.tgt);
      this.unpinned.push(row.handle);
    }
    if ((row.handle in this.row_of)) {
{
        const _jac_del_1053_13_0_c = this.row_of;
        const _jac_del_1053_13_0_k = row.handle;
        _jac.poly.destroy(_jac.poly.getitem(_jac_del_1053_13_0_c, _jac_del_1053_13_0_k));
        _jac.poly.delitem(_jac_del_1053_13_0_c, _jac_del_1053_13_0_k);
      }
    }
    row.live = false;
    row.handle = 0;
    row.pos_out = (-1);
    row.pos_in = (-1);
    this.free_rows.push(rid);
  }
  _compact(lst, outgoing) {
    let rid;
    let row;
    let j = 0;
    let n = lst.length;
    let i = 0;
    while ((i < n)) {
      rid = lst.at(i);
      if ((rid >= 0)) {
        if ((j !== i)) {
          _jac.poly.setitem(lst, j, rid);
          row = this.rows.at(rid);
          if (outgoing) {
            row.pos_out = j;
          } else {
            row.pos_in = j;
          }
        }
        j += 1;
      }
      i += 1;
    }
    while ((lst.length > j)) {
      lst.pop();
    }
  }
  _slot_clear(lst, pos, rid, holes, outgoing) {
    let n = lst.length;
    if ((((pos < 0) || (pos >= n)) || (lst.at(pos) !== rid))) {
      return holes;
    }
    if ((pos === (n - 1))) {
      lst.pop();
      while (_jac.builtin.bool(_jac.poly.and_(lst, () => (lst.at((lst.length - 1)) < 0)))) {
        lst.pop();
        holes -= 1;
      }
      return holes;
    }
    _jac.poly.setitem(lst, pos, (-1));
    holes += 1;
    if (((holes * 2) > lst.length)) {
      this._compact(lst, outgoing);
      return 0;
    }
    return holes;
  }
  _tag_drop(d, rid, outgoing) {
    let mid;
    let m;
    let row = this.rows.at(rid);
    let tag = row.tag;
    if (!(tag in d)) {
      return;
    }
    let tl = d[tag];
    let key = (outgoing ? row.pos_out : row.pos_in);
    let lo = 0;
    let hi = tl.length;
    while ((lo < hi)) {
      mid = Math.floor((lo + hi) / 2);
      m = this.rows.at(tl.at(mid));
      if ((((outgoing ? m.pos_out : m.pos_in)) < key)) {
        lo = (mid + 1);
      } else {
        hi = mid;
      }
    }
    if (((lo < tl.length) && (tl.at(lo) === rid))) {
      tl.splice(lo, 1)[0];
    }
    if (!_jac.builtin.bool(tl)) {
{
        _jac.poly.destroy(_jac.poly.getitem(d, tag));
        _jac.poly.delitem(d, tag);
      }
    }
  }
  _drop_side(h, a, rid, outgoing) {
    let i;
    let n;
    let lst = (outgoing ? a.rows_out : a.rows_in);
    let tags = (outgoing ? this.tags_out : this.tags_in);
    if (!(h in tags)) {
      i = 0;
      n = lst.length;
      while ((i < n)) {
        if ((lst.at(i) === rid)) {
          lst.splice(i, 1)[0];
          return;
        }
        i += 1;
      }
      return;
    }
    let row = this.rows.at(rid);
    let d = tags[h];
    this._tag_drop(d, rid, outgoing);
    let holes_of = (outgoing ? this.holes_out : this.holes_in);
    let holes = this._slot_clear(lst, (outgoing ? row.pos_out : row.pos_in), rid, _jac.dict.get(holes_of, h, 0), outgoing);
    if (_jac.builtin.bool(_jac.poly.and_(d, () => (holes > 0)))) {
      holes_of[h] = holes;
    } else if ((h in holes_of)) {
{
        _jac.poly.destroy(_jac.poly.getitem(holes_of, h));
        _jac.poly.delitem(holes_of, h);
      }
    }
    if (!_jac.builtin.bool(d)) {
{
        _jac.poly.destroy(_jac.poly.getitem(tags, h));
        _jac.poly.delitem(tags, h);
      }
    }
  }
  _add_side(h, a, rid, tag, outgoing) {
    let d;
    let tl;
    let lst = (outgoing ? a.rows_out : a.rows_in);
    let tags = (outgoing ? this.tags_out : this.tags_in);
    let row = this.rows.at(rid);
    if (outgoing) {
      row.pos_out = lst.length;
    } else {
      row.pos_in = lst.length;
    }
    lst.push(rid);
    if ((h in tags)) {
      d = tags[h];
      if ((tag in d)) {
        tl = d[tag];
        tl.push(rid);
      } else {
        d[tag] = [rid];
      }
    } else if ((lst.length > this.index_at)) {
      this._build_index(h, lst, outgoing);
    }
  }
  _live_rows(h, a, outgoing) {
    if (outgoing) {
      return (a.rows_out.length - _jac.dict.get(this.holes_out, h, 0));
    }
    return (a.rows_in.length - _jac.dict.get(this.holes_in, h, 0));
  }
  region_reg(h, rgn) {
    let members;
    if ((rgn in this.regions)) {
      members = this.regions[rgn];
      members.push(h);
    } else {
      this.regions[rgn] = [h];
    }
  }
  _no_rows(h, a) {
    return ((this._live_rows(h, a, true) === 0) && (this._live_rows(h, a, false) === 0));
  }
  connect(src, tgt, eobj, undirected, tag, rgn_src, rgn_tgt) {
    if (((src in this.dead) || (tgt in this.dead))) {
      return (-1);
    }
    let sa = this.adj_of(src);
    let ta = this.adj_of(tgt);
    if (((rgn_src !== 0) && this._no_rows(src, sa))) {
      this.region_reg(src, rgn_src);
    }
    if ((((rgn_tgt !== 0) && (tgt !== src)) && this._no_rows(tgt, ta))) {
      this.region_reg(tgt, rgn_tgt);
    }
    let rid = this._row_alloc(src, tgt, tag, eobj, undirected);
    this._add_side(src, sa, rid, tag, true);
    this._add_side(tgt, ta, rid, tag, false);
    return tgt;
  }
  _build_index(h, lst, outgoing) {
    let rid;
    let row;
    let tag;
    let tl;
    let d = {};
    let i = 0;
    let n = lst.length;
    while ((i < n)) {
      rid = lst.at(i);
      row = this.rows.at(rid);
      if (outgoing) {
        row.pos_out = i;
      } else {
        row.pos_in = i;
      }
      tag = row.tag;
      if ((tag in d)) {
        tl = d[tag];
        tl.push(rid);
      } else {
        d[tag] = [rid];
      }
      i += 1;
    }
    if (outgoing) {
      this.tags_out[h] = d;
    } else {
      this.tags_in[h] = d;
    }
  }
  _narrowed(h, outgoing, want) {
    if ((want === (-1))) {
      return true;
    }
    return (h in ((outgoing ? this.tags_out : this.tags_in)));
  }
  _tag_matches(tag, want) {
    if (((want === (-1)) || (tag === want))) {
      return true;
    }
    return osp_is_a(tag, want);
  }
  _rows_for(h, a, outgoing, want) {
    let exact;
    let only;
    let row;
    if ((!this._narrowed(h, outgoing, want) || (want === (-1)))) {
      return (outgoing ? a.rows_out : a.rows_in);
    }
    let tags = (outgoing ? this.tags_out : this.tags_in);
    let d = tags[h];
    if (!_has_subs.has(want)) {
      if ((want in d)) {
        exact = d[want];
        return exact;
      }
      return _NO_ROWS;
    }
    let hits = [];
    for (const k of Object.keys(d)) {
      if (((k === want) || osp_is_a(k, want))) {
        hits.push(d[k]);
      }
    }
    if (!_jac.builtin.bool(hits)) {
      return _NO_ROWS;
    }
    if ((hits.length === 1)) {
      only = hits[0];
      return only;
    }
    let slots = [];
    for (const lst of hits) {
      for (const rid of lst) {
        if ((rid >= 0)) {
          row = this.rows.at(rid);
          slots.push((outgoing ? row.pos_out : row.pos_in));
        }
      }
    }
    slots.sort();
    let all_rows = (outgoing ? a.rows_out : a.rows_in);
    let merged = [];
    for (const p of slots) {
      merged.push(all_rows.at(p));
    }
    return merged;
  }
  _collect(origin, dir, edge_tag, edges_only, out) {
    let row;
    let o;
    let peers;
    let srcs;
    if ((!(origin in this.adj) || (origin in this.dead))) {
      return;
    }
    let a = this.adj[origin];
    let out_ok = ((dir === 2) || (dir === 3));
    let in_ok = ((dir === 1) || (dir === 3));
    let nar = this._narrowed(origin, true, edge_tag);
    for (const rid of this._rows_for(origin, a, true, edge_tag)) {
      if ((rid < 0)) {
        continue;
      }
      row = this.rows.at(rid);
      if (!row.live) {
        continue;
      }
      if (((out_ok || row.undirected) && (nar || this._tag_matches(row.tag, edge_tag)))) {
        o = (edges_only ? row.handle : row.tgt);
        out.push(o);
      }
    }
    nar = this._narrowed(origin, false, edge_tag);
    for (const rid of this._rows_for(origin, a, false, edge_tag)) {
      if ((rid < 0)) {
        continue;
      }
      row = this.rows.at(rid);
      if (!row.live) {
        continue;
      }
      if (((in_ok || row.undirected) && (nar || this._tag_matches(row.tag, edge_tag)))) {
        o = (edges_only ? row.handle : row.src);
        out.push(o);
      }
    }
    if (edges_only) {
      return;
    }
    let ad = a.out;
    if ((out_ok && (ad != null))) {
      for (const k of Object.keys(ad)) {
        if (this._tag_matches(k, edge_tag)) {
          peers = ad[k];
          for (const p of peers) {
            out.push(p);
          }
        }
      }
    }
    let ai = a.inn;
    if ((in_ok && (ai != null))) {
      for (const k of Object.keys(ai)) {
        if (this._tag_matches(k, edge_tag)) {
          srcs = ai[k];
          for (const s of srcs) {
            out.push(s);
          }
        }
      }
    }
  }
  _dedup_tail(out, start, seen) {
    let v;
    let j = start;
    let i = start;
    let n = out.length;
    while ((i < n)) {
      v = out.at(i);
      if (!seen.has(v)) {
        seen.add(v);
        _jac.poly.setitem(out, j, v);
        j += 1;
      }
      i += 1;
    }
    while ((out.length > j)) {
      out.pop();
    }
  }
  refs_into(origin, dir, edge_tag, edges_only, out, seen) {
    let start = out.length;
    this._collect(origin, dir, edge_tag, edges_only, out);
    this._dedup_tail(out, start, seen);
  }
  refs(origin, dir, edge_tag, edges_only) {
    let seen;
    let v;
    let k;
    let out = [];
    this._collect(origin, dir, edge_tag, edges_only, out);
    let n = out.length;
    if ((n < 2)) {
      return out;
    }
    if ((n > 16)) {
      seen = new Set();
      this._dedup_tail(out, 0, seen);
      return out;
    }
    let j = 0;
    let i = 0;
    while ((i < n)) {
      v = out.at(i);
      k = 0;
      while (((k < j) && (out.at(k) !== v))) {
        k += 1;
      }
      if ((k === j)) {
        _jac.poly.setitem(out, j, v);
        j += 1;
      }
      i += 1;
    }
    while ((out.length > j)) {
      out.pop();
    }
    return out;
  }
  refs_many(origins, dir, edge_tag, edges_only) {
    let out = [];
    let seen = new Set();
    for (const origin of origins) {
      this.refs_into(origin, dir, edge_tag, edges_only, out, seen);
    }
    return out;
  }
  refs_edge_pred(origins, dir, edge_tag, edges_only, pred) {
    let a;
    let nar;
    let row;
    let o;
    let out = [];
    let seen = new Set();
    let out_ok = ((dir === 2) || (dir === 3));
    let in_ok = ((dir === 1) || (dir === 3));
    for (const origin of origins) {
      if ((!(origin in this.adj) || (origin in this.dead))) {
        continue;
      }
      a = this.adj[origin];
      nar = this._narrowed(origin, true, edge_tag);
      for (const rid of this._rows_for(origin, a, true, edge_tag)) {
        if ((rid < 0)) {
          continue;
        }
        row = this.rows.at(rid);
        if (!row.live) {
          continue;
        }
        if ((((out_ok || row.undirected) && (nar || this._tag_matches(row.tag, edge_tag))) && pred(row.handle))) {
          o = (edges_only ? row.handle : row.tgt);
          if (!seen.has(o)) {
            seen.add(o);
            out.push(o);
          }
        }
      }
      nar = this._narrowed(origin, false, edge_tag);
      for (const rid of this._rows_for(origin, a, false, edge_tag)) {
        if ((rid < 0)) {
          continue;
        }
        row = this.rows.at(rid);
        if (!row.live) {
          continue;
        }
        if ((((in_ok || row.undirected) && (nar || this._tag_matches(row.tag, edge_tag))) && pred(row.handle))) {
          o = (edges_only ? row.handle : row.src);
          if (!seen.has(o)) {
            seen.add(o);
            out.push(o);
          }
        }
      }
    }
    return out;
  }
  filter_handles(hs, pred) {
    let out = [];
    for (const h of hs) {
      if (pred(h)) {
        out.push(h);
      }
    }
    return out;
  }
  refs_chain(origins, dirs, tags, edges_only) {
    let last;
    let cur = origins;
    let i = 0;
    let n = dirs.length;
    while ((i < n)) {
      last = (i === (n - 1));
      cur = this.refs_many(cur, dirs.at(i), tags.at(i), (last ? edges_only : false));
      i += 1;
    }
    return cur;
  }
  conn_many(srcs, tgts, eobjs, undirected, tag, rgn_src, rgn_tgt) {
    let eobj;
    let n = 0;
    let k = 0;
    for (const s of srcs) {
      for (const t of tgts) {
        eobj = eobjs.at(k);
        k += 1;
        if ((this.connect(s, t, eobj, undirected, tag, rgn_src, rgn_tgt) < 0)) {
          return (-1);
        }
        n += 1;
      }
    }
    return n;
  }
  edge_peer(eobj, origin) {
    if (!(eobj in this.row_of)) {
      return (-1);
    }
    let rid = this.row_of[eobj];
    let row = this.rows.at(rid);
    if (!row.live) {
      return (-1);
    }
    if ((row.src === origin)) {
      return row.tgt;
    }
    if ((row.tgt === origin)) {
      return row.src;
    }
    return (-1);
  }
  _unlink(rid) {
    let sa;
    let ta;
    let row = this.rows.at(rid);
    if ((row.src in this.adj)) {
      sa = this.adj[row.src];
      this._drop_side(row.src, sa, rid, true);
    }
    if ((row.tgt in this.adj)) {
      ta = this.adj[row.tgt];
      this._drop_side(row.tgt, ta, rid, false);
    }
  }
  disconnect(eobj) {
    if (!(eobj in this.row_of)) {
      return false;
    }
    let rid = this.row_of[eobj];
    let row = this.rows.at(rid);
    if (!row.live) {
      return false;
    }
    this._unlink(rid);
    this._row_retire(rid);
    return true;
  }
  _between_hits(from_h, to_h, edge_tag, any_row, hits, hit_set) {
    let ta;
    let other;
    let row;
    if (!(from_h in this.adj)) {
      return;
    }
    let fa = this.adj[from_h];
    let cand = this._rows_for(from_h, fa, true, edge_tag);
    let nar = this._narrowed(from_h, true, edge_tag);
    if ((to_h in this.adj)) {
      ta = this.adj[to_h];
      other = this._rows_for(to_h, ta, false, edge_tag);
      if ((other.length < cand.length)) {
        cand = other;
        nar = this._narrowed(to_h, false, edge_tag);
      }
    }
    for (const rid of cand) {
      if ((rid < 0)) {
        continue;
      }
      row = this.rows.at(rid);
      if (!row.live) {
        continue;
      }
      if (((((row.src === from_h) && (row.tgt === to_h)) && (any_row || row.undirected)) && (nar || this._tag_matches(row.tag, edge_tag)))) {
        if (!hit_set.has(rid)) {
          hit_set.add(rid);
          hits.push(rid);
        }
      }
    }
  }
  disconnect_between(src, tgt, dir, edge_tag) {
    if (!(src in this.adj)) {
      return 0;
    }
    let hits = [];
    let hit_set = new Set();
    this._between_hits(src, tgt, edge_tag, ((dir === 2) || (dir === 3)), hits, hit_set);
    this._between_hits(tgt, src, edge_tag, ((dir === 1) || (dir === 3)), hits, hit_set);
    for (const rid of hits) {
      this._unlink(rid);
      this._row_retire(rid);
    }
    return hits.length;
  }
  disconnect_between_pred(src, tgt, dir, edge_tag, pred) {
    let row;
    if (!(src in this.adj)) {
      return 0;
    }
    let cands = [];
    let hit_set = new Set();
    this._between_hits(src, tgt, edge_tag, ((dir === 2) || (dir === 3)), cands, hit_set);
    this._between_hits(tgt, src, edge_tag, ((dir === 1) || (dir === 3)), cands, hit_set);
    let hits = [];
    for (const rid of cands) {
      row = this.rows.at(rid);
      if (pred(row.handle)) {
        hits.push(rid);
      }
    }
    for (const rid of hits) {
      this._unlink(rid);
      this._row_retire(rid);
    }
    return hits.length;
  }
  light_disconnect_between(src, tgt, dir, edge_tag) {
    let ktags;
    let ktags2;
    let n = 0;
    if (!(src in this.adj)) {
      return 0;
    }
    let a = this.adj[src];
    let ad = a.out;
    if ((((dir === 2) || (dir === 3)) && (ad != null))) {
      ktags = [];
      for (const k of Object.keys(ad)) {
        if (this._tag_matches(k, edge_tag)) {
          ktags.push(k);
        }
      }
      for (const k of ktags) {
        while (this.light_remove_one(src, tgt, k)) {
          n += 1;
        }
      }
    }
    let ai = a.inn;
    if ((((dir === 1) || (dir === 3)) && (ai != null))) {
      ktags2 = [];
      for (const k of Object.keys(ai)) {
        if (this._tag_matches(k, edge_tag)) {
          ktags2.push(k);
        }
      }
      for (const k of ktags2) {
        while (this.light_remove_one(tgt, src, k)) {
          n += 1;
        }
      }
    }
    return n;
  }
  disconnect_between_many(srcs, tgts, dir, edge_tag) {
    let n = 0;
    for (const s of srcs) {
      for (const t of tgts) {
        n += this.disconnect_between(s, t, dir, edge_tag);
      }
    }
    return n;
  }
  node_destroy(h) {
    let row;
    if ((h in this.dead)) {
      return 0;
    }
    this.dead[h] = 1;
    if (!(h in this.adj)) {
      return 0;
    }
    let n0 = this.light_detach(h);
    let a = this.adj[h];
    let gone = [];
    for (const rid of a.rows_out) {
      if ((rid < 0)) {
        continue;
      }
      row = this.rows.at(rid);
      if (row.live) {
        gone.push(rid);
      }
    }
    for (const rid of a.rows_in) {
      if ((rid < 0)) {
        continue;
      }
      row = this.rows.at(rid);
      if (row.live) {
        gone.push(rid);
      }
    }
    let n = n0;
    for (const rid of gone) {
      row = this.rows.at(rid);
      if (!row.live) {
        continue;
      }
      this._unlink(rid);
      this._row_retire(rid);
      n += 1;
    }
    return n;
  }
  destroy(h) {
    if ((h in this.row_of)) {
      return (this.disconnect(h) ? 1 : 0);
    }
    return this.node_destroy(h);
  }
  destroy_all(hs) {
    let n = 0;
    for (const h of hs) {
      n += this.destroy(h);
    }
    return n;
  }
  _forget_index(h) {
    if ((h in this.tags_out)) {
{
        const _jac_del_1814_13_0_c = this.tags_out;
        _jac.poly.destroy(_jac.poly.getitem(_jac_del_1814_13_0_c, h));
        _jac.poly.delitem(_jac_del_1814_13_0_c, h);
      }
    }
    if ((h in this.tags_in)) {
{
        const _jac_del_1817_13_0_c = this.tags_in;
        _jac.poly.destroy(_jac.poly.getitem(_jac_del_1817_13_0_c, h));
        _jac.poly.delitem(_jac_del_1817_13_0_c, h);
      }
    }
    if ((h in this.holes_out)) {
{
        const _jac_del_1820_13_0_c = this.holes_out;
        _jac.poly.destroy(_jac.poly.getitem(_jac_del_1820_13_0_c, h));
        _jac.poly.delitem(_jac_del_1820_13_0_c, h);
      }
    }
    if ((h in this.holes_in)) {
{
        const _jac_del_1823_13_0_c = this.holes_in;
        _jac.poly.destroy(_jac.poly.getitem(_jac_del_1823_13_0_c, h));
        _jac.poly.delitem(_jac_del_1823_13_0_c, h);
      }
    }
  }
  drop_node(h) {
    let n = this.node_destroy(h);
    this._forget_index(h);
    if ((h in this.adj)) {
      _jac.dict.pop(this.adj, h);
    }
    if ((h in this.dead)) {
      _jac.dict.pop(this.dead, h);
    }
    return n;
  }
  region_died(rgn) {
    let a;
    let row;
    let ta;
    let sa;
    if (!(rgn in this.regions)) {
      return 0;
    }
    let members = this.regions[rgn];
{
      const _jac_del_1844_9_0_c = this.regions;
      _jac.poly.destroy(_jac.poly.getitem(_jac_del_1844_9_0_c, rgn));
      _jac.poly.delitem(_jac_del_1844_9_0_c, rgn);
    }
    let stash = [];
    for (const h of members) {
      if ((h in this.adj)) {
        a = this.adj[h];
        if (((a.out != null) || (a.inn != null))) {
          this.light_detach(h);
        }
        stash.push(a);
        _jac.dict.pop(this.adj, h);
      }
      this._forget_index(h);
      if ((h in this.dead)) {
        _jac.dict.pop(this.dead, h);
      }
    }
    let n = 0;
    for (const a of stash) {
      for (const rid of a.rows_out) {
        if ((rid < 0)) {
          continue;
        }
        row = this.rows.at(rid);
        if (!row.live) {
          continue;
        }
        if ((row.tgt in this.adj)) {
          ta = this.adj[row.tgt];
          this._drop_side(row.tgt, ta, rid, false);
        }
        this._row_retire(rid);
        n += 1;
      }
      for (const rid of a.rows_in) {
        if ((rid < 0)) {
          continue;
        }
        row = this.rows.at(rid);
        if (!row.live) {
          continue;
        }
        if ((row.src in this.adj)) {
          sa = this.adj[row.src];
          this._drop_side(row.src, sa, rid, true);
        }
        this._row_retire(rid);
        n += 1;
      }
    }
    return n;
  }
}
function _new_graph() {
  return new OspGraph({adj: {}, rows: [], free_rows: [], row_of: {}, dead: {}, regions: {}});
}
let DEFAULT_GRAPH = _new_graph();
function osp_adj_fill(origin, dir, out) {
  let row;
  let ad;
  let peers;
  let ai;
  let srcs;
  if (!(origin in DEFAULT_GRAPH.adj)) {
    return 0;
  }
  let start = out.length;
  let a = DEFAULT_GRAPH.adj[origin];
  if ((dir === 2)) {
    for (const rid of a.rows_out) {
      if ((rid < 0)) {
        continue;
      }
      row = DEFAULT_GRAPH.rows.at(rid);
      if (row.live) {
        out.push(row.tag);
        out.push(row.tgt);
      }
    }
    ad = a.out;
    if ((ad != null)) {
      for (const k of Object.keys(ad)) {
        peers = ad[k];
        for (const t of peers) {
          out.push(k);
          out.push(t);
        }
      }
    }
  } else {
    for (const rid of a.rows_in) {
      if ((rid < 0)) {
        continue;
      }
      row = DEFAULT_GRAPH.rows.at(rid);
      if (row.live) {
        out.push(row.tag);
        out.push(row.src);
      }
    }
    ai = a.inn;
    if ((ai != null)) {
      for (const k of Object.keys(ai)) {
        srcs = ai[k];
        for (const t of srcs) {
          out.push(k);
          out.push(t);
        }
      }
    }
  }
  return Math.floor((out.length - start) / 2);
}
function osp_adj_pairs(origin, dir) {
  let out = [];
  osp_adj_fill(origin, dir, out);
  return out;
}
function osp_has_edge(eh) {
  return (DEFAULT_GRAPH.has_edge(eh) ? 1 : 0);
}
function osp_conn(src, tgt, eobj, undirected, edge_tag, rgn_src, rgn_tgt) {
  return DEFAULT_GRAPH.connect(src, tgt, eobj, (undirected !== 0), edge_tag, rgn_src, rgn_tgt);
}
function osp_refs(origin, dir, edge_tag, edges_only) {
  return DEFAULT_GRAPH.refs(origin, dir, edge_tag, (edges_only !== 0));
}
function osp_refs_many(origins, dir, edge_tag, edges_only) {
  return DEFAULT_GRAPH.refs_many(origins, dir, edge_tag, (edges_only !== 0));
}
function osp_refs_edge_pred(origins, dir, edge_tag, edges_only, pred) {
  return DEFAULT_GRAPH.refs_edge_pred(origins, dir, edge_tag, (edges_only !== 0), pred);
}
function osp_filter(hs, pred) {
  return DEFAULT_GRAPH.filter_handles(hs, pred);
}
function osp_refs_chain(origins, dirs, tags, edges_only) {
  return DEFAULT_GRAPH.refs_chain(origins, dirs, tags, (edges_only !== 0));
}
function osp_conn_many(srcs, tgts, eobjs, undirected, edge_tag, rgn_src, rgn_tgt) {
  return DEFAULT_GRAPH.conn_many(srcs, tgts, eobjs, (undirected !== 0), edge_tag, rgn_src, rgn_tgt);
}
function osp_disconn_between_pred(src, tgt, dir, edge_tag, pred) {
  return DEFAULT_GRAPH.disconnect_between_pred(src, tgt, dir, edge_tag, pred);
}
function osp_disconn_between_many(srcs, tgts, dir, edge_tag) {
  return DEFAULT_GRAPH.disconnect_between_many(srcs, tgts, dir, edge_tag);
}
function osp_wrap1(x) {
  let out = [];
  out.push(x);
  return out;
}
function osp_edge_peer(edge_handle, origin) {
  return DEFAULT_GRAPH.edge_peer(edge_handle, origin);
}
function osp_conn_light(src, tgt, edge_tag, one_sided) {
  return DEFAULT_GRAPH.connect_light(src, tgt, edge_tag, (one_sided !== 0));
}
function osp_light_remove(src, tgt, edge_tag) {
  return (DEFAULT_GRAPH.light_remove_one(src, tgt, edge_tag) ? 1 : 0);
}
function osp_light_pairs(h, outgoing) {
  return DEFAULT_GRAPH.light_pairs(h, (outgoing !== 0));
}
function osp_light_detach(h) {
  return DEFAULT_GRAPH.light_detach(h);
}
function osp_has_light(h) {
  return (DEFAULT_GRAPH.has_light(h) ? 1 : 0);
}
function osp_light_disconn_between(src, tgt, dir, edge_tag) {
  return DEFAULT_GRAPH.light_disconnect_between(src, tgt, dir, edge_tag);
}
function osp_drop_node(h) {
  return DEFAULT_GRAPH.drop_node(h);
}
function osp_forget_node(h) {
  if ((h in DEFAULT_GRAPH.adj)) {
    DEFAULT_GRAPH.drop_node(h);
  } else if ((h in DEFAULT_GRAPH.dead)) {
    _jac.dict.pop(DEFAULT_GRAPH.dead, h);
  }
}
function osp_pin_refs() {
  DEFAULT_GRAPH.pin_refs = true;
}
function osp_unpinned_count() {
  return DEFAULT_GRAPH.unpinned.length;
}
function osp_take_unpinned() {
  let out = DEFAULT_GRAPH.unpinned;
  DEFAULT_GRAPH.unpinned = [];
  return out;
}
function osp_disconn_between(src, tgt, dir, edge_tag) {
  return DEFAULT_GRAPH.disconnect_between(src, tgt, dir, edge_tag);
}
function osp_disconnect(edge_handle) {
  return (DEFAULT_GRAPH.disconnect(edge_handle) ? 1 : 0);
}
function osp_is_dead(addr) {
  return (DEFAULT_GRAPH.is_dead(addr) ? 1 : 0);
}
function osp_node_destroy(addr) {
  return DEFAULT_GRAPH.node_destroy(addr);
}
function osp_destroy(h) {
  return DEFAULT_GRAPH.destroy(h);
}
function osp_destroy_all(hs) {
  return DEFAULT_GRAPH.destroy_all(hs);
}
function osp_region_died(rgn) {
  return DEFAULT_GRAPH.region_died(rgn);
};

if (!globalThis.__jacOspCore) {
  globalThis.__jacOspCore = {
    O: [null], H: new Map(),
    osp_conn, osp_conn_many, osp_refs, osp_refs_many, osp_refs_edge_pred,
    osp_wrap1, osp_destroy, osp_is_dead,
    osp_disconn_between, osp_disconn_between_many, osp_disconn_between_pred,
    osp_edge_peer,
    osp_spawn, osp_visit, osp_report, osp_disengage, osp_forget,
    osp_register_type, osp_register_desc, osp_node_desc, osp_is_a,
    OspWalkerDesc, OspNodeDesc, OspSlot, OspRuntime
  };
}
var __ospC = globalThis.__jacOspCore;
var __ospO = __ospC.O;
var __ospH = __ospC.H;
var __ospGenericEdge = globalThis.__jacOspGenericEdge ??= class __ospGenericEdge {};
function __ospId(o) {
  if (o == null) return 0;
  let h = __ospH.get(o);
  if (h === undefined) { h = __ospO.length; __ospO.push(o); __ospH.set(o, h); }
  return h;
}
function __ospConnW(src, tgt, mkEdge, undirected, tag = -1, edgesOnly = false) {
  const srcs = Array.isArray(src) ? src : [src];
  const tgts = Array.isArray(tgt) ? tgt : [tgt];
  for (const value of [...srcs, ...tgts]) {
    if (value === null || typeof value !== "object" || Array.isArray(value)) {
      throw new TypeError("connect operands must be nodes or flat collections of nodes");
    }
  }
  const sh = srcs.map(__ospId);
  const th = tgts.map(__ospId);
  const eh = [];
  for (let i = 0; i < sh.length * th.length; i++) eh.push(__ospId(mkEdge()));
  const r = __ospC.osp_conn_many(sh, th, eh, undirected ? 1 : 0, tag, 0, 0);
  if (r < 0) throw new Error("cannot connect a destroyed node");
  return edgesOnly ? eh.map((h) => __ospO[h]) : tgt;
}
function __ospRefsW(origin, dir, tag = -1, edgesOnly = 0, pred = null) {
  const oh = __ospId(origin);
  if (pred === null) {
    return __ospC.osp_refs(oh, dir, tag, edgesOnly ? 1 : 0).map((h) => __ospO[h]);
  }
  return __ospC.osp_refs_edge_pred(
    [oh], dir, tag, edgesOnly ? 1 : 0, (eh) => !!pred(__ospO[eh])
  ).map((h) => __ospO[h]);
}
function __ospRefsManyW(objs, dir, tag = -1, edgesOnly = 0, pred = null) {
  const hs = [];
  for (const o of objs) hs.push(__ospId(o));
  if (pred === null) {
    return __ospC.osp_refs_many(hs, dir, tag, edgesOnly ? 1 : 0).map((h) => __ospO[h]);
  }
  return __ospC.osp_refs_edge_pred(
    hs, dir, tag, edgesOnly ? 1 : 0, (eh) => !!pred(__ospO[eh])
  ).map((h) => __ospO[h]);
}
function __ospDestroyW(x, strict = false) {
  // `del` on a value target: flatten through arrays, sets, map values and
  // plain-object values and destroy every archetype found. Strict, as the
  // Python backend's `destroy(..., strict=True)`: a leaf that is not a graph
  // object raises before anything is destroyed.
  const seen = new Set();
  const stack = [x];
  const found = [];
  while (stack.length) {
    const v = stack.pop();
    if (v !== null && v !== undefined && typeof v === "object") {
      const h = __ospH.get(v);
      if (h !== undefined) { found.push(h); continue; }
      if (seen.has(v)) continue;
      if (Array.isArray(v) || v instanceof Set) { seen.add(v); for (const e of v) stack.push(e); continue; }
      if (v instanceof Map) { seen.add(v); for (const e of v.values()) stack.push(e); continue; }
      if (Object.getPrototypeOf(v) === Object.prototype) { seen.add(v); for (const e of Object.values(v)) stack.push(e); continue; }
    }
    if (strict) {
      throw new TypeError("cannot destroy " + (v === null ? "None" : typeof v)
        + ": a `del` value target must yield nodes, edges or archetypes");
    }
  }
  let n = 0;
  for (const h of found) { n += __ospC.osp_destroy(h); __ospC.osp_forget(h); }
  return n;
}
function __ospLiveStarts(starts) {
  for (const o of starts) {
    if (__ospC.osp_is_dead(__ospId(o))) {
      throw new Error("cannot spawn on a destroyed graph object");
    }
  }
  return starts;
}
function __ospDiscBetweenW(a, b, dir, tag = -1) {
  const as = Array.isArray(a) ? a : [a];
  const bs = Array.isArray(b) ? b : [b];
  return __ospC.osp_disconn_between_many(as.map(__ospId), bs.map(__ospId), dir, tag);
}
function __ospDiscBetweenPredW(a, b, dir, tag, pred) {
  return __ospC.osp_disconn_between_pred(
    __ospId(a), __ospId(b), dir, tag, (eh) => !!pred(__ospO[eh])
  );
}
;
if (typeof Health !== "undefined") Health.prototype.__tag = 4688060283586735;
__ospC.osp_register_type(4688060283586735, [4688060283586735]);
__ospGenericEdge.prototype.__tag = 6741604257242899;
__ospC.osp_register_type(6741604257242899, []);;
__ospC.osp_register_desc(4688060283586735, new __ospC.OspWalkerDesc({type_tag: 4688060283586735, entry: [new __ospC.OspSlot({trig_tag: -1, fn: (o, x) => o.check(x)})], exit: []}));
var __ospRT = globalThis.__jacOspRT ??= new __ospC.OspRuntime({tag_of: (h) => h.__tag, is_a: (t, b) => __ospC.osp_is_a(t, b), node_desc: (t) => __ospC.osp_node_desc(t), on_complete: (s, ok) => { if (s.wlk && !s.nested) s.wlk.reports = s.reports; }});;
export {Health, HealthStatus};
if (typeof globalThis !== "undefined") { if (!globalThis.__jacEndpointEffects__) globalThis.__jacEndpointEffects__ = {}; Object.assign(globalThis.__jacEndpointEffects__, {"[\"\",\"api.jac\",\"walker\",\"Health\"]": {"app": "", "module": "api.jac", "kind": "walker", "name": "Health", "reads": ["*"], "writes": ["*"], "assumptions": [], "unknown": true, "observed_tags": ["Root"]}}); };
//# sourceMappingURL=api.js.map
