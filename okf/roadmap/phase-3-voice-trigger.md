---
type: RoadmapPhase
title: "Phase 3: Voice trigger"
status: planned
description: Always-listening wake-word access to the agent without opening the app.
tags: [roadmap, voice]
---

# Phase 3: Voice trigger

## Goal

Talk to the agent without opening the app.

## Approach

Always-listening wake-word service (e.g. Porcupine) running in an Android
foreground service. Requires a visible "listening" indicator, in-app
disclosure, and a privacy policy before any future Play Store submission —
background mic access is heavily scrutinized in review.

## Depends on

- [Phase 1](phase-1-local-model.md)
- [Phase 2](phase-2-app-integrations.md) — voice is most useful once the
  agent can actually do things, not just chat.
