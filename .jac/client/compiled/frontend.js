/* Source: /mnt/c/Users/User/Documents/My Projects/JAC/frontend.jac */
import {__jacJsx, __jacSpawn} from "@jac/runtime";
import "./api.js";
import { useJacState } from "@jac/runtime";
import { useEffect } from "@jac/runtime";
import { _jac } from "@jac/prelude";
function App() {
  const __jacS_task = useJacState("");
  const setTask = __jacS_task.set;
  const __jacS_connection = useJacState("");
  const setConnection = __jacS_connection.set;
  const __jacS_error = useJacState("");
  const setError = __jacS_error.set;
  useEffect(() => {
    loadHealth();
  }, []);
  async function loadHealth() {
    let result;
    let got;
    try {
      result = await __jacSpawn("Health", "", {}, {"contract": "[\"\",\"api.jac\",\"walker\",\"Health\"]"});
      if (_jac.builtin.bool(_jac.poly.and_(result.reports, () => (result.reports.length > 0)))) {
        got = result.reports[0];
        __jacS_connection.set(`ok=${got.ok} service=${got.service}`);
      }
    } catch (__jac_e) {
      if (_jac.exc.matches(__jac_e, "Exception")) {
        let e = __jac_e;
        __jacS_error.set(`${e}`);
      } else {
        throw __jac_e;
      }
    }
  }
  return __jacJsx("div", {"style": {"minHeight": "100vh", "backgroundColor": "#0B1020", "color": "#F8FAFC", "fontFamily": "system-ui, -apple-system, sans-serif"}}, [__jacJsx("div", {"style": {"maxWidth": "720px", "margin": "0 auto", "padding": "2rem 1rem", "display": "flex", "flexDirection": "column", "gap": "1rem"}}, [__jacJsx("h1", {"style": {"margin": "0", "fontSize": "1.75rem", "letterSpacing": "0.08em"}}, ["PHOENIX"]), __jacJsx("div", {"style": {"backgroundColor": "#151C2F", "borderRadius": "8px", "padding": "1rem", "display": "flex", "flexDirection": "column", "gap": "0.75rem"}}, [__jacJsx("textarea", {"value": __jacS_task.val, "onChange": e => {
    __jacS_task.set(e.target.value);
  }, "placeholder": "Research task", "style": {"width": "100%", "minHeight": "6rem", "boxSizing": "border-box", "padding": "0.75rem", "borderRadius": "6px", "border": "1px solid #94A3B8", "backgroundColor": "#0B1020", "color": "#F8FAFC", "resize": "vertical"}}, []), __jacJsx("button", {"type": "button", "disabled": true, "style": {"alignSelf": "flex-start", "padding": "0.6rem 1.2rem", "backgroundColor": "#F97316", "color": "#0B1020", "border": "none", "borderRadius": "6px"}}, ["Start Task"])]), __jacJsx("div", {"style": {"backgroundColor": "#151C2F", "borderRadius": "8px", "minHeight": "8rem", "padding": "1rem"}}, []), __jacJsx("p", {"style": {"margin": "0", "color": "#94A3B8", "minHeight": "1.25rem"}}, [__jacS_error.val, __jacS_connection.val])])]);
}
const app = App;
/*jac:refresh-boundary*/;
export {app};
//# sourceMappingURL=frontend.js.map
