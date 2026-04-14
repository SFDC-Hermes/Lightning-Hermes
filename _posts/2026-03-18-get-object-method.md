---
layout: single
title: "Apex Schema Mastery: Building an Intelligent Object Selector"
date: 2026-03-18
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - DynamicApex
  - CleanCode
---

In Salesforce development, hardcoding object names can make your application brittle. To build truly scalable tools—like dynamic data migrators or custom report builders—you need to master **Dynamic Apex** and the **Schema** class.

Today, I’ll share a robust utility that dynamically discovers and filters Salesforce objects, optimized for performance and usability.

---

## 🚀 Why Dynamic Schema Discovery?

Static code requires manual updates every time a new custom object is added. Dynamic discovery allows your system to automatically adapt to schema changes, significantly reducing maintenance overhead.

---

## 💻 Core Implementation

The following implementation uses `Schema.getGlobalDescribe()` to fetch metadata and applies strict filters to ensure only "actionable" objects are returned.

### 1. The Wrapper: ObjectInfo Class

By implementing the `Comparable` interface, we ensure the object list is always sorted by Label before reaching the UI.

```java
public class ObjectInfo implements Comparable {
    @AuraEnabled public String label;
    @AuraEnabled public String apiName;

    public ObjectInfo(String label, String apiName) {
        this.label = label;
        this.apiName = apiName;
    }

    // Sort by Label in ascending order
    public Integer compareTo(Object compareTo) {
        ObjectInfo other = (ObjectInfo)compareTo;
        if (this.label == null) return -1;
        if (other.label == null) return 1;
        return this.label.compareTo(other.label);
    }
}
```

### 2. The Logic: Smart Object Filtering

We don't just fetch everything. We filter for objects that are **searchable, queryable, and updateable**, while excluding system noise like `History` or `Share` objects.

```java
@AuraEnabled(cacheable=true)
public static Map<String, List<ObjectInfo>> getObjectMap() {
    Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
    List<ObjectInfo> standardList = new List<ObjectInfo>();
    List<ObjectInfo> customList = new List<ObjectInfo>();

    for (Schema.SObjectType sType : describeMap.values()) {
        Schema.DescribeSObjectResult result = sType.getDescribe();
        
        // Filtering actionable objects
        if (result.isSearchable() && result.isQueryable() && result.isUpdateable()) {
            String apiName = result.getName();
            
            // Security Check: Skip if custom business logic fails
            // (e.g., encryption check)
            if (!getEncryptionFields(apiName)) continue;

            // Exclude noise: History, Share, and Feed objects
            if (!result.isCustom() && (apiName.endsWith('History') || 
                apiName.endsWith('Share') || apiName.endsWith('Feed'))) {
                continue;
            }

            ObjectInfo info = new ObjectInfo(result.getLabel(), apiName);
            if (result.isCustom()) {
                customList.add(info);
            } else {
                standardList.add(info);
            }
        }
    }

    // Efficient sorting thanks to the Comparable interface
    standardList.sort();
    customList.sort();

    Map<String, List<ObjectInfo>> resultMap = new Map<String, List<ObjectInfo>>();
    resultMap.put('standard', standardList);
    resultMap.put('custom', customList);
    return resultMap;
}
```

---

👉 [View Full Class on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-Apex/SchemaService)


## 💡 Key Architectural Takeaways

1. **Performance with @AuraEnabled(cacheable=true):** Schema operations are expensive. Client-side caching ensures your UI remains snappy without overloading the server.
2. **Comparable Interface:** Instead of sorting in JavaScript, we handle data integrity at the Apex level, following the **Clean Code** principle.
3. **Smart Filtering:** Excluding `deprecated` or `hidden` objects prevents UI clutter and potential runtime errors.

---

*Building dynamic tools is what separates a developer from an architect. How are you using Schema methods in your current projects?*
