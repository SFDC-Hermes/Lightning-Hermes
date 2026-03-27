    private static final String PUBLIC_GROUP_DEVELOPER_NAME = 'GroupDeveloperName';   
    private static final String PUBLIC_GROUP_TYPE = 'GroupType'; 
    /**
     * @description get user Email List from Public Group
     * @return List<String> User Email List
     */
    private static List<String> getRecipient() {
        List<Group> Groups = [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = :PUBLIC_GROUP_TYPE 
            AND DeveloperName = :PUBLIC_GROUP_DEVELOPER_NAME
            LIMIT 1
        ];
        
        if (Groups.isEmpty()) {
            return new List<String>();
        }
        
        Set<Id> userIds = collectGroupMemberUserIds(Groups[0].Id);
        return getUserEmails(userIds);
    }

    private static Set<Id> collectGroupMemberUserIds(Id groupId) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> roleIds = new Set<Id>();
        Set<Id> subGroupIds = new Set<Id>();
        
        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :groupId
        ];
        
        for (GroupMember gm : groupMembers) {
            Id memberOrGroupId = gm.UserOrGroupId;
            Schema.SObjectType sObjectType = memberOrGroupId.getSObjectType();
            
            if (sObjectType == User.SObjectType) {
                userIds.add(memberOrGroupId);
            } else if (sObjectType == Group.SObjectType) {
                subGroupIds.add(memberOrGroupId);
            }
        }
        
        roleIds.addAll(extractRoleIdsFromGroups(subGroupIds));
        userIds.addAll(getUserIdsByRoleIds(roleIds));
        
        return userIds;
    }

    private static Set<Id> extractRoleIdsFromGroups(Set<Id> subGroupIds) {
        Set<Id> roleIds = new Set<Id>();
        
        if (subGroupIds.isEmpty()) {
            return roleIds;
        }
        
        List<Group> roleGroups = [
            SELECT Id, RelatedId, Type 
            FROM Group 
            WHERE Id IN :subGroupIds 
            AND Type IN ('Role', 'RoleAndSubordinates', 'RoleAndSubordinatesInternal')
        ];
        
        for (Group rg : roleGroups) {
            if (rg.RelatedId != null) {
                roleIds.add(rg.RelatedId);
            }
        }
        
        return roleIds;
    }

    private static Set<Id> getUserIdsByRoleIds(Set<Id> roleIds) {
        Set<Id> userIds = new Set<Id>();
        
        if (roleIds.isEmpty()) {
            return userIds;
        }
        
        for (User u : [SELECT Id FROM User WHERE UserRoleId IN :roleIds AND IsActive = true]) {
            userIds.add(u.Id);
        }
        
        return userIds;
    }

    private static List<String> getUserEmails(Set<Id> userIds) {
        Set<String> emails = new Set<String>();
        
        if (userIds.isEmpty()) {
            return new List<String>();
        }
        
        for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = true AND Email != null]) {
            emails.add(u.Email);
        }
        
        return new List<String>(emails);
    }
