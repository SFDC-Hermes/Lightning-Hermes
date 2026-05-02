---
layout: single
title: "LWC: Extending Lightning Datatable with Picklist and Toggle Types (1)"
date: 2026-03-13
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Datatable
  - CustomTypes
  - UI/UX
---

The standard `lightning-datatable` is a powerful tool, but it has its limitations—most notably the lack of support for **Picklist** and **Toggle** inputs within cells. To provide a better UX for inline editing, we must extend the base component.

This post covers how to implement a custom datatable that supports specialized column types.

---

## 🚀 Key Features

* **Custom Picklist Support:** Native-looking dropdowns for seamless inline editing.
* **Toggle Switch Integration:** A clean UI for boolean field updates.
* **Reusable Architecture:** Extends the standard `LightningDatatable` while maintaining all original functionalities.

---

## 💻 Core Implementation: `CustomDatatable.js`

To add new types, we define `customTypes` in our JavaScript file. This tells the datatable which template to render for specific `type` attributes.

```javascript
import LightningDatatable from 'lightning/datatable';
import picklistTemplate from './picklistTemplate.html';
import toggleTemplate from './toggleTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: picklistTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context'],
        },
        toggle: {
            template: toggleTemplate,
            standardCellLayout: true,
            typeAttributes: ['value', 'context'],
        }
    };
}
```

---

## 🛠️ How to Use: Column Configuration

When using this custom component in your parent LWC, configure the columns as follows. Note that you must set `editable: true` and provide the necessary `typeAttributes`.

```javascript
const COLUMNS = [
    {
        label: 'Employment Status',
        fieldName: 'Status__c',
        type: 'picklistColumn', // Using our custom type
        editable: true,
        typeAttributes: {
            placeholder: 'Choose Status',
            options: { fieldName: 'picklistOptions' }, // Map to dynamic options in your data
            value: { fieldName: 'Status__c' },
            context: { fieldName: 'Id' } // Bind record ID for the update event
        }
    },
    {
        label: 'toggle Data',
        fieldName: 'Boolean__c',
        type: 'toggle', // Using our custom type
        editable: true,
        typeAttributes: {
            value: { fieldName: 'Boolean__c' },
            context: { fieldName: 'Id' }
        }
    }
];
```

---

### ⚠️ Required Dependency

This component relies on the **toggleType** component to handle the specific rendering of the switch. Make sure to deploy both:
- `customDatatable`
- `toggleType`

👉 [View Source Code on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/CustomDatatable)
👉 [ToggleType Component](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/ToggleType)

---

## 💡 Key Architectural Takeaways

1.  **Standardization:** By extending the base class, we keep the look and feel consistent with the rest of Salesforce Lightning.
2.  **Context Binding:** Passing the `Id` as a `context` attribute is crucial. It allows the component to return the exact record ID when a value is changed.
3.  **Scalability:** You can easily add more custom types (like file uploaders or custom lookups) by adding them to the `customTypes` object.

---

*Customizing datatables is a hallmark of a senior-level LWC developer. How are you enhancing your data grids?*
