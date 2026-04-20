---
layout: single
title: "Salesforce Governor Limits: The Architecture of Multi-tenancy"
date: 2026-04-07
categories:
  - Concepts
tags:
  - Apex
  - Salesforce
  - GovernorLimits
  - BestPractices
---

Salesforce Governor Limits are arguably the most critical concept for anyone working with the Salesforce platform. Whether you're a developer, administrator, or architect, understanding these guardrails is fundamental to building scalable, reliable, and enterprise-grade solutions.

---

## 🏗️ Why Do Governor Limits Exist?

Salesforce is a **SaaS (Software as a Service)** platform built on a **multi-tenant architecture**. This means thousands of organizations share the same underlying infrastructure, compute resources, and database instances.

Imagine living in a luxury apartment complex. If one tenant uses all the water, every other resident suffers. To guarantee **fair resource allocation** and **consistent performance** across all tenants, Salesforce enforces Governor Limits. Without these guardrails, a single inefficient script could degrade performance for every customer on that pod.

### The "Anti-pattern": SOQL inside a Loop
```java
// This innocent-looking code could bring down an entire pod
for (Account acc : Trigger.new) {
    // This is the "N+1" problem. SOQL inside a loop = disaster.
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}
```

### The "Architect" Way: Bulkification
```java
// Always query outside the loop using Collections (Set/Map)
Set<Id> accIds = Trigger.newMap.keySet();
List<Contact> relatedCons = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accIds];
```

---

## 1. Key Limits You Must Know

As an architect, you must design your logic to fit within these constraints. Leveraging **Asynchronous Apex** is a primary strategy for handling heavy workloads.

| Resource | Synchronous | Asynchronous |
| :--- | :--- | :--- |
| **SOQL Queries** | 100 | 200 |
| **Query Rows** | 50,000 | 50,000 |
| **DML Statements** | 150 | 150 |
| **DML Rows** | 10,000 | 10,000 |
| **CPU Time** | 10,000 ms | 60,000 ms |
| **Heap Size** | 6 MB | 12 MB |

** Critical Note:** Unlike standard exceptions, a `System.LimitException` **cannot be caught** with a `try-catch` block. Once you breach a limit, the entire transaction terminates and rolls back immediately.

###  Proactive Monitoring with the `Limits` Class
Build "self-aware" code by monitoring resource usage in real-time. This is essential for complex logic that might approach platform thresholds.

| Method | Description | Return Value |
|:---|:---|:---|
| `Limits.getQueries()` | SOQL queries issued so far | Current count |
| `Limits.getLimitQueries()` | Maximum allowed SOQL | 100 / 200 |
| `Limits.getDMLStatements()` | DML statements issued | Current count |
| `Limits.getCpuTime()` | CPU time consumed (ms) | Current usage |
| `Limits.getHeapSize()` | Heap size used (bytes) | Current usage |

---

👉 [Salesforce Official Limits Documentation](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_platform_apexgov.htm)
👉 [Salesforce Multi-tenant Architecture (Trailhead)](https://trailhead.salesforce.com/en/content/learn/modules/starting_force_com/starting_understanding_arch)

