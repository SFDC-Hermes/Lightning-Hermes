---
layout: single
title: "Custom Path LWC Component"
date: 2026-03-25
categories:
  - LWC
tags:
  - LWC
  - Path
---

Salesforce Custom Path
A reusable LWC component that mirrors the standard Salesforce Path design while allowing custom functionality.  
Simply configure `recordId`, `objectName`, and `fieldName` via XML to use it on any object. This is the Classic version

---

## 🚀 Key Features

* **Dynamic Picklist Rendering:** Fetches StageName picklist values via Apex and dynamically generates the Path UI.
* **Visual Progress Tracking:** Displays completed stages as `slds-is-complete` and the current stage as `slds-is-current slds-is-active` for intuitive progress visualization.
* **Closed Stage Modal:** Provides a modal dialog for selecting the final outcome (Closed Won/Lost) when closing an Opportunity.
* **Real-time Record Update:** Leverages `updateRecord` from `lightning/uiRecordApi` to instantly update records without page refresh.
* **Reusable Design:** Built with `@api recordId` to be easily reusable across any Opportunity record page.

---

👉 [View Full Class on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/CustomPath-Classic)
