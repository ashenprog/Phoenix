"""PHOENIX optional report wording — deterministic fallback only (no API key)."""

import from models { ModelMode, Scenario }
import from tools { check_report }

def _filter_fixture_source_ids(source_ids: list[str]) -> list[str] {
    filtered: list[str] = [];
    for sid in source_ids {
        if not isinstance(sid, str) or len(sid) == 0 {
            continue;
        }
        if sid in filtered {
            continue;
        }
        probe = {
            "title": "[FIXTURE] probe",
            "executive_summary": "probe",
            "findings": ["probe"],
            "recommendations": ["probe"],
            "source_ids": filtered + [sid],
        };
        if check_report("ai-filter", Scenario.NORMAL, probe)["ok"] {
            filtered.append(sid);
        }
    }
    if len(filtered) == 0 {
        filtered = ["fixture-primary-1"];
    }
    return filtered;
}

def _normalize_findings(findings: list[str]) -> list[str] {
    out: list[str] = [];
    for item in findings {
        text = str(item).strip();
        if len(text) > 0 {
            out.append(text);
        }
    }
    if len(out) == 0 {
        out = ["[FIXTURE] Summary from verified fixture excerpts only."];
    }
    return out;
}

def compose_report(
    prompt: str,
    findings: list[str],
    source_ids: list[str],
) -> dict[str, any] {
    safe_ids = _filter_fixture_source_ids(source_ids);
    norm_findings = _normalize_findings(findings);
    report_doc = {
        "title": f"[FIXTURE] Research: {prompt}",
        "executive_summary": (
            "Deterministic template report from verified fixture sources. "
            "Not live web research."
        ),
        "findings": norm_findings,
        "recommendations": [
            "Use bounded retries and approved backup tools for agent workflows.",
            "Label simulated faults clearly in demos.",
        ],
        "source_ids": safe_ids,
    };
    verified = check_report("ai-compose", Scenario.NORMAL, report_doc);
    explanation = (
        "Report composed in DETERMINISTIC_FALLBACK mode using fixture source IDs only."
    );
    if not verified["ok"] {
        explanation = (
            "DETERMINISTIC_FALLBACK report failed schema check; using minimal fixture template."
        );
        report_doc = {
            "title": "[FIXTURE] Research report",
            "executive_summary": "Minimal deterministic fixture report.",
            "findings": norm_findings,
            "recommendations": ["Continue monitoring agent reliability."],
            "source_ids": ["fixture-primary-1"],
        };
    }
    return {
        "report": report_doc,
        "model_mode": ModelMode.DETERMINISTIC_FALLBACK,
        "explanation": explanation,
    };
}

def explain_recovery(category: str, strategy: str, reason: str) -> dict[str, any] {
    text = (
        f"Observed {category}; deterministic policy selected {strategy}: {reason}"
    );
    return {
        "text": text,
        "model_mode": ModelMode.DETERMINISTIC_FALLBACK,
    };
}
