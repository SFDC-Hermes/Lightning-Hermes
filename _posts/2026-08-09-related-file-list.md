---
layout: single
title: "LWC Architecture: Building a Dynamic File Manager with Enterprise Apex Service Layer"
date: 2026-08-09
categories:
  - Development
tags:
  - LWC
  - Salesforce
  - Apex
  - ContentDocument
  - Architecture
---

## 1. Overview: The Need for a Custom File Manager

In standard Salesforce Lightning record pages, the out-of-the-box **Files Related List** provides basic file attachment and download capabilities. However, enterprise business requirements often demand a more versatile file management solution due to key limitations in the standard component:

1. **Rigid View Options:** Standard file lists offer only a single-column list layout, making visual inspection of images, diagrams, or design attachments inefficient.
2. **Direct Relationship Boundaries:** Standard components can only query `ContentDocumentLink` records directly attached to the current record (`LinkedEntityId = :recordId`). They cannot traverse relationship trees to aggregate files attached to child records (e.g., displaying files attached to child line items directly on the parent record page).
3. **Lack of Advanced Filtering:** Standard components lack dynamic date-range filters, author filters, and rich-text image exclusions (preventing embedded inline images from cluttering primary attachment lists).

To address these challenges, we designed a custom Lightning Web Component supported by a decoupled **Enterprise Apex Layer** (Controller + Service pattern), multi-column responsive grid views, and a governor-limit defensive query design.

---

## 2. High-Level Architecture & Layer Separation

To maintain clean separation of concerns, the backend is split into a lightweight **Controller Layer** (handling entry points and DTOs) and a robust **Service Layer** (managing schema introspection, dynamic SOQL construction, and security checks).

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          LIGHTNING WEB COMPONENT                       │
│  * Grid View Switcher (2 / 4 / 8 Columns)                              │
│  * Search Keyword & Date Filter Controls                               │
│  * Drag-and-Drop File Upload Zone                                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Calls @AuraEnabled Methods
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│            CONTROLLER LAYER (CustomFileListController.cls)             │
│  * Exposes @AuraEnabled API Endpoints                                  │
│  * Houses Data Transfer Objects (DTOs: FileQueryRequest, FileDto, etc) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Delegates Business Logic
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             SERVICE LAYER (CustomFileListService.cls)                  │
│  * Schema Introspection & Dynamic Field Resolution (isNameField)       │
│  * Direct & Indirect SOQL Query Engine                                 │
│  * Scalability Guardrails (fileLookbackMonths & Date Range Bounds)      │
│  * Keyset Cursor Pagination (LastModifiedDate + Id)                    │
│  * Record Ownership & Admin Delete Enforcement                         │
└────────────────────────────────────────────────────────────────────────┘

```

---

## 3. Backend Implementation: Controller vs. Service Pattern

### 3.1 The Controller Layer (`CustomFileListController.cls`)

The Controller contains zero business logic. It acts purely as a wrapper for `@AuraEnabled` endpoints and hosts the structured Data Transfer Objects (DTOs) passed between Apex and LWC.

```apex
public with sharing class CustomFileListController {

    @AuraEnabled
    public static FileQueryResult getFilesByObjectRelation(FileQueryRequest request, FileQueryCursor cursor) {
        return CustomFileListService.getFilesByObjectRelation(request, cursor);
    }

    @AuraEnabled
    public static DeletePermissionResult checkDeleteFilePermission(Id linkedEntityId) {
        return CustomFileListService.checkDeleteFilePermission(linkedEntityId);
    }

    // =========================================================================
    // Data Transfer Objects (DTOs)
    // =========================================================================
    public class FileQueryRequest {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String parentObjectApiName { get; set; }
        @AuraEnabled public String relatedObjectApiName { get; set; }
        @AuraEnabled public String relatedToParentField { get; set; }
        @AuraEnabled public String firstField { get; set; }
        @AuraEnabled public String operator { get; set; }
        @AuraEnabled public String secondField { get; set; }
        @AuraEnabled public String exceptField { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public String searchKeyword { get; set; }
        @AuraEnabled public String createdDateFrom { get; set; }
        @AuraEnabled public String createdDateTo { get; set; }
        @AuraEnabled public List<Id> createdByIds { get; set; }
        @AuraEnabled public Integer fileLookbackMonths { get; set; }
        @AuraEnabled public List<Id> relatedRecordIds { get; set; }
    }

    public class FileQueryResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public FilePageDto data;
        public FileQueryResult() {
            this.isSuccess = false;
            this.message = '';
            this.data = new FilePageDto();
        }
    }
}

```

### 3.2 The Service Layer (`CustomFileListService.cls`)

The Service layer handles data processing, schema validation, and dynamic query generation.

```apex
public with sharing class CustomFileListService {

    public static CustomFileListController.FileQueryResult getFilesByObjectRelation(
        CustomFileListController.FileQueryRequest request,
        CustomFileListController.FileQueryCursor cursor
    ) {
        CustomFileListController.FileQueryResult result = new CustomFileListController.FileQueryResult();
        normalizeRequest(request);

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        String validationError = validateRequest(request, globalDescribe);
        if (validationError != null) {
            result.message = validationError;
            return result;
        }

        try {
            QueryOptions options = buildQueryOptions(request);
            Set<Id> parentRecordIds = collectParentRecordIds(request);
            RelatedContext relatedContext = resolveRelatedContext(request, globalDescribe);

            DocumentLinkContext linkContext = collectDocumentLinkContext(request, relatedContext, parentRecordIds, options);
            result.data.totalCount = linkContext.documentIds.size();

            if (!linkContext.documentIds.isEmpty()) {
                List<ContentVersion> versions = queryLatestContentVersions(
                    linkContext.documentIds, options, request.exceptField, 
                    cursor != null ? cursor.cursorModifiedDate : null, 
                    cursor != null ? cursor.cursorVersionId : null
                );

                trimVersionsForPaging(result.data, versions, options.normalizedPageSize);
                loadRelatedRecordsForPage(request, relatedContext, linkContext, versions, globalDescribe);
                appendFileDtos(result.data, versions, relatedContext, linkContext, parentNameById, request.recordId);
                updateCursor(result.data, versions);
            }
            result.isSuccess = true;
        } catch (Exception e) {
            result.message = toUserFacingError(e, 'An error occurred while retrieving attached files');
        }
        return result;
    }

    private static String getNameFieldApiName(Schema.DescribeSObjectResult describeResult) {
        for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
            Schema.DescribeFieldResult fDescribe = field.getDescribe();
            if (fDescribe.isNameField()) {
                return fDescribe.getName();
            }
        }
        return 'Id';
    }
}

```

---

## 4. Architectural Deep-Dive: Defending Against Governor Limits at Scale

When designing file management components for enterprise Orgs, the single greatest architectural risk is **data volume growth**. Over time, an enterprise Salesforce environment can easily accumulate tens or hundreds of thousands of `ContentDocument` records across related object trees.

If a component queries files without explicit boundaries, it will inevitably trigger the platform's hard limits:

* **SOQL Row Limit:** `System.LimitException: Too many query rows: 50001`
* **Apex Heap Size Limit:** `System.LimitException: Apex heap size too large`

To guarantee scale-proof execution, we embedded two strict architectural guardrails into the Service Layer:

### 4.1 Scalability Guardrail 1: Enforced Date Range Lookbacks (`fileLookbackMonths`)

To prevent unbounded full-table scans, the Service layer incorporates a mandatory lookback validation engine via `validateLookbackRange()`.

Administrators can configure `fileLookbackMonths` (e.g., restricting searches to a maximum of 3, 6, or 12 months). The Apex service validates incoming date filters against this policy:

```apex
private static String validateLookbackRange(FileQueryRequest request) {
    if (request.fileLookbackMonths == null || request.fileLookbackMonths <= 0) {
        return null;
    }
    if (String.isBlank(request.createdDateFrom)) {
        return 'Please set a Start Date for search period. (Maximum ' + request.fileLookbackMonths + ' months)';
    }
    Date fromDate = Date.valueOf(request.createdDateFrom);
    Date toDate = String.isBlank(request.createdDateTo) ? Date.today() : Date.valueOf(request.createdDateTo);
    Date earliestAllowed = toDate.addMonths(-request.fileLookbackMonths);
    
    // Hard check blocking queries exceeding the administrator-defined timeframe
    if (fromDate < earliestAllowed) {
        return 'Lookback period cannot exceed ' + request.fileLookbackMonths + ' months.';
    }
    return null;
}

```

By enforcing a time-bound window (`ContentDocument.ContentModifiedDate >= :createdDateFromDt AND < :createdDateToExclusive`), we force the Salesforce Query Optimizer to leverage indexed date fields, drastically trimming candidate row counts before Apex touches the data.

### 4.2 Scalability Guardrail 2: Keyset Cursor Pagination (No `OFFSET`)

Standard SOQL `OFFSET` clauses suffer from performance degradation on large datasets and still count toward total queried rows. Instead, our Service layer utilizes **Keyset Pagination** via `cursorModifiedDate` and `cursorVersionId`.

```apex
// Fetching strictly pageSize + 1 records for deterministic "hasMore" detection
if (cursorModifiedDate != null && cursorVersionId != null) {
    query += ' AND (LastModifiedDate < :cursorModifiedDate OR ' +
             '(LastModifiedDate = :cursorModifiedDate AND Id < :cursorVersionId))';
}
query += ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT :queryLimit';

```

By querying only `pageSize + 1` records at a time, Apex Heap memory remains practically flat (a few kilobytes instead of megabytes), eliminating memory overflow risks regardless of total file counts.

---

## 5. Front-End Strategy: Responsive Grid Options

To enhance the visual browsing experience, the LWC JS controller manages dynamic CSS column layouts via a grid configuration structure (`GRID_OPTIONS`):

```javascript
import { LightningElement, api, track } from 'lwc';

const GRID_OPTIONS = [
    { label: '2-Column View', value: 2, cells: [1, 2] },
    { label: '4-Column View', value: 4, cells: [1, 2, 3, 4] },
    { label: '8-Column View', value: 8, cells: [1, 2, 3, 4, 5, 6, 7, 8] }
];

export default class CustomFileListView extends LightningElement {
    @api headerTitle = 'Attached Files';
    @api gridOption = 4;
    
    @track currentGridColumns = 4;
    gridOptions = GRID_OPTIONS;

    handleGridSwitch(event) {
        const selectedValue = parseInt(event.currentTarget.dataset.value, 10);
        this.currentGridColumns = selectedValue;
    }
}

```

---

## 6. Declarative Governance via Lightning App Builder (`js-meta.xml`)

Administrators can configure object relationships, filter rules, and layout defaults directly within the Lightning App Builder interface without writing code:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="[http://soap.sforce.com/2006/04/metadata](http://soap.sforce.com/2006/04/metadata)">
    <apiVersion>61.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage, lightning__AppPage">
            <property name="headerTitle" type="String" label="Header Title" default="Attached Files"/>
            <property name="enableFileUpload" type="Boolean" label="Enable File Upload" default="true"/>
            <property name="enableDeleteFile" type="Boolean" label="Enable Delete File" default="true"/>
            <property name="parentObjectApiName" type="String" label="Parent Object API Name"/>
            <property name="relatedObjectApiName" type="String" label="Related Object API Name"/>
            <property name="relatedToParentField" type="String" label="Related To Parent Field"/>
            <property name="exceptField" type="String" label="Except Field" description="Commas-separated fields to filter out (e.g. IsRichText__c)"/>
            <property name="gridOption" type="Integer" label="Grid Option" default="4"/>
            <property name="pageSize" type="Integer" label="Page Size" default="40"/>
            <property name="fileLookbackMonths" type="Integer" label="File Lookback Months" default="12"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>

```

---

## 7. Key Architectural Takeaways

1. **Defensive Query Design:** Always implement date-range lookback validations (`fileLookbackMonths`) when querying junction entities like `ContentDocumentLink`. Unbounded queries on enterprise data will eventually hit the 50,000 SOQL row limit.
2. **Keyset Cursor over OFFSET:** Compound cursor conditions (`LastModifiedDate` + `Id`) guarantee fast, memory-efficient pagination without hitting Heap Size limits.
3. **Decoupled Service Layer:** Separating business validation from controller endpoints keeps Apex logic modular, testable, and reusable across multiple LWCs.

---

## 8. Conclusion

By pairing a decoupled Controller/Service backend with proactive date-range guardrails and cursor pagination, this custom file manager satisfies both user UI needs (grid views, cross-object files) and strict enterprise platform limits.

```

```