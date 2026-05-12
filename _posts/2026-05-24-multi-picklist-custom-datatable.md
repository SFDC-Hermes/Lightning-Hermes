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
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
        }
    };
}
```

## 2. Usage: Column Configuration

In your parent component, configure the columns as follows. Note that editable: false must be set, and the context attribute is mapped to the record Id for precise row tracking.

```javascript
const columns = [
    { label: 'Name', fieldName: 'Name', editable: true },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true },
    {
        label: 'MultiUnit', fieldName: 'multiUnit__c', type: 'multiPicklistTemplate', editable: false, typeAttributes: {
            placeholder: 'Choose Type', options: { fieldName: 'pickListOptions' }, 
            value: { fieldName: 'multiUnit__c' },
            context: { fieldName: 'Id' } 
        }
    },
    
]
```

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
