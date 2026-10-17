/* Source: /home/user/.cache/jac/rt/f562f1257227d66d/site/jaclang/client/auth_contract.jac */
class SignupResult {
  constructor(props = {}) {
    this.success = (Object.hasOwn(props, "success") ? props.success : null);
    this.user_id = (Object.hasOwn(props, "user_id") ? props.user_id : "");
    this.error = (Object.hasOwn(props, "error") ? props.error : "");
    this.status = (Object.hasOwn(props, "status") ? props.status : 0);
  }
}
export {SignupResult};
//# sourceMappingURL=auth_contract.js.map
