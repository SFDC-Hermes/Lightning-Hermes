@AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getCustomObjects() {
        Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
        List<ObjectInfo> results = new List<ObjectInfo>();
        for (Schema.SObjectType sType : describeMap.values()) {
            Schema.DescribeSObjectResult result = sType.getDescribe();
            if (result.isCustom() && !result.isDeprecatedAndHidden()) {
                results.add(new ObjectInfo(result.getLabel(), result.getName()));
            }
        }
        return results;
    }
