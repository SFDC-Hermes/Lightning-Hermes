---
layout: single
title: "LWC: Building a Reusable Custom Path Component(Advanced)"
date: 2026-04-18
categories:
  - LWC
tags:
  - LWC
  - Salesforce
  - Path
  - UI/UX
---
The standard Salesforce Path is a great visual tool, but sometimes we need more control over its behavior or want to display it in custom locations. 

Today, I’m sharing a **Custom Path LWC Component(Advanced)** that mirrors the standard SLDS design while remaining fully dynamic. 
At the previous post I simply configuring the `recordId`, `objectName`, and `fieldName`.
In Advanced version I will add configure `errorValue`, `endValue`, `replaceFromValue`, `booleanValue`, `booleanPickValue`, `replaceToValue`.
If this property filled, We can Dynamically show picklistValue such as if errorValue, all of the picklistValue will be blank except errorValue.
And it will return slds-is-current slds-is-lost class. 
