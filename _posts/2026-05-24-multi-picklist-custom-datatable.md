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
import multiselectPicklistTemplate from './multiselectPicklistTemplate.html';


export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        multipicklistColumn: {
            template: multiselectPicklistTemplate,
            editTemplate: multiselectPicklistTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
        }
    };
}
```
