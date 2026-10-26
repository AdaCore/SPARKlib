"""Include the detailed analysis report in proof-test baselines.

The report records which entities were analyzed and their SPARK and analysis
status. Its banner, source line numbers, and check counts are omitted from
baselines, along with the summary table and prover statistics.
"""

from pathlib import Path
import re

from e3.testsuite.driver.diff import OutputRefiner


ANALYSIS_HEADER = (
    "========================\n"
    "Detailed analysis report\n"
    "========================\n"
)


def normalize_analysis_report(analysis):
    """Remove source line and column numbers and flow and proof check counts"""
    analysis = re.sub(r"(\.ad[bs](?:\.in)?):\d+(?::\d+)?", r"\1", analysis)
    analysis = re.sub(r"(\bflow analyzed \(\d+ errors), \d+ checks,", r"\1,", analysis)
    analysis = re.sub(r"( and proved) \(\d+ checks\)", r"\1", analysis)
    analysis = re.sub(
        r"( and not proved),\s*\d+ checks out of\s*\d+ proved", r"\1", analysis
    )
    return analysis.strip("\n") + "\n"


def analysis_report(working_dir):
    """Read the sole gnatprove.out and return its normalized analysis section"""
    reports = sorted(Path(working_dir).rglob("gnatprove.out"))
    if len(reports) != 1:
        raise RuntimeError(f"expected one gnatprove.out, found {len(reports)}")

    _, header, analysis = reports[0].read_text().partition(ANALYSIS_HEADER)
    if not header or not analysis.strip():
        raise RuntimeError("gnatprove.out has no detailed analysis report")

    return normalize_analysis_report(analysis)


class SortDiagnosticsRefiner(OutputRefiner):
    """Sort parallel diagnostics while preserving the ordered analysis report"""

    def refine(self, output):
        report = re.search(r"(?m)^Analyzed \d+ units?$", output)
        diagnostics = output if report is None else output[: report.start()]
        analysis = "" if report is None else output[report.start() :]
        diagnostics = "\n".join(sorted(diagnostics.strip("\n").splitlines()))
        separator = "\n\n" if diagnostics and analysis else ""
        return diagnostics + separator + analysis
