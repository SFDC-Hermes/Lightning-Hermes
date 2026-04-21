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
List<Account> accountList = [SELECT Id, Name FROM Account ORDER BY Name LIMIT 20 OFFSET 40];
```


Dynamic Implementation (Real-world Pattern)
In a production environment, you need a reusable service that calculates the offset on the fly.

```java
private static final Integer DEFAULT_PAGE_SIZE = 20;
private static final Integer DEFAULT_PAGE_NUMBER = 1;

public static List<SObject> getPagedRecords(String objectName, Integer pageSize, Integer pageNumber) {
    List<SObject> result = new List<SObject>();
    if (String.isBlank(objectName)) {
        return result;
    }

    Integer size = (pageSize == null || pageSize < 1) ? DEFAULT_PAGE_SIZE : pageSize;
    Integer page = (pageNumber == null || pageNumber < 1) ? DEFAULT_PAGE_NUMBER : pageNumber;

    Integer offsetValue = (page - 1) * size;

    if (offsetValue > 2000) {
        throw new AuraHandledException('The requested page exceeds the maximum offset limit of 2,000.');
    }
    
    // 3. Secure Dynamic SOQL
    // Use bind variables (:size, :offsetValue) for better security and performance
    String query = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(objectName) + 
                   ' ORDER BY CreatedDate DESC ' +
                   ' LIMIT :size OFFSET :offsetValue';
    
    try {
        result = Database.query(query);
        return result;
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving records. Please check the object name or parameters.');
    }
}
```

⚠️ The Architect's Warning

•	The 2,000 Row Wall: The OFFSET clause cannot exceed 2,000. You cannot use this for massive datasets.

•	Scan & Discard: Performance degrades as you go deeper. To return records 1,980–2,000, Salesforce must still scan the first 1,979 records, leading to higher execution times.

## 2. Keyset (Manual Cursor) Pagination
To scale beyond 2,000 rows, architects use Keyset Pagination. This uses an indexed field (like Id or CreatedDate) as a marker.

```java
// Fetching the next page based on the last record from the previous page
List<Account> accs = [SELECT Id, Name FROM Account 
                      WHERE Id > :lastIdSeen 
                      ORDER BY Id ASC LIMIT 20];
```

🧐 Pros & Cons

•	Pros: Constant performance. Since it uses an index-based WHERE clause, it is lightning-fast even with millions of records.

•	Cons: No random access. You cannot jump directly to Page 10 from Page 1. Users are restricted to "Next" and "Previous" navigation.

## 3. Apex Cursor (The Modern Standard)
Newly introduced, Apex Cursor is a stateful feature that allows you to navigate up to 50 million rows without the complexity of manual keyset logic.

```Java
Database.Cursor myCursor = Database.getCursor([SELECT Id, Name FROM Account]);
// Fetching records 5,000 to 5,200
List<SObject> chunk = myCursor.fetch(5000, 200);
```


