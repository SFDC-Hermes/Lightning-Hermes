---
layout: single
title: "Apex Get Group Emails: Designing a Hybrid Resolver for Salesforce Groups"
date: 2026-04-01
categories:
  - Development
tags:
  - Apex
  - Salesforce
  - CleanCode
  - SoftwareArchitecture
---

When building enterprise-grade utilities in Salesforce, you often face a trade-off between **performance** and **completeness**. This is especially true when resolving members of a Public Group, which can be flat or deeply nested.

Today, I want to highlight two specific architectural decisions I made in my `GroupMemberUtility` to solve this problem effectively.

---

## 1. The Hybrid Strategy: `doRecursive` Branching

Not every group needs a deep dive. For simple notification lists, a flat check is enough. For organizational hierarchies, recursion is mandatory. I implemented a `doRecursive` toggle to give the calling code control over this behavior.

```java
public static List<String> getRecipient(String groupDevName, Boolean doRecursive) {
    // ... initial group query ...

    if (doRecursive) {
        // Path A: Recursive resolution for deep hierarchies
        Set<Id> processedGroupIds = new Set<Id>();
        resolveRecursive(rootGroupId, allUserIds, processedGroupIds);
    } else {
        // Path B: Flat resolution for high-performance direct checks
        resolveFlat(rootGroupId, allUserIds);
    }

    // ... return user emails ...
}
```

By branching the logic here, we ensure that we only consume the extra SOQL queries required for recursion when explicitly requested. This keeps our utility **Governor Limit friendly** by default.

---

## 2. Deciphering System Roles in `getUserIdsByRoleGroups`

A common "gotcha" in Salesforce development is that **Roles are represented as internal Group records.** To find users assigned to a Role that is part of a Public Group, you have to query these hidden system groups.

In the `getUserIdsByRoleGroups` method, I specifically filter for three distinct Group Types to ensure no user is left behind:

```java
private static Set<Id> getUserIdsByRoleGroups(Set<Id> subGroupIds) {
    Set<Id> roleIds = new Set<Id>();
    
    // Filtering for specific System Group Types
    for (Group g : [
        SELECT RelatedId FROM Group 
        WHERE Id IN :subGroupIds AND RelatedId != null 
        AND Type IN ('Role', 'RoleAndSubordinates', 'RoleAndSubordinatesInternal')
    ]) {
        roleIds.add(g.RelatedId);
    }
    
    // ... query active users assigned to these Role IDs ...
}
```

### Why these three types?
* **`Role`**: Captures users specifically assigned to that exact Role.
* **`RoleAndSubordinates`**: Includes the Role and everyone below it in the hierarchy (External & Internal).
* **`RoleAndSubordinatesInternal`**: Focuses on the internal hierarchy, excluding portal/community users if necessary.

By targeting these three types, the utility accurately maps the `RelatedId` (the actual UserRole ID) back to the users, covering all possible membership scenarios.

---
👉 [View Full Class on GitHub](https://github.com/SFDC-Hermes/Lightning-Hermes/tree/main/SFDC-Apex/GroupMemberUtility)

## Summary

Architecture is about making intentional choices. By implementing **Hybrid Branching** and **Precise Role Mapping**, this utility provides a robust way to handle Salesforce's complex membership model without sacrificing performance.
