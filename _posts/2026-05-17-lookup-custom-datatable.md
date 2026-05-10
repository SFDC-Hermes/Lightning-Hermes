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

## 0. Implementation Reference

Refer to the previously implemented codebase to maintain consistency in field mapping and event handling.

👉 [Previous Code Overview](https://sfdc-hermes.github.io/SFDC-Hermes/development/2026/03/13/custom-datatable.html)

---

## 1. Core Implementation: CustomDatatable.js

To add new types, we define customTypes in our JavaScript file. This tells the datatable which template to render for specific type attributes.

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



