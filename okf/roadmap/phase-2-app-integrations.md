---
type: RoadmapPhase
title: "Phase 2: App integrations"
status: planned
description: Read/act on data in other apps (mail, calendar) through chat commands.
tags: [roadmap, integrations]
---

# Phase 2: App integrations

## Goal

"Show me today's mail", "write and send this email" — without opening Gmail.

## Approach

- Prefer official APIs (Gmail REST API + OAuth) over UI automation wherever
  an API exists — far more reliable than screen scraping.
- For apps without an API, fall back to Android AccessibilityService-based
  UI automation (native Kotlin, bridged like the existing
  [native-bridge](../architecture/native-bridge.md)).
- New tools register in [tool-registry](../services/tool-registry.md)
  alongside the existing 18 device tools, following the same
  confirm-before-execute pattern in [tools-service](../services/tools-service.md).

## Depends on

- [Phase 1](phase-1-local-model.md) — agent needs to actually understand
  requests before it can act on them reliably.
