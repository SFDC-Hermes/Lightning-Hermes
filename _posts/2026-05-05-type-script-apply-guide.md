---
layout: single
title: "A Step-by-Step Guide: TypeScript for Salesforce"
date: 2026-05-05
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

---

## 3. System Permissions: PowerShell (Optional)

If you are working on a Windows environment, you may encounter execution errors when running scripts. Setting the execution policy allows the Salesforce CLI and npm scripts to run securely.

Open PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Select 'Y' when prompted.

---

## 4. Installing Core Dependencies
Now, we install the "brains" of our operation. We need the TypeScript compiler itself and the specific type definitions for Salesforce and Node.

Global TypeScript Installation

```bash 
npm install -g typescript
```

Next, we install the type definitions. These files do not affect the runtime but are critical for the development phase, providing the IntelliSense that allows VS Code to understand the context of your code.

**Node.js Type Definitions**

Essential for the compiler to recognize standard Node.js environments.

**Salesforce Lightning Types**
This is the most important package for LWC developers. It provides types for decorators like @api, @track, and @wire.

```bash
npm install --save-dev @types/node
npm install --save-dev @salesforce/lightning-types
```

---

## 5. Configuring the Compiler: tsconfig.json
The tsconfig.json file is the blueprint for how TypeScript is converted into JavaScript. It defines the rules and constraints of your code.

First, initialize the configuration:

```bash
tsc --init
```
Then, replace the content with the following configuration. This setup uses a "Transpile-in-place" strategy, which is the most effective approach for the current Salesforce metadata structure.

```json

{
  "extends": "../../../../.sfdx/tsconfig.sfdx.json",
  "compilerOptions": {
    "checkJs": false, 
    "allowJs": true,
    /* File Layout */
    "rootDir": ".", 
    "outDir": ".", 

    /* Environment Settings */
    "target": "es2022",
    "lib": ["es2022", "dom"],
    "moduleResolution": "bundler",
    "module": "ESNext",
    "types": ["@salesforce/lightning-types"],
    "sourceMap": false,
    "declaration": false,
    "declarationMap": true,

    /* Path Mapping: Resolving 'c/component' imports */
    "baseUrl": ".",
    "paths": {
      "c/*": ["force-app/main/default/lwc/*"]
    },

    /* Stricter Typechecking Options */
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": false, 

    /* LWC Architect Standards */
    "verbatimModuleSyntax": true,
    "isolatedModules": true, // Required: LWC compiler transpiles files individually
    "noUncheckedSideEffectImports": true,
    "skipLibCheck": true,
    "moduleDetection": "force",
    "noEmit": false
  },
  "include": [
        "**/*.ts",
        "../../../../.sfdx/typings/lwc/**/*.d.ts"
    ],
    "exclude": [
        "**/__tests__/**",
        "**/*.js"
    ]
}

```

---

## 6.🧐 Architect's Final Review
By aligning your rootDir and outDir, you ensure that the .ts and .js files coexist within the same LWC component folder. However, this raises a critical question for your Git Strategy:

Commit Both? If you commit both .ts and .js, your Org is always in sync, but your PRs will be noisy with auto-generated code.

Commit only .ts? This is the cleanest "Source-Driven" approach, but it requires a CI/CD pipeline to transpile the code into .js before deploying to Salesforce.

Regardless of your choice, remember the golden rule:

"The Org runs the code, but Git owns the logic."

Your TypeScript files are your intellectual property. Manage them with care in your version control system, and treat the transpiled JavaScript as a runtime artifact.

---

## 7. Automating the Workflow: Watch Mode (Optional)
To truly embrace the power of TypeScript, you shouldn't have to run the compiler manually every time you make a change.

By running the "Watch" command in your terminal:

```bash
tsc -w
```

You turn your development environment into a real-time validation engine. The compiler will monitor your .ts files and automatically transpile them into .js upon saving. This ensures that the JavaScript artifacts in your LWC bundles are always in sync with your TypeScript source of truth.

---

## 8. Pro Tip: Managing ESLint Noise in JavaScript (Optional)
If you have the ESLint extension installed in VS Code, you might notice that it flags errors in your .js files alongside your .ts files. While well-intentioned, this can create unnecessary noise in a TypeScript-first project.

Why Disable Linting for JS?
JavaScript is a dynamically typed language, which means it often cannot detect certain types of errors until the code is actually executed at runtime. In our modern workflow, we rely on TypeScript's static analysis to catch these issues during the development phase.

Once your TypeScript is transpiled into JavaScript, the resulting .js file is a "runtime artifact." Checking it again with ESLint is redundant and can lead to confusing warnings.

The Solution: ignorePatterns
To tell ESLint to focus exclusively on your source logic (TS) and ignore the generated artifacts (JS), update your .eslintrc.json file by adding the ignorePatterns property:

```json 
{
  "extends": ["@salesforce/eslint-config-lwc/recommended"],
  /* Ignore all .js files to prevent redundant linting noise */
  "ignorePatterns": ["**/*.js"], 
  "overrides": [
    {
      "files": ["*.test.js"],
      "rules": {
        "@lwc/lwc/no-unexpected-wire-adapter-usages": "off"
      },
      "env": {
        "node": true
      }
    }
  ]
}
```

By adding this, you ensure that your editor stays clean and only alerts you to issues within your Source of Truth—the TypeScript files.

🎯 Conclusion

With Node.js as your engine and TypeScript as your guardrails, you are now equipped to build more resilient Salesforce solutions. This setup is not just about writing code; it is about establishing a professional environment that prioritizes stability and long-term maintainability.
