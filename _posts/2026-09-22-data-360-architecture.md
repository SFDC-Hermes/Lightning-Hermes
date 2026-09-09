---
layout: single
title: "Salesforce Data 360 Architecture: Decoding Data Streams, DLOs, DMOs, Queries & Pricing"
date: 2026-10-06
categories:
  - Development
tags:
  - Salesforce
  - Data 360
  - Architecture
  - DataStream
  - DLO
  - DMO
---

When building advanced AI Agents like **Agentforce** or designing complex multi-system integrations, writing standard SOQL inside Salesforce is no longer enough. Enterprise architectures require a unified data layer capable of ingesting petabytes of structured and unstructured data, harmonizing it, and serving it in real time. This layer is **Salesforce Data Cloud**.

To master Data Cloud, an architect must understand how raw data flows from external sources into harmonized models, how to query them efficiently, and how platform usage translates into financial costs. 

This guide breaks down the core data pipeline (**Data Stream ➔ DLO ➔ DMO**), query patterns, and the Data Cloud credit consumption model.

## 1. The Core Pipeline: Data Stream, DLO, and DMO Relationships

Data in Data Cloud does not magically appear in a usable state. It flows through a strict, multi-tier pipeline that transforms raw external records into standardized, unified business entities.

```text
┌────────────────────────┐        Ingests       ┌──────────────────────┐        Maps         ┌──────────────────────┐
│  External Data Source  │ ───────────────────► │  Data Lake Object    │ ──────────────────► │ Data Model Object    │
│  (CRM, S3, Snowflake)  │                      │       (DLO)          │                     │       (DMO)          │
└────────────────────────┘                      └──────────────────────┘                     └──────────────────────┘
    (Data Stream)                                (Raw / Tabular Schema)                       (Harmonized / Unified)
```
