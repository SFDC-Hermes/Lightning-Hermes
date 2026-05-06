---
layout: single
title: "LWC : Extending Lightning Datatable (2)"
date: 2026-05-17
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Lookup Field
  - Custom  
---

The standard lightning-datatable is a powerful tool, but it has its limitations—most notably the lack of support for Lookup inputs within cells. To provide a better UX for inline editing, we must extend the base component.

This post covers how to implement a custom datatable that supports specialized column types.

---

## 🚀 Key Features

* **Lookup Field Support:** Enables seamless inline editing with a native-looking **Record Picker** for searching and selecting records.
* **Reusable Architecture:** Extends the standard `LightningDatatable` while maintaining all original functionalities.

---
