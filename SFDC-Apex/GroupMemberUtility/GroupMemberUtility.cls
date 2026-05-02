 /**
 * @description       : Utility class for retrieving Public Group member emails.
 * Supports both flat (direct members only) and recursive (nested subgroups/roles) resolution.
 * Includes protection against circular references in group structures. 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-03-28
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-03-28   SFDC-Hermes   Initial Version
 **/
public class GroupMemberUtility {

    /**
     * @description Entry point to retrieve a unique list of active user emails from a specific Public Group.
     * @param groupDevName The DeveloperName of the Public Group to inspect.
     * @param doRecursive If true, drills down into all nested subgroups and roles; if false, fetches direct members only.
     * @return List<String> A unique list of active, non-null email addresses.
     */
    public static List<String> getRecipient(String groupDevName, Boolean doRecursive) {
        List<Group> groups = [SELECT Id FROM Group 
                            WHERE DeveloperName = :groupDevName 
                            LIMIT 1
                            ];
        if (groups.isEmpty()) return new List<String>();

        Set<Id> allUserIds = new Set<Id>();
        Id rootGroupId = groups[0].Id;

        if (doRecursive) {
            // [Path A] Recursive Mode
            Set<Id> processedGroupIds = new Set<Id>();
            resolveRecursive(rootGroupId, allUserIds, processedGroupIds);
        } else {
            // [Path B] Flat Mode
            resolveFlat(rootGroupId, allUserIds);
        }

        return getUserEmails(allUserIds);
    }

    /**
     * @description Recursive helper method to traverse through nested group hierarchies.
     * @param currentGroupId The ID of the group currently being processed.
     * @param allUserIds A collector set for all identified User IDs.
     * @param processedGroupIds A set to track visited groups to prevent infinite loops (Circular References).
     */
    private static void resolveRecursive(Id currentGroupId, Set<Id> allUserIds, Set<Id> processedGroupIds) {
        if (processedGroupIds.contains(currentGroupId)) return;
        processedGroupIds.add(currentGroupId);

        Set<Id> subGroupIds = new Set<Id>();
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :currentGroupId]) {
            Id memberId = gm.UserOrGroupId;
            if (memberId.getSObjectType() == User.SObjectType) {
                allUserIds.add(memberId);
            } else if (memberId.getSObjectType() == Group.SObjectType) {
                subGroupIds.add(memberId);
            }
        }

        if (!subGroupIds.isEmpty()) {
            allUserIds.addAll(getUserIdsByRoleGroups(subGroupIds));
            
            for (Id subId : subGroupIds) {
                resolveRecursive(subId, allUserIds, processedGroupIds);
            }
        }
    }

    /**
     * @description Non-recursive helper method to process direct members of a group.
     * @param groupId The ID of the group to inspect.
     * @param allUserIds A collector set for all identified User IDs.
     */
    private static void resolveFlat(Id groupId, Set<Id> allUserIds) {
        Set<Id> subGroupIds = new Set<Id>();
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId]) {
            Id memberId = gm.UserOrGroupId;
            if (memberId.getSObjectType() == User.SObjectType) {
                allUserIds.add(memberId);
            } else if (memberId.getSObjectType() == Group.SObjectType) {
                subGroupIds.add(memberId);
            }
        }
        if (!subGroupIds.isEmpty()) {
            allUserIds.addAll(getUserIdsByRoleGroups(subGroupIds));
        }
    }

    /**
     * @description Maps internal 'Role' type groups to their actual UserRoles to identify assigned users.
     * @param subGroupIds A set of IDs confirmed to be Group records.
     * @return Set<Id> A set of User IDs associated with the identified Roles.
     */
    private static Set<Id> getUserIdsByRoleGroups(Set<Id> subGroupIds) {
        Set<Id> roleIds = new Set<Id>();
        for (Group g : [
            SELECT RelatedId FROM Group 
            WHERE Id IN :subGroupIds AND RelatedId != null 
            AND Type IN ('Role', 'RoleAndSubordinates', 'RoleAndSubordinatesInternal')
        ]) {
            roleIds.add(g.RelatedId);
        }
        
        Set<Id> userIds = new Set<Id>();
        if (!roleIds.isEmpty()) {
            for (User u : [SELECT Id FROM User WHERE UserRoleId IN :roleIds AND IsActive = true]) {
                userIds.add(u.Id);
            }
        }
        return userIds;
    }

    /**
     * @description Converts a set of User IDs into a unique list of active email addresses.
     * @param userIds A set of unique User IDs.
     * @return List<String> A list of unique, valid email addresses.
     */
    private static List<String> getUserEmails(Set<Id> userIds) {
        if (userIds.isEmpty()) return new List<String>();
        Set<String> emailSet = new Set<String>();
        for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = true AND Email != null]) {
            emailSet.add(u.Email);
        }
        return new List<String>(emailSet);
    }
}