---
layout: single
title: "Salesforce Apex Byte Manipulation: Managing Multi-byte Strings via Byte-size Logic"
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
    Integer byteLength = Blob.valueOf(txt).size(); 
    return byteLength <= 90;
}

```

### 2. Strategic Splitting (splitByByte)
If a string exceeds the limit, we need to chunk it. Simply cutting the string by length might break a multi-byte character in half, leading to data corruption. This logic ensures each chunk is valid and stays under the byte limit.

```java

/**
 * @description Splits a string into multiple chunks, each within the max byte limit.
 */
private static List<String> splitByByte(String input) {
    List<String> result = new List<String>();
    if (String.isEmpty(input)) return result;

    Integer totalBytes = 0;
    String currentChunk = '';

    for (Integer i = 0; i < input.length(); i++) {
        String ch = input.substring(i, i + 1);
        // Measure each character's byte size individually
        Integer chBytes = Blob.valueOf(ch).size();

        if (totalBytes + chBytes > MAX_BYTE_LIMIT) {
            // If adding this char exceeds the limit, push the current chunk and start new
            result.add(currentChunk);
            currentChunk = ch;
            totalBytes = chBytes;
        } else {
            currentChunk += ch;
            totalBytes += chBytes;
        }
    }

    if (!String.isEmpty(currentChunk)) {
        result.add(currentChunk);
    }

    return result;
}

```

---
## 🧐 Architect's Insight: Performance & Precision
1. The Cost of Blob.valueOf()
Inside a loop, Blob.valueOf() can be CPU-intensive if the string is massive. For extremely large texts, consider using a Buffer approach or processing in larger blocks. However, for standard integration payloads (like SMS messages or field updates), this greedy character-by-character check is the safest way to ensure character integrity.

2. The "90-Byte" Threshold: SMS vs. MMS Strategy
In a recent enterprise project involving telecommunications integration, I faced a specific business constraint: the 90-byte threshold.

In many messaging protocols, once a payload exceeds 90 bytes, the message is automatically converted from a standard SMS to a more expensive MMS (or LMS). To manage operational costs and ensure predictable messaging behavior, I implemented this byte-splitting logic. By centralizing this **"90-byte rule"** in a utility, the system can gracefully "chunk" long texts into multiple standard SMS segments, preventing unintended MMS conversions across the entire application. It’s a perfect example of how code architecture directly impacts cost efficiency.

3. Preventing Data Corruption
By measuring the byte size of each character before adding it to the chunk, we ensure that a 3-byte character isn't accidentally cut between two different chunks, which would render the character unreadable.

## 🎯 Conclusion
In a globalized Salesforce environment, being "byte-aware" is not optional—it's a requirement for robust integration. By leveraging Blob.valueOf().size(), we move from fragile **"Length-based"** logic to a more resilient **"Byte-based"** architecture.

👉 [Salesforce Official Blob Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_blob.htm)
👉 [View Utility Code on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-Apex/StringUtility)

---
