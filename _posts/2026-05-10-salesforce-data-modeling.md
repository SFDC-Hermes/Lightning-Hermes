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

## 🏗️ 1. Master-Detail: The "Inseparable" Connection
Think of a Master-Detail relationship as a **tightly coupled** parent-child bond. The child (Detail) cannot exist without its parent (Master).
### Key Characteristics:
* **Mandatory Parent:** A child record must have a parent at all times.
* **Cascade Delete:** If you delete the Master record, all related Detail records are automatically deleted.
* **Security Inheritance:** The child record does not have its own "Owner" field. Instead, it **inherits the sharing and security settings** of the Master.
* **Roll-up Summary:** This is the biggest advantage. You can create fields on the Master object to calculate the SUM, MIN, MAX, or COUNT of child records.

---
