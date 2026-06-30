---
type: Bundle
title: Mobile Agent — Knowledge Bundle
description: On-device AI assistant Flutter app with tool-calling, native Android bridge, and a roadmap toward full device automation.
okf_version: "0.1"
tags: [flutter, android, llm, agent]
---

# Mobile Agent

A Flutter app that runs an AI assistant on-device, with the long-term goal of
controlling other apps on the phone (read mail, compose and send messages,
trigger actions) through chat and voice, without the user opening those apps
directly.

## Start here

- [Architecture](architecture/index.md) — how the layers fit together
- [Services](services/index.md) — what each service actually does today
- [Known issues](issues/index.md) — gaps between what the docs claim and what the code does
- [Roadmap](roadmap/index.md) — phased plan toward the full agent vision

## Current state in one line

The BLoC/UI/tool-calling scaffolding is solid and working. The on-device LLM
inference path is not — see [native-inference-disconnected](issues/native-inference-disconnected.md).
