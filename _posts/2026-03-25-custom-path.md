---
layout: single
title: "LWC: Building a Reusable Custom Path Component"
date: 2026-03-25
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Path
  - UI/UX
---

The standard Salesforce Path is a great visual tool, but sometimes we need more control over its behavior or want to display it in custom locations. 

Today, I’m sharing a **Custom Path LWC Component** that mirrors the standard SLDS design while remaining fully dynamic. By simply configuring the `recordId`, `objectName`, and `fieldName`, you can use this component on any object.

---

## 🚀 Key Features

* **Dynamic Picklist Rendering:** Fetches picklist metadata via Apex and current record data via Lightning Data Service (LDS).
* **Visual Progress Tracking:** Automatically calculates and applies SLDS classes (`slds-is-complete`, `slds-is-current`) based on the current record state.
* **Reusable XML Configuration:** Designed to be dropped into any Lightning Record Page with property pane support for Object and Field names.
* **Real-time UI Sync:** Uses `@wire` to ensure the Path updates instantly if the record's field value changes elsewhere.

---

## 💻 Core Logic Highlights

### 1. Dynamic Class Assignment (The CSS Engine)

The heart of this component is the `picklistValues` getter. It determines the visual state of every stage by comparing the picklist options against the current record's value.

```javascript
get picklistValues() {
    let itemsList = [];
    if (Array.isArray(this.pickList)) {
        let selectedIndex = -1;

        // Step 1: Initialize classes and find the current index
        this.pickList.forEach((picklistEntry, index) => {
            let classList = 'slds-path__item slds-is-incomplete';
            
            if (picklistEntry.value === this.selectedValue) {
                classList = 'slds-path__item slds-is-current slds-is-active';
                selectedIndex = index;
            }
            
            itemsList.push({
                pItem: picklistEntry,
                classList: classList
            });
        });

        // Step 2: Mark previous stages as 'Complete'
        if (selectedIndex > 0) {
            for (let i = 0; i < selectedIndex; i++) {
                itemsList[i].classList = 'slds-path__item slds-is-complete';
            }
        }
    }
    return itemsList;
}
```

### 2. Hybrid Data Approach

I combined **Lightning Data Service (@wire)** for record data and **Apex** for picklist metadata. This ensures the component stays "Reactive" to record changes while still being able to fetch global picklist values that LDS doesn't naturally provide.

---

👉 [View Full Project on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/CustomPath-Classic)
👉 [View Advanced Code on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/CustomPath-Advanced)

---

## 💡 Key Architectural Takeaways

1.  **SLDS Compliance:** By using standard classes like `slds-path__nav`, the component feels native to the Salesforce ecosystem.
2.  **Context Awareness:** Using `@api recordId` allows the component to know exactly which record it is sitting on without extra coding.
3.  **Scalability:** This "Classic" version sets the foundation for more advanced features like custom "Path Guidance" or specialized modals for closed stages.

---
