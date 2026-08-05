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
└──────────────────────────────────┬────────────────────────────-────────┘
                                   │
                                   │ Routes Request
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                           SUB-AGENTS / TOPICS                          │
│  * Domain-Specific Expertise (e.g., Billing, Tech Support, Leads)      │
│  * Applies Local Instructions & Boundary Constraints                   │
└──────────────────────────────────┬────────────────────────────-────────┘
                                   │
                                   │ Triggers Atomic Logic
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                                ACTIONS                                 │
│  * Deterministic Execution Units (Flows, Apex, Prompt Templates, APIs) │
│  * Interacts with Salesforce CRM Data & External Systems               │
└────────────────────────────────────────────────────────────────────────┘
```

세일즈포스의 최신 AI 아키텍처인 Agentforce(에이전트포스)를 주제로 한 블로그 포스트를 작성했습니다!

Agentforce의 핵심인 **Atlas Reasoning Engine**을 바탕으로, **Main Agent**, **Sub-Agent (Topics)**, 그리고 **Actions**의 3단계 개념 구조와 각 레이어의 역할, 흐름 다이어그램, 비교 표, 그리고 실무 적용 기준을 아키텍트 시각에서 명확하게 정리했습니다.

`2026-08-16-agentforce-architectural-foundations.md` 파일로 작성해 블로그에 올려보세요!

---

```markdown
---
layout: single
title: "Agentforce Architecture: Deconstructing Main Agents, Sub-Agents, and Actions"
date: 2026-08-16
categories:
  - AI
tags:
  - Salesforce
  - Agentforce
  - AI
  - Architecture
  - AgentBuilder
---

## 1. The Paradigm Shift: From Rule-Based Bots to Autonomous Agents

The enterprise AI landscape in Salesforce has evolved beyond predefined branching logic and static conversational flows. Traditional chatbots relied on rigid decision trees, while early Copilots depended heavily on explicit user prompts to trigger single-step actions.

**Salesforce Agentforce** introduces autonomous execution driven by the **Atlas Reasoning Engine**. Instead of following deterministic IF-THEN paths, Agentforce analyzes user intent, evaluates context, dynamically formulates multi-step execution plans, and executes backend operations safely.

To build scalable, governance-compliant autonomous agents in the **Agent Builder**, architects must master the core structural hierarchy: **Main Agents**, **Sub-Agents (Topics)**, and **Actions**.

---

## 2. The Core Architecture: The Triad of Agentforce

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

### 1.1 Main Agent: The Sovereign Entry Point

The **Main Agent** represents the primary persona and system interface exposed to users or external channels (e.g., Experience Cloud, Messaging for In-App, Slack). It maintains global conversation memory, establishes the overarching tone, and delegates incoming requests to specialized sub-domains using the Atlas Engine.

### 1.2 Sub-Agents (Topics): Domain Specialization Boundaries

A **Sub-Agent** (historically structured as a *Topic* within the Builder) acts as a specialized subject matter expert. It encapsulates a specific business capability—such as Order Management, Technical Troubleshooting, or Lead Qualification. Each Sub-Agent contains localized instructions, scope constraints, and an assigned suite of Actions.

### 1.3 Actions: The Deterministic Workhorses

**Actions** are the atomic, deterministic capabilities assigned to Sub-Agents. While the Main Agent and Sub-Agents handle *reasoning and routing*, Actions handle *execution*. They directly bridge AI reasoning with backend platform capabilities, leveraging standard Salesforce metadata like Apex classes, Auto-launched Flows, Prompt Templates, and MuleSoft API integrations.

---