# Archived Agent Specs

This directory contains agent specifications that have been archived during the MQL5-focused cleanup of Alpha Logic Hub. These specs are for Nautilus/Python/ONNX/BMAD agents that are outside the current MQL5-only scope.

## Archived Files

| File | Original Purpose | Archive Date |
|------|-----------------|--------------|
| `nautilus-trader-architect.md` | Nautilus Trader Python framework architecture | 2026-05-26 |
| `nautilus-nano.md` | Nautilus Nano lightweight trading agent | 2026-05-26 |
| `forge-mql5-architect.md` | Forge MQL5 architect (superseded by modular `.factory/droids/`) | 2026-05-26 |
| `onnx-model-builder.md` | ONNX model building and integration | 2026-05-26 |
| `bmad-builder.md` | BMAD (Bayesian Market Anomaly Detector) builder | 2026-05-26 |
| `forge-mql5-architect-v5.1-LEAN.md` | Forge MQL5 LEAN variant | Pre-2026-05 |
| `forge-mql5-architect-v5.2-GENIUS.md` | Forge MQL5 GENIUS variant | Pre-2026-05 |

## Rationale

These specs were archived because:
1. **MQL5 focus**: The current roadmap prioritizes MQL5 EA development, backtesting, and risk management
2. **Python/Nautilus scope**: Nautilus Trader and ONMX/BMAD agents belong to a separate Python-based research track
3. **Skill-based architecture**: Agent capabilities are now defined through `.skills/` rather than monolithic agent specs

## Restoration

To restore an archived spec, move it back to `.factory/droids/` and update the agent router in `AGENTS.md`.
