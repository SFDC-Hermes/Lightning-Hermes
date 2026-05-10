---
layout: single
title: "Salesforce Data Modeling: Master-Detail vs. Lookup Relationships"
date: 2026-05-10
categories:
 - Concepts
tags:
 - DataModeling
 - Architecture
 - Salesforce
 - Admin
---

One of the most fundamental decisions a Salesforce Architect makes is choosing the right relationship type between objects. This choice dictates how data flows, how records are secured, and how the system performs.
Today, we’ll break down the two primary relationship types: **Master-Detail** and **Lookup**, and discuss when to use which.

---

## 🚨 1. Before Modeling Object Relationships

**I highly recommend** reading these two documents before starting your data modeling. From my experience, once a relationship is established, it's extremely difficult to revert. This is especially true when converting from Master-Detail to Lookup, as many roll-up summary fields may already be dependent on that relationship.

👉 [View SF Document about Relationships](https://help.salesforce.com/s/articleView?id=platform.overview_of_custom_object_relationships.htm&type=5)

👉 [View SF Document about Considerations for Object Relationships](https://help.salesforce.com/s/articleView?id=platform.relationships_considerations.htm&type=5)

---

## 🏗️ 2. Master-Detail: The "Inseparable" Connection
Think of a Master-Detail relationship as a **tightly coupled** parent-child bond. The child (Detail) cannot exist without its parent (Master).
### Key Characteristics:
* **Mandatory Parent:** A child record must have a parent at all times.
* **Cascade Delete:** If delete the Master record, all related Detail records are automatically deleted.
* **Security Inheritance:** The child record does not have its own "Owner" field. Instead, it **inherits the sharing and security settings** of the Master.
* **Roll-up Summary:** This is the biggest advantage. Create fields on the Master object to calculate the SUM, MIN, MAX, or COUNT of child records.
  
## Behaviors of master-detail relationships:

* By default, records can’t be reparented in master-detail relationships. Administrators can, however, allow child records in master-detail relationships on custom objects to be reparented to different parent records by selecting the **Allow reparenting option** in the master-detail relationship definition.
*  As a best practice, don’t exceed **10,000** child records for a master-detail relationship.
* Each custom object can have up to **two master-detail relationships** and up to **40 total relationships**.
  
---

## 🌿 3. Lookup: The "Professional" Association
A Lookup relationship is a **loosely coupled** association. Two objects are linked, but they remain independent entities.
### Key Characteristics:
* **Optional Parent:** A record can exist without being linked to a parent.
* **Independent Security:** Each record has its own **Owner** and can have its own independent sharing rules (Sharing Rules).
* **Flexible Deletion:** If a parent is deleted, you can choose to either clear the lookup field, protect the parent from deletion, or (in some cases) cascade delete.
* **No Native Roll-up:** Standard Roll-up Summary fields are not supported. You’ll need Apex triggers or Flow to aggregate data.

---

## 📊 Comparison at a Glance

| Feature | Master-Detail | Lookup |
| :--- | :--- | :--- |
| **Coupling** | Tight (Strongly linked) | Loose (Independent) |
| **Parent Required?** | Yes | Optional |
| **Delete Behavior** | Always Cascade Delete | Clear / Protect / Cascade |
| **Record Ownership** | Inherited from Master | Independent (Owner field exists) |
| **Roll-up Summary** | **Supported natively** | Requires Customization (Flow/Apex) |
| **Limits** | Max 2 per object | Max 40 per object |

---

### 🧐 An Architect’s Reflection: The Illusion of "Easy" Security

In large-scale enterprise systems, the choice between Master-Detail (MD) and Lookup relationships is often treated as a functional preference. However, from a security architecture standpoint, this decision defines the Security Boundary of your entire data model. Choosing Master-Detail simply to "simplify sharing" is a strategic risk that often leads to architectural rigidity.

**The Pitfall of Inherited Visibility**

When faced with complex visibility requirements—such as when a parent record’s access isn't enough to cover diverse regional needs—stakeholders often suggest switching to a Master-Detail relationship. The allure is clear: child records automatically inherit the parent's security settings. But this "convenience" is a double-edged sword.
- **Zero Granularity**: In an MD relationship, the child record loses its independent sharing model. If a future requirement demands that a user see a specific child record without having access to the parent "Master," the architecture fails.
- **Over-Privileging**: To grant access to a single child record, you are forced to open up the parent record, violating the Principle of Least Privilege.

**The "Scale" Misconception**
  
A common mistake occurs when Role Hierarchies become too complex to manage. Architects might be tempted to use MD relationships to bypass hierarchy limits, hoping that inherited sharing will solve the problem.

This is an architectural debt. MD relationships lock your security model into a rigid inheritance chain. While it might solve a "Sharing" headache in the current sprint, it leaves the system unable to adapt to evolving compliance or organizational shifts that require record-level independence.

**Performance and Row Locking**

Beyond security, the tightly coupled nature of Master-Detail creates significant overhead in high-volume environments:

- **Record Locking**: Any update to a child record triggers a lock on the parent to maintain data integrity (and recalculate roll-ups).
  
- **Contention**: In systems processing thousands of transactions per second, this leads to frequent "Row Lock" errors, degrading performance and frustrating end-users.

**The Strategic Choice: Resilience over Convenience**

To build a truly resilient system, one must prioritize Architectural Freedom.
- **Maintain Lookup Relationships**: Keep the data models decoupled to ensure each object can have its own Sharing Rules and owners.
- **Decouple Aggregation**: Use asynchronous logic (Flows or Apex) for data roll-ups instead of relying on the native MD feature.
  
## 🎯 Final Thought

Never let the ease of inherited sharing dictate your data security model. Security should be granular and independent. Build a system that can pivot with the business, not one that is anchored by its own relationships.

## 🎯 Conclusion

As an architect, your role is to balance **functionality** (like Roll-up Summaries) with **security and integrity**. While Master-Detail offers powerful automation, the rigid security model can become a bottleneck as the organization grows.
**Rule of Thumb:** If they are "One Soul in Two Bodies," go with Master-Detail. If they are "Colleagues working on the same project," choose Lookup.
