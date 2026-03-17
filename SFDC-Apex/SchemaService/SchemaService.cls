/**
 * @description Retrieves basic information for all custom objects in the Salesforce Schema.
 *              Filters out deprecated and hidden objects.
 * @return List<ObjectInfo> A list of ObjectInfo containing label and API name for each custom object
 */
@AuraEnabled(cacheable=true)
public static List<ObjectInfo> getObjects() {
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

/**
 * @description Retrieves object information from Salesforce Schema, categorized by standard and custom objects.
 *              Filters objects based on searchability, queryability, and updateability.
 *              Excludes History, Share, and Feed objects for standard objects.
 *              Also excludes objects with encrypted fields.
 * @return Map<String, List<ObjectInfo>> A map containing two keys:
 *         - 'standard': List of standard object information
 *         - 'custom': List of custom object information
 */
@AuraEnabled(cacheable=true)
public static Map<String, List<ObjectInfo>> getObjectMap() {
    Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
    List<ObjectInfo> standardList = new List<ObjectInfo>();
    List<ObjectInfo> customList = new List<ObjectInfo>();

    for (Schema.SObjectType sType : describeMap.values()) {
        Schema.DescribeSObjectResult result = sType.getDescribe();
        if (result.isSearchable() && result.isQueryable() && result.isUpdateable()) {
            String apiName = result.getName();
            if (!getEncryptionFields(apiName)) {
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

    standardList.sort();
    customList.sort();

    Map<String, List<ObjectInfo>> resultMap = new Map<String, List<ObjectInfo>>();
    resultMap.put('standard', standardList);
    resultMap.put('custom', customList);
    return resultMap;
}

/**
 * @description Inner class to hold Salesforce object information.
 *              Implements Comparable interface for sorting by label.
 */
public class ObjectInfo implements Comparable {
    @AuraEnabled public String label;
    @AuraEnabled public String apiName;
    public ObjectInfo(String label, String apiName) {
        this.label = label;
        this.apiName = apiName;
    }

    /**
     * @description Compares this ObjectInfo with another for sorting purposes.
     *              Comparison is based on the label property in ascending order.
     * @param compareTo The object to compare against
     * @return Integer Negative if this < other, 0 if equal, positive if this > other
     */
    public Integer compareTo(Object compareTo) {
        ObjectInfo other = (ObjectInfo)compareTo;
        if (this.label == null) return -1;
        if (other.label == null) return 1;
        return this.label.compareTo(other.label);
    }
}
