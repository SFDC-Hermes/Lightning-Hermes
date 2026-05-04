---
layout: single
title: "Salesforce Architecture: Synchronous vs. Asynchronous Strategy"
date: 2026-05-03
categories:
  - Concepts
tags:
  - Apex
  - Salesforce
  - Sync
  - Async
  - Architecture
---

In a multi-tenant ecosystem, deciding between synchronous and asynchronous execution is a strategic choice that defines a system’s scalability. It is the art of managing transaction boundaries to maximize throughput while maintaining a seamless user experience under the pressure of governor limits.

---

## 1. Synchronous Apex: The Immediate Foundation

Synchronous execution is the default mode in Salesforce. It runs in a single thread, and the user must wait for the process to complete before moving to the next task.

* **Immediate Consistency:** Logic is executed within the same transaction. If it fails, everything rolls back.
* **Blocking Behavior:** The UI is "locked" until the Apex code finishes, making it ideal for validation but risky for heavy processing.
* **Deterministic Flow:** Since it runs sequentially, it's easier to debug and predict the execution order.

---

## 2. Sync vs. Async: Beyond the Governor Limits

While we previously discussed in depth, the choice between Sync and Async also involves **Resource Isolation** and **Transaction Boundaries**.
👉 [View governor limits post on GitHub](https://sfdc-hermes.github.io/SFDC-Hermes/concepts/2026/04/07/salesforce-governor-limits.html)

| Feature | Synchronous (Sync) | Asynchronous (Async) |
| :--- | :--- | :--- |
| **Transaction** | Part of the triggering transaction | Starts a **new, isolated** transaction |
| **User Experience** | User waits (Blocking) | User continues (Non-blocking) |
| **CPU Time** | 10 Seconds | 60 Seconds |
| **Heap Size** | 6 MB | 12 MB |
| **Error Handling** | Direct Exception | Job monitoring required |
| **Best For** | Validation, Small DML, UI Logic | Callouts, Bulk Data, Heavy Logic |



---

## 3. The Modern Async Era: The Queueable Evolution

Based on recent release notes, Salesforce is prioritizing **Queueable Apex** as the cornerstone of modern asynchronous orchestration. It is no longer just a flexible alternative to `@future`; it offers features that allow for "Stateful" and "Controlled" execution.

### 🚀 Key Enhancements (Spring '24 & Beyond)

* **Queueable Delay:** You can now specify a delay (up to 10 mins) using `System.enqueueJob(job, delayInMinutes)`. This is a game-changer for avoiding "Record Locked" errors or polling external APIs.
* **Transaction Finalizers:** By implementing `System.Finalizer`, you can attach a "finally" block to your async job to handle errors or re-enqueue jobs regardless of success or failure.
* **Stack Depth Control:** You can limit how deep a chain of Queueable jobs goes, preventing runaway infinite loops in your org.

---

## 4. Async Methods at a Glance

When synchronous boundaries are too restrictive, move your logic to the appropriate asynchronous layer.

| Method | Best For | Max Calls | Chaining | Returns Job ID |
| :--- | :--- | :--- | :--- | :--- |
| **@future** | Simple, isolated tasks | 50/transaction | X | X |
| **Queueable** | **Complex logic / Chaining** | 50/transaction | **O** | **O** |
| **Batch** | Massive data processing | 5 concurrent | O | O |
| **Scheduled** | Recurring automation | 100/org | O | O |

---

## 🧐 Architect's Insight: The "Fire and Forget" Decision

When should you shift from Sync to Async? Don't wait until you hit a limit. Consider these architectural triggers:

1.  **External Dependencies:** Any logic involving a **Callout** should ideally be Async (Queueable) to prevent the UI from hanging on external latency.
2.  **DML Volatility:** If your logic updates thousands of related records, move it to a **Batch** or **Queueable** to isolate the transaction and prevent the main UI transaction from failing.
3.  **The Trigger "Mixed DML" Rule:** If you need to update a Setup object (User) and a non-Setup object (Account) in the same flow, Async is your only way to bypass the `MIXED_DML_OPERATION` error.

> 💡 **Architect's Choice:** Default to **Queueable** instead of `@future`. It provides superior monitoring, allows for job chaining, and handles complex sObject types seamlessly.

---

## 🎯 Conclusion

A well-architected system balances the strict boundaries of synchronous transactions with the expanded limits of asynchronous processing. By mastering the recent enhancements in Queueable Apex, you ensure your Salesforce implementation remains resilient and "Future-Proof" as your data grows.

Happy coding! ⚡
