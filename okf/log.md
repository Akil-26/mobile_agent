# Log

## 2026-06-30

- Created initial OKF v0.1 bundle from a full repo trace (not from the
  pre-existing .md docs, which overstate native-inference readiness).
- Documented confirmed bug: native LLM inference pipeline disconnected end
  to end (fake `.so`, unregistered channel, mismatched channel name,
  hardcoded-false availability flag). See `issues/native-inference-disconnected.md`.
- Logged 3-phase roadmap: local model (fllama swap-in) -> app integrations
  (Gmail API + accessibility automation) -> voice trigger (wake-word service).
