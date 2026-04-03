---
layout: single
title: "Salesforce Governor Limits: Why Every Developer Must Master Them"
date: 2026-04-08
categories:
  - Salesforce
tags:
  - Apex
  - Salesforce
  - GovernorLimits
  - BestPractices
---

Salesforce Governor Limits are arguably the most critical concept for anyone working with the Salesforce platform. Whether you're a developer, administrator, or architect, understanding these limits is fundamental to building scalable and reliable solutions.

---

## Why Do Governor Limits Exist?

Salesforce is a **SaaS (Software as a Service)** platform built on a **multi-tenant architecture**. This means thousands of organizations share the same infrastructure, compute resources, and database instances.

To guarantee **fair resource allocation** and **consistent performance** across all orgs, Salesforce enforces Governor Limits. Without these guardrails, a single poorly written trigger could degrade performance for every customer on that pod.

```java
// This innocent-looking code could bring down an entire pod
for (Account acc : Trigger.new) {
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
    // ❌ SOQL inside a loop = disaster waiting to happen
}
```

1. Key Limits You Must Know
Here are the limits that will impact your daily development:

| Resource | Synchronous | Asynchronous |
| :--- | :--- | :--- |
| **SOQL Queries** | 100 | 200 |
| **Query Rows** | 50,000 | 50,000 |
| **DML Statements** | 150 | 150 |
| **DML Rows** | 10,000 | 10,000 |
| **CPU Time** | 10,000 ms | 60,000 ms |
| **Heap Size** | 6 MB | 12MB |

**How to check Governor Limit in apex**

| Method | Description | Return Value |
|:---|:---|:---|
| `Limits.getQueries()` | Number of SOQL queries issued | Current count |
| `Limits.getLimitQueries()` | Maximum allowed SOQL queries | Sync: 100 / Async: 200 |
| `Limits.getQueryRows()` | Number of records retrieved | Current count |
| `Limits.getLimitQueryRows()` | Maximum records retrievable | 50,000 |
| `Limits.getDMLStatements()` | Number of DML statements issued | Current count |
| `Limits.getLimitDMLStatements()` | Maximum allowed DML statements | 150 |
| `Limits.getDMLRows()` | Number of records processed by DML | Current count |
| `Limits.getLimitDMLRows()` | Maximum records for DML | 10,000 |
| `Limits.getCpuTime()` | CPU time used (milliseconds) | Current usage |
| `Limits.getLimitCpuTime()` | Maximum CPU time allowed | Sync: 10,000ms / Async: 60,000ms |
| `Limits.getHeapSize()` | Heap size used (bytes) | Current usage |
| `Limits.getLimitHeapSize()` | Maximum heap size allowed | Sync: 6MB / Async: 12MB |
| `Limits.getCallouts()` | Number of callouts made | Current count |
| `Limits.getLimitCallouts()` | Maximum callouts allowed | 100 |

---

2. Async Methods at a Glance

| Method | Best For | Max Calls | Chaining | Returns Job ID |
|:---|:---|:---|:---|:---|
| **@future** | Simple callouts | 50/transaction | X | X |
| **Queueable** | Complex jobs with chaining | 50/transaction | O | O |
| **Batch** | Large data (50M+ records) | 5 concurrent | O | O |
| **Scheduled** | Time-based automation | 100/org | O | O |

---

### 🎯 When to Use What?

| Scenario | Use This |
|:---|:---|
| Callout from trigger | `Queueable` |
| Need job tracking | `Queueable` |
| Process 10,000+ records | `Batch Apex` |
| Chain multiple jobs | `Queueable` |
| Daily/weekly tasks | `Scheduled Apex` |

---

### ⚠️ Why You Should Stop Using @future

| @future (Legacy) | Queueable (Recommended) |
|:---|:---|
| X No Job ID returned | O Returns Job ID for monitoring |
| X Primitives only | O Accepts complex types (sObjects, custom classes) |
| X Cannot chain jobs | O Supports job chaining |
| X No progress tracking | O Query `AsyncApexJob` for status |
| X Limited debugging | O Better error handling |

> 💡 **Best Practice:** Always use `Queueable` instead of `@future`. It provides all the same functionality with more flexibility and better monitoring capabilities.

```java
// ❌ Old way - Don't use
@future(callout=true)
public static void oldWay(Set<Id> recordIds) { }

// ✅ New way - Use Queueable
public class NewWay implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) { }
}
```

---
👉 [Salesforce Official Document](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_platform_apexgov.htm)
👉 [Salesforce Trailhead](https://trailhead.salesforce.com/ko/content/learn/modules/starting_force_com/starting_understanding_arch)

