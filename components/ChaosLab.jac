def:pub ChaosLab(
    scenario: str,
    onScenarioChange: Callable[[str], None],
) -> JsxElement {
    def handle_scenario_change(e: ChangeEvent) {
        onScenarioChange(e.target.value);
    }

    return <div className="scenario-field">
        <label className="field-label" htmlFor="scenario-select">Test scenario</label>
        <select
            id="scenario-select"
            className="scenario-select"
            value={scenario}
            onChange={handle_scenario_change}
        >
            <option value="NORMAL">Normal run</option>
            <option value="PRIMARY_503">Simulated API 503</option>
            <option value="TEMP_TIMEOUT">Simulated timeout</option>
            <option value="INVALID_OUTPUT">Simulated invalid output</option>
            <option value="PERMISSION_DENIED">Simulated permission denied</option>
        </select>
        <p className="scenario-note">Fault scenarios are requested from the backend; the dashboard does not fake run outcomes.</p>
    </div>;
}