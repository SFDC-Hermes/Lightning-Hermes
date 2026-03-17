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

    @AuraEnabled(cacheable=true)
    public static Map<String, List<ObjectInfo>> getObjectMap() {
        Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
        List<ObjectInfo> standardList = new List<ObjectInfo>();
        List<ObjectInfo> customList = new List<ObjectInfo>();

        for (Schema.SObjectType sType : describeMap.values()) {
            Schema.DescribeSObjectResult result = sType.getDescribe();
            if (result.isSearchable() && result.isQueryable() && result.isUpdateable()) {
                String apiName = result.getName();
                if(!getEncryptionFields(apiName)){
                continue;
            }

            if (!result.isCustom() && (apiName.endsWith('History') || apiName.endsWith('Share') || apiName.endsWith('Feed'))) {
                continue;
            }

            ObjectInfo info = new ObjectInfo(result.getLabel(), apiName);
            if (result.isCustom()) {
                customList.add(info);
            } else {
                standardList.add(info);
            }
        }
    }

    public class ObjectInfo implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;

        public ObjectInfo(String label, String apiName) {
            this.label = label;
            this.apiName = apiName;
        }

        public Integer compareTo(Object compareTo) {
            ObjectInfo other = (ObjectInfo)compareTo;
            if (this.label == null) return -1;
            if (other.label == null) return 1;
            return this.label.compareTo(other.label);
        }
    }
