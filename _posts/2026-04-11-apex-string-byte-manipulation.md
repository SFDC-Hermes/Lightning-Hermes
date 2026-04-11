---
layout: single
title: "Apex: Managing Multi-byte Strings via Byte-size Logic"
date: 2026-04-11
categories:
  - Apex
tags:
  - Apex
  - Salesforce
  - StringManipulation
  - Integration
---

In Salesforce development, we often rely on `String.length()`. However, when integrating with external systems or specific character-limited fields, **Character Count != Byte Size**. 

This is especially true for multi-byte characters (like Korean, Chinese, or Emojis), where a single character can consume 3 or 4 bytes in UTF-8. Today, I’ll share a utility logic to accurately calculate and split strings based on their **Byte size**.

---

## 🏗️ The Problem: Length vs. Bytes

In Apex, `String.length()` returns the number of characters. But most external databases and legacy systems define limits in **Bytes**. 

* **"A"**: 1 Character, 1 Byte
* **"우"**: 1 Character, 3 Bytes (UTF-8)

If you send a 100-character string containing multi-byte characters to a 100-byte field, the transaction will fail. To prevent this, we must translate our strings into **Blobs** to measure their true "weight."

---

## 🛠️ The Implementation: Byte-Aware Utility

Here is the implementation of a byte-size validator and a greedy splitting algorithm.

### 1. Byte-size Validation
Before processing, we check if the string fits within our designated limit (e.g., 90 bytes).

```java
/**
 * @description Validates if the string's byte size is within the limit.
 * @return Boolean - Returns true if it does NOT overflow.
 */
private static Boolean calculateByte(String txt){
    if (String.isEmpty(txt)) return true;
    
    // Convert to Blob to get the actual UTF-8 byte size
    Integer byteLength = Blob.valueOf(txt).size();
    
    return byteLength <= 90;
}