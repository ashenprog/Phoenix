def:pub ChaosLab(
    scenario: str,
    onScenarioChange: Callable[[str], None],
) -> JsxElement {
    def handle_normal(_e: MouseEvent) {
        onScenarioChange("NORMAL");
    }

    def handle_primary_503(_e: MouseEvent) {
        onScenarioChange("PRIMARY_503");
    }

    def handle_timeout(_e: MouseEvent) {
        onScenarioChange("TEMP_TIMEOUT");
    }

    def handle_invalid_output(_e: MouseEvent) {
        onScenarioChange("INVALID_OUTPUT");
    }

    def handle_permission_denied(_e: MouseEvent) {
        onScenarioChange("PERMISSION_DENIED");
    }

    normal_class = "scenario-option";
    api_503_class = "scenario-option";
    timeout_class = "scenario-option";
    invalid_output_class = "scenario-option";
    permission_denied_class = "scenario-option";
    if scenario == "NORMAL" {
        normal_class = "scenario-option scenario-option-selected";
    }
    if scenario == "PRIMARY_503" {
        api_503_class = "scenario-option scenario-option-selected";
    }
    if scenario == "TEMP_TIMEOUT" {
        timeout_class = "scenario-option scenario-option-selected";
    }
    if scenario == "INVALID_OUTPUT" {
        invalid_output_class = "scenario-option scenario-option-selected";
    }
    if scenario == "PERMISSION_DENIED" {
        permission_denied_class = "scenario-option scenario-option-selected";
    }

    return <div className="scenario-field">
        <span className="field-label" id="scenario-label">Chaos Lab · choose a scenario</span>
        <div className="scenario-options" role="group" aria-labelledby="scenario-label">
            <button
                className={normal_class}
                type="button"
                aria-pressed={scenario == "NORMAL"}
                onClick={handle_normal}
            >Normal</button>
            <button
                className={api_503_class}
                type="button"
                aria-pressed={scenario == "PRIMARY_503"}
                onClick={handle_primary_503}
            >API 503</button>
            <button
                className={timeout_class}
                type="button"
                aria-pressed={scenario == "TEMP_TIMEOUT"}
                onClick={handle_timeout}
            >Timeout</button>
            <button
                className={invalid_output_class}
                type="button"
                aria-pressed={scenario == "INVALID_OUTPUT"}
                onClick={handle_invalid_output}
            >Invalid Output</button>
            <button
                className={permission_denied_class}
                type="button"
                aria-pressed={scenario == "PERMISSION_DENIED"}
                onClick={handle_permission_denied}
            >Permission Denied</button>
        </div>
        <p className="scenario-note">All fault scenarios are controlled simulations. Your selection is sent to start_run; the UI does not fake failures.</p>
    </div>;
}