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
## 2. How to Use: Column Configuration

When using this custom component in your parent LWC, configure the columns as follows. Note that you must set editable: true and provide the necessary typeAttributes.

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

## 3. Key Architectural Takeaways

Standardization: By extending the base class, we keep the look and feel consistent with the rest of Salesforce Lightning.

Context Binding: Passing the Id as a context attribute is crucial. It allows the component to return the exact record ID when a value is changed.

Scalability: You can easily add more custom types (like file uploaders or custom lookups) by adding them to the customTypes object.


