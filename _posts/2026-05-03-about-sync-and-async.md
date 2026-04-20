---
layout: single
title: "Salesforce Sync VS Async"
date: 2026-05-03
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - Sync
  - Async
---

## 1. Async Methods at a Glance

When synchronous limits are too restrictive, move your logic to the asynchronous layer.

| Method | Best For | Max Calls | Chaining | Returns Job ID |
|:---|:---|:---|:---|:---|
| **@future** | Simple, isolated tasks | 50/transaction | X | X |
| **Queueable** | Complex logic / Chaining | 50/transaction | O | O |
| **Batch** | Massive data processing | 5 concurrent | O | O |
| **Scheduled** | Recurring automation | 100/org | O | O |

---

### 🎯 When to Use What? (Design Strategy)

| Scenario | Recommended Approach |
|:---|:---|
| Callout from a trigger | `Queueable` |
| Need to monitor job status | `Queueable` (via `AsyncApexJob`) |
| Processing >10,000 records | `Batch Apex` |
| Chaining multiple sequential jobs | `Queueable` |
| Daily/Weekly maintenance tasks | `Scheduled Apex` |

---

### ⚠️ The Shift from @future to Queueable

While `@future` was a staple in legacy Apex, modern Salesforce architecture favors **Queueable Apex** for its flexibility and robustness.

| @future (Legacy) | Queueable (Architect's Choice) |
|:---|:---|
| No Job ID; hard to track | Returns **Job ID** for monitoring |
| Primitives only (ID, String, etc.) | Accepts **Complex Types** (sObjects, Lists) |
| Cannot chain jobs | Supports **Job Chaining** |
| Difficult to debug | Better error handling and visibility |

> 💡 **Best Practice:** Default to `Queueable` instead of `@future`. It provides superior monitoring, allows for job chaining, and handles complex data structures seamlessly.

```java
// Legacy Approach: Limited and hard to monitor
@future(callout=true)
public static void processSync(Set<Id> ids) { ... }

// Modern Architect Approach: Scalable and trackable
public class VaultProcessor implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) { 
        // Logic here
    }
}
```
