---
layout: single
title: "LWC Architecture: Decoupling Components with Lightning Message Service (LMS)"
date: 2026-08-09
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - LMS
  - MessageChannel
  - Frontend
---

Overview: The Cross-DOM Communication Challenge

In a standard Lightning Web Component (LWC) architecture, components residing in the same DOM tree communicate via straightforward parent-child patterns:
* **Parent to Child:** Passing data down using public properties (`@api`).
* **Child to Parent:** Bubbling events up using standard DOM `CustomEvent`.

However, modern enterprise Lightning Pages are composed of **unrelated components** scattered across different regions of a page flexipage (e.g., a Record Detail view in the main region communicating with a custom Analytics Card in the sidebar). Because these components do not share a direct ancestor-child relationship in the DOM, standard custom events cannot reach across these boundaries.

To solve this decoupling problem without resorting to legacy, unmaintained pub/sub utility libraries, Salesforce provides the **Lightning Message Service (LMS)**.

---