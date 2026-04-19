---
layout: single
title: "Apex: The Ultimate Guide to Scalable Paging in Salesforce"
date: 2026-04-26
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - Paging
  - Performance
  - ApexCursor
---

Handling large datasets is a core challenge in Salesforce architecture. Fetching everything at once leads to Heap Size issues and CPU timeouts. To build resilient systems, you must choose the right paging strategy. 

From the basic **Offset** to the modern **Apex Cursor**, let’s explore every major paging method available in the ecosystem.

---

## 1. Offset-Based Pagination (Standard & Dynamic)

The most intuitive way to page data is using `LIMIT` and `OFFSET`. While simple, it has significant architectural constraints.

### Static Implementation
```java
// Page 3 (20 records per page)
List<Account> accs = [SELECT Id, Name FROM Account ORDER BY Name LIMIT 20 OFFSET 40];