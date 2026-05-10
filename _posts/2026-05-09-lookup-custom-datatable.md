---
layout: single
title: "LWC : Extending Lightning Datatable (2)"
date: 2026-05-09
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

## 0. Implementation Reference

Refer to the previously implemented codebase to maintain consistency in field mapping and event handling.

👉 [Previous Code Overview](https://sfdc-hermes.github.io/SFDC-Hermes/development/2026/03/13/custom-datatable.html)

---

## 1. Core Implementation: CustomDatatable.js, LookupType.js, LokkupLinkCell.js

1.1 To add new types, we define customTypes in our JavaScript file. This tells the datatable which template to render for specific type attributes.

```javascript
import LightningDatatable from 'lightning/datatable';
import lookupTemplate from './lookupTemplate.html';
import lookupEditTemplate from './lookupEditTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        lookup: {
            template: lookupTemplate,      
            editTemplate: lookupEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['value', 'objectApiName', 'name', 'label', 'context', 'fieldName'] 
        }
    };
}
```

1.2  The Bridge Component: lookupType.js
For CustomDatatable to render a lookup input within a cell, we need a dedicated component that wraps lightning-record-picker. 
This component doesn't just display a search bar; it must implement a specific interface to communicate seamlessly with the datatable's inline editing engine.

**Key Technical Aspects**
1. Interface Compliance (Standard Methods)
methods like focus(), validity, and checkValidity(). These are not optional. When the datatable enters edit mode and focuses on a cell, it looks for these standard LWC input methods.

focus(): Ensures that when a user clicks the edit icon, the cursor is automatically placed in the record picker.

Validation: By providing validity and checkValidity(), we ensure the datatable can include this custom field in its standard error-handling lifecycle.

2. Advanced Event Strategy: lookupselect
In LWC, events are encapsulated within their component’s Shadow DOM by default. However, for a Custom Datatable Type, the event must travel a long and restricted path to reach its destination. This is where bubbles and composed become mandatory.

```javascript
    const lookupEvent = new CustomEvent('lookupselect', {
    composed: true,
    bubbles: true,
    cancelable: true ...
    }
```
bubbles: true (The Vertical Ascent)
By default, events do not bubble. Setting this to true allows the event to move up from the lightning-record-picker to our lookupType component's root.

composed: true (Breaking the Boundary)
This is the most critical part. In a datatable, our lookupType is nested inside a Shadow Root created by the datatable engine. Standard bubbling stops at the first shadow boundary it hits.
Setting composed: true is what gives the event the **permission** to cross that boundary and reach the CustomDatatable. Without it, the event is trapped inside the cell's private DOM.

Why both are required here?
In architecture, the event journey looks like this:
lightning-record-picker → lookupType (Shadow Boundary 1) → Datatable Cell (Shadow Boundary 2) → CustomDatatable.
To ensure our handleLookupSelect in the CustomDatable catches the change, must enable both to allow the event to "bubble" and stay "composed" across these nested layers.

⚠️ Architect's Note: The Encapsulation Trade-off

Setting composed: true should be done with caution. It breaks the principle of encapsulation by allowing internal events to leak into the outer DOM. 

However, in the case of Extending Datatables, it is a deliberate architectural choice to facilitate communication between a deeply nested custom editor and its parent.

3. UX Polish: Automatic Blur

```javascript
const picker = this.template.querySelector('lightning-record-picker');
if (picker) {
    picker.blur();
}
```

After a user selects a record, we manually trigger blur(). This signals to the datatable that editing is "finished" for this cell, allowing for a smoother "commit-on-select" experience.

---
## 2. Usage: Column Configuration

In your parent component, configure the columns as follows. Note that editable: true must be set, and the context attribute is mapped to the record Id for precise row tracking.

```javascript
Columns = [
            label: 'Account Name'
            , fieldName: 'AccountId'
            , type: 'lookup'
            , editable: true
            , typeAttributes: {
                objectApiName: 'Account',
                value: { fieldName: 'AccountId' },
                name: { fieldName : 'AccountId_Name' }, 
                fieldName: 'AccountId',
                label: 'Account',
                context: { fieldName: 'Id' }
            }
        },
  ]
```

---

## 3. Backend Support: Dynamic Record Resolution
When a user selects a record in the lookup, the frontend usually only receives the Record ID. To display the Record Name immediately without a full page refresh, we need a dynamic Apex helper.

Using getSobjectType() allows a single Apex method to handle various objects dynamically:

```java
    @AuraEnabled(cacheable=true)
    public static String getRecordName(Id recordId) {
    if (recordId == null) return null;
    String objectApiName = recordId.getSobjectType().getDescribe().getName();
    String query = 'SELECT Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
    SObject res = Database.query(query);
    return (String)res.get('Name');
    }
```

By using this approach can construct a Dynamic SOQL query that works for any object, making Apex code much more reusable and flexible.

## 4. Event Handling: Detecting Changes
We capture the custom event from our lookup template and update the internal state. We use stopPropagation() to prevent the event from bubbling up unnecessarily, maintaining a clean event flow.

```javascript

async handleLookupSelect(event) {
        event.stopPropagation();
        const { context, value, fieldName } = event.detail.data;

        let realRecordName = '';
        if (value) {
            try {
                realRecordName = await getRecordName({ recordId: value });
            } catch (error) {
                console.error('Record name fetch failed:', error);
                realRecordName = 'Unknown';
            }
        }

        const draftItem = { Id: context, [fieldName]: value };
        this.updateDraftValuesAndData(draftItem);

        const displayFieldName = fieldName + '_Name';
        this.updateDataValues({Id: context, [fieldName]: value, [displayFieldName]: realRecordName});
    }

```

## 5. Architectural Takeaway: The "Base Table" Vision
This CustomDatatable serves as the underlying engine. By wrapping this inside a CoreDatatable (or BaseTable), you can add global features like Server-side Paging and Global Search.

Standardization: Extends the platform's native look and feel.

Security: Inherits Salesforce's standard security and sharing models.

### ⚠️ Required Dependency

This component relies on the **lookupType** component to handle the specific rendering of the switch. Make sure to deploy both:
- `customDatatable`
- `lookupType`
- `lookupLinkCell` - Navigate to record detail page in default state

👉 [LookupLinkCell Component](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/LookupType)
👉 [LookupType Component](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/LookupLinkCell)

--- 



