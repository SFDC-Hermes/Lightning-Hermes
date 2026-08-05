---
layout: single
title: "Agentforce Architecture: Deconstructing Main Agents, Sub-Agents, and Actions"
date: 2026-08-23
categories:
  - Agentforce
tags:
  - Salesforce
  - Agentforce
  - AI
  - Architecture
  - AgentBuilder
---

The Paradigm Shift: From Rule-Based Bots to Autonomous Agents

The enterprise AI landscape in Salesforce has evolved beyond predefined branching logic and static conversational flows. Traditional chatbots relied on rigid decision trees, while early Copilots depended heavily on explicit user prompts to trigger single-step actions.

**Salesforce Agentforce** introduces autonomous execution driven by the **Atlas Reasoning Engine**. Instead of following deterministic IF-THEN paths, Agentforce analyzes user intent, evaluates context, dynamically formulates multi-step execution plans, and executes backend operations safely.
To build scalable, governance-compliant autonomous agents in the **Agent Builder**, architects must master the core structural hierarchy: **Main Agents**, **Sub-Agents (Topics)**, and **Actions**.

## 1. The Core Architecture: The Triad of Agentforce

Agentforce structures conversational and operational intelligence into three distinct functional layers:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                               MAIN AGENT                               │
│  * Global Entry Point & Identity                                       │
│  * Evaluates User Intent via Atlas Reasoning Engine                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                   │
                                   │ Routes Request
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                           SUB-AGENTS / TOPICS                          │
│  * Domain-Specific Expertise (e.g., Billing, Tech Support, Leads)      │
│  * Applies Local Instructions & Boundary Constraints                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                   │
                                   │ Triggers Atomic Logic
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                                ACTIONS                                 │
│  * Deterministic Execution Units (Flows, Apex, Prompt Templates, APIs) │
│  * Interacts with Salesforce CRM Data & External Systems               │
└────────────────────────────────────────────────────────────────────────┘
```
