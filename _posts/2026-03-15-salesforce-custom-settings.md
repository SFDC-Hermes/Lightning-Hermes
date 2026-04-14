---
layout: single
title: "Custom Settings vs. Custom Metadata: Why DML Matters in Architecture"
date: 2026-03-15
categories:
  - Concepts
tags:
  - Salesforce
  - Apex
  - Architecture
  - Performance
---

In the Salesforce ecosystem, deciding where to store configuration data is a common architectural crossroads. While **Custom Metadata Types (CMDT)** are often hailed as the modern standard, **Custom Settings** remain a powerful tool in a developer's arsenal—especially when dynamic data updates are required.

Today, I’ll dive into the critical differences between the two and share a specific use case where Custom Settings was the superior choice.

---

## 🛠️ Enabling List Custom Settings

By default, many Salesforce Orgs only show the **Hierarchy** type when creating a new Custom Setting. If you need the **List** type, you must first enable it in the organizational settings.

* **Path:** `Setup` > `Schema Settings`
* **Action:** Enable **"Manage List Custom Settings Type"**

Once toggled on, you will see the "List" option available during the creation process.

---

## 💡 The "Why": Direct DML vs. Read-Only Metadata

The most significant differentiator between these two is how they handle data updates within Apex logic.

### 1. Direct DML Support
* **Custom Settings:** They behave like standard objects in terms of DML. You can perform `insert`, `update`, and `upsert` directly within an Apex class or trigger.
* **Custom Metadata:** These are "Metadata," not "Data." They are essentially read-only for standard Apex. Updating them requires complex calls to the Metadata API or manual deployment.

### 2. Practical Case: 24-Hour API Token Rotation
I recently designed a scheduled batch process that integrates with an external service. The service requires an API token that expires every 24 hours.

* **The Requirement:** A batch job runs daily to fetch a new token and must store it centrally for other classes to use.
* **The Solution:** **Custom Settings**.
* **The Reason:** Because Custom Settings support DML, the batch job can simply `upsert` the new token value at the end of its execution. If I had used CMDT, automating this "Self-Updating" logic would have been significantly more complex and prone to deployment-related hurdles.

---

## 🔐 Security & Functional Comparison

Understanding the lifecycle and visibility of these tools is key to a secure implementation.

| Feature | Custom Settings | Custom Metadata (CMDT) |
| :--- | :--- | :--- |
| **DML Support** | **Yes** (Directly updateable via Apex) | **No** (Requires Metadata API) |
| **Data Nature** | **Data** (Records are not deployable) | **Metadata** (Records are deployable) |
| **Visibility** | Public or Hidden | Public or Protected |
| **SOQL Impact** | **0** (Uses Application Cache) | **0** (Static retrieval) |
| **Sandbox Refresh** | Records are **not** copied | Records **are** copied (as Metadata) |
| **Best For** | Frequently changing values, User/Profile-specific settings | Static app config, Packaging, and Deployment |

---

## 🏁 Conclusion

While Custom Metadata is excellent for static configurations that need to be packaged and deployed, **Custom Settings** is the undisputed winner when your system needs to programmatically update its own settings. 

By leveraging the direct DML capabilities and the zero-SOQL impact of Custom Settings, you can build a more flexible and performant architecture for dynamic requirements like token management.

---
*Architecture is all about choosing the right tool for the specific job. How do you decide between Settings and Metadata in your projects? Let's discuss in the comments.*
