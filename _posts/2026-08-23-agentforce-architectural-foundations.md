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

### 1.1 Main Agent: The Sovereign Entry Point

The **Main Agent** represents the primary persona and system interface exposed to users or external channels (e.g., Experience Cloud, Messaging for In-App, Slack). It maintains global conversation memory, establishes the overarching tone, and delegates incoming requests to specialized sub-domains using the Atlas Engine.

### 1.2 Sub-Agents (Topics): Domain Specialization Boundaries

A **Sub-Agent** (historically structured as a *Topic* within the Builder) acts as a specialized subject matter expert. It encapsulates a specific business capability—such as Order Management, Technical Troubleshooting, or Lead Qualification. Each Sub-Agent contains localized instructions, scope constraints, and an assigned suite of Actions.

### 1.3 Actions: The Deterministic Workhorses

**Actions** are the atomic, deterministic capabilities assigned to Sub-Agents. While the Main Agent and Sub-Agents handle *reasoning and routing*, Actions handle *execution*. They directly bridge AI reasoning with backend platform capabilities, leveraging standard Salesforce metadata like Apex classes, Auto-launched Flows, Prompt Templates, and MuleSoft API integrations.

## 2. Architectural Comparison Matrix

Understanding where logic resides is critical to preventing intent leakage and ensuring enterprise data security.

| Architectural Layer | Role & Responsibility | Reasoning Level | Primary Configuration Asset |
| --- | --- | --- | --- |
| **Main Agent** | Global routing, channel exposure, system identity, overarching guardrails. | High-Level Intent Classification | System Persona, Global Guardrails |
| **Sub-Agent (Topic)** | Contextual domain execution, local instruction scoping, capability classification. | Tactical Domain Reasoning | Natural Language Instructions, Scope Rules |
| **Actions** | Executing discrete backend tasks (CRUD operations, external HTTP calls, calculations). | Zero (Purely Deterministic) | Apex, Flow, Prompt Template, MuleSoft |

---

## 3. Decision Framework: When to Use What?

Designing an efficient Agentforce implementation requires placing requirements into the correct layer of the hierarchy.

### 🏢 When to Configure the Main Agent

* **Single Front-Door Strategy:** You need a unified conversational endpoint across digital channels that handles authentication and global context.
* **Global Security Guardrails:** You must enforce top-level policy constraints (e.g., "Never disclose internal employee IDs regardless of user prompt").
* **Cross-Domain Routing:** The user's query may jump between vastly different business units (e.g., moving from a product inquiry to a billing dispute in a single session).

### 🎯 When to Create Sub-Agents (Topics)

* **Domain Separation:** When logic requires distinct business rules. For instance, `Billing_Support` requires access to financial records and payment gateways, whereas `Field_Service_Support` needs access to Work Orders and Asset telemetry.
* **Instruction Scoping:** When detailed instructions would pollute the global prompt context. Grouping instructions into specialized Sub-Agents keeps the reasoning engine fast, accurate, and cost-effective.
* **Role-Based Capability Scoping:** When certain business operations should only activate under specific contextual domains.

### ⚙️ When to Build Actions

* **Data Mutations & Side Effects:** Creating, updating, or deleting Salesforce records (e.g., updating an Account address or closing a Case).
* **Deterministic Computations:** Calculating loan interest, complex pricing matrix evaluation, or inventory checks that require exact math rather than probabilistic AI estimates.
* **External System Integration:** Calling third-party REST APIs via HTTP Callouts, MuleSoft Anypoint endpoints, or External Services.
* **Structured Content Generation:** Executing a strict **Prompt Template** to summarize a Case or draft an email response.

---

## 4. Architect's Best Practices for Agentforce Builder

1. **Keep Actions Atomic and Single-Purpose:** Do not build a single monolithic Apex Action that updates five unrelated objects. Keep Actions granular (e.g., `Get_Invoice_Details`, `Process_Refund`) so the Atlas Engine can chain them dynamically based on user intent.
2. **Enforce Strict Sub-Agent Boundaries:** Write explicit negative guidelines in your Sub-Agent instructions (e.g., *"Do NOT attempt to process refunds in this Topic; redirect to the Billing Sub-Agent"*). This prevents topic drift.
3. **Never Trust AI for Math or Governance:** Always delegate transactional logic, validation rules, and mathematical operations to deterministic **Actions** (Flow/Apex) rather than relying on natural language reasoning.
4. **Leverage Flow for Safety & Human-in-the-Loop:** When an Action performs a destructive operation (e.g., cancelling a subscription), encapsulate the logic within a Flow that incorporates approval steps or confirmation prompts before execution.

---

## 5. Conclusion

The power of Salesforce Agentforce lies in the separation of concerns. By delegating global entry to the **Main Agent**, domain expertise to **Sub-Agents**, and backend execution to **Actions**, architects can build modular, secure, and highly scalable AI workforces that operate safely within enterprise boundaries.
