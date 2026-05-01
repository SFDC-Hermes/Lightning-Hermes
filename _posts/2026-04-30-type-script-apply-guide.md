---
layout: single
title: "A Step-by-Step Guide: TypeScript for Salesforce"
date: 2026-05-17
categories:
  - Concepts
tags:
  - LWC
  - Salesforce
  - TypeScript
  - Install Guide
---

Modern Salesforce development is no longer just about basic scripting; it’s about building scalable, enterprise-grade applications. Transitioning from JavaScript to TypeScript is a strategic move to significantly reduce runtime errors and enhance developer productivity through static typing.

While Salesforce now provides official build-time support for TypeScript in LWC, we must understand the underlying mechanics: the platform fundamentally runs on JavaScript, and the Org only stores transpiled code. This means the 'Source of Truth' must shift from the Org to Git, marking a true transition to **Source-Driven Development**.

In this guide, we will set up the essential foundation—Node.js and VS Code—which act as the 'engine' to transpile, lint, and validate your code before it ever reaches the cloud. Understanding why we need these local tools is the first step in mastering a professional TypeScript workflow.

---

## 1. Establishing the Environment: Node.js

Before we can use TypeScript, we need the runtime environment that allows our development tools to function.

*   **Install Node.js:** Download and install the LTS version from [nodejs.org](https://nodejs.org/).
*   **Verify Installation:** Open your terminal and run the following command to ensure the Node Package Manager (npm) is ready.

    ```bash

    npm -v

    ```

---

## 2. Optimizing the Workspace: VS Code Configuration

To ensure a smooth developer experience, we need to tune VS Code to ignore metadata noise and recognize TypeScript within LWC.

Modify your **`settings.json`** with the following configurations:

```json
{
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.sfdx": true
  },
  "xml.preferences.showSchemaDocumentationType": "none",
  "salesforcedx-vscode-lwc.preview.typeScriptSupport": true
}

```

Architect's Tip: Excluding .sfdx and node_modules from search significantly improves VS Code performance, especially in large enterprise repositories.

정리해주신 실무적인 절차들을 바탕으로, 아키텍트의 관점에서 왜 각 단계가 필요한지에 대한 설명을 곁들여 완성도 높은 가이드라인을 작성해 드립니다.

_posts/2026-05-17-typescript-install-guide-for-salesforce.md
Markdown
---
layout: single
title: "A Step-by-Step Guide: TypeScript for Salesforce"
date: 2026-05-17
categories:
  - Concepts
tags:
  - LWC
  - Salesforce
  - TypeScript
  - Install Guide
---

Modern Salesforce development is no longer just about basic scripting; it’s about building scalable, enterprise-grade applications. Transitioning from JavaScript to TypeScript is a strategic move to significantly reduce runtime errors and enhance developer productivity through static typing.

While Salesforce now provides official build-time support for TypeScript in LWC, we must understand the underlying mechanics: the platform fundamentally runs on JavaScript, and the Org only stores transpiled code. This means the 'Source of Truth' must shift from the Org to Git, marking a true transition to **Source-Driven Development**.

In this guide, we will set up the essential foundation—Node.js and VS Code—which act as the 'engine' to transpile, lint, and validate your code before it ever reaches the cloud. Understanding why we need these local tools is the first step in mastering a professional TypeScript workflow.

---

## 1. Establishing the Environment: Node.js

Before we can use TypeScript, we need the runtime environment that allows our development tools to function.

*   **Install Node.js:** Download and install the LTS version from [nodejs.org](https://nodejs.org/).
*   **Verify Installation:** Open your terminal and run the following command to ensure the Node Package Manager (npm) is ready.
    ```bash
    npm -v
    ```

---

## 2. Optimizing the Workspace: VS Code Configuration

To ensure a smooth developer experience, we need to tune VS Code to ignore metadata noise and recognize TypeScript within LWC.

Modify your **`settings.json`** with the following configurations:
```json
{
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.sfdx": true
  },
  "xml.preferences.showSchemaDocumentationType": "none",
  "salesforcedx-vscode-lwc.preview.typeScriptSupport": true
}
Architect's Tip: Excluding .sfdx and node_modules from search significantly improves VS Code performance, especially in large enterprise repositories.

## 3. System Permissions: PowerShell (Optional)

If you are working on a Windows environment, you may encounter execution errors when running scripts. Setting the execution policy allows the Salesforce CLI and npm scripts to run securely.

Open PowerShell as Administrator and execute: