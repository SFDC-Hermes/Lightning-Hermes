---
layout: single
title: "LWC : Extending Lightning Datatable (3)"
date: 2026-05-24
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Multi Picklist Field
  - Custom  
---

The standard lightning-datatable is a powerful tool, but it has its limitations—most notably the lack of support for Multi Picklist inputs. To provide a better UX for inline editing, we must extend the base component.

This post covers how to implement a custom datatable that supports specialized column types.

## 🚀 Key Features

* **Multi-picklist Field Support:** Enables seamless inline editing with a native-looking **lightning-combobox** for searching and selecting records.
* **Reusable Architecture:** Extends the standard `LightningDatatable` while maintaining all original functionalities.


## 0. Implementation Reference

Refer to the previously implemented codebase to maintain consistency in field mapping and event handling.

👉 [Previous Code Overview](https://sfdc-hermes.github.io/SFDC-Hermes/development/2026/03/13/custom-datatable.html)

## 1. Core Implementation

### 1.1 CustomDatable.js 

To add new types, we define customTypes in our JavaScript file. This tells the datatable which template to render for specific type attributes.

```javascript
import LightningDatatable from 'lightning/datatable';
import multiPicklistTemplate from './multiPicklistTemplate.html';


export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        multipicklistColumn: {
            template: multiPicklistTemplate,
            editTemplate: multiPicklistTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'fieldName']
        }
    };
}
```

## 2. Usage: Column Configuration

In your parent component, configure the columns as follows. Note that editable: false must be set, and the context attribute is mapped to the record Id for precise row tracking.

```javascript
const columns = [
    {
        label: 'MultiUnit',
        fieldName: 'multiUnit__c',
        type: 'multiPicklistColumn',
        editable: false,
        typeAttributes: {
            placeholder: 'Choose Type',
            options: this._multiPickListOptions, 
            value: { fieldName: 'multiUnit__c' },
            context: { fieldName: 'Id' },
            fieldName: 'multiUnit__c'
        }
    }
]

```

## 3. Frontend Support: Dynamic Record Resolution

To make the Multi-Picklist functional within a lightning-datatable, the frontend must dynamically fetch and map picklist options. Using the UI Object Info API is the best practice here, as it ensures your component remains metadata-aware.

Admin-Friendly: If an administrator adds or removes a value in the Setup, the component updates automatically without a code redeployment.

Record Type Awareness: Different Record Types often have different available picklist values. getPicklistValues allows you to filter options based on the specific recordTypeId.

Consistency: It ensures the labels and values in your datatable perfectly match the Salesforce schema.

```javascript

import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
}

```

### ⚠️ Required Dependency

This component relies on the **Multi-Picklist Type** component to handle the specific rendering of the switch. Make sure to deploy both:
- `customDatatable`
- `MultiPicklistColumn`
- `MultiSelectPicklist` - 

👉 [MultiPicklistColumn Component](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/MultiPicklistColumn)
👉 [MultiSelectPicklist Component](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-LWC/MultiSelectPicklist)

### ⚠️ Unresolved Problem 

Just a quick heads-up: this component is still a work in progress.

The main roadblock I'm currently facing is with the inline edit dropdown layout. When the datatable has only one or two records, the physical height of the component is too short, and the dropdown gets clipped by the parent container instead of popping out smoothly over the table.

I've tried tackling this layout trap by tweaking dynamic inline styles in LWC JS and even injecting global CSS through Static Resources, but I guess I'm still a bit green when it comes to mastering these complex CSS overrides inside Salesforce tables.

I'm pretty sure there's an LWC guru among my readers who knows exactly how to crack this riddle! Haha.

