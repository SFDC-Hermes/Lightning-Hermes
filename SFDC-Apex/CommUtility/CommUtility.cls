public without sharing class COMM_Util {
    @AuraEnabled(cacheable=true)
    public static List<PicklistWrap> getPicklistWrap(String objectName, String fieldName) {

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();

        List<Schema.PicklistEntry> picklistEntries = objectDescribe.fields.getMap().get(fieldName).getDescribe().getPicklistValues();

        List<PicklistWrap> listWrap = new List<PicklistWrap>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            listWrap.add(new PicklistWrap(entry.getLabel(), entry.getValue()));
        }

        return listWrap;
    }

    public class PicklistWrap {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistWrap(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordName(Id recordId) {
        String result;
        if (recordId == null) return null;
        try{
           String objectApiName = recordId.getSobjectType().getDescribe().getName();

           String query = 'SELECT Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
           List<SObject> results = Database.query(query);
           if (!results.isEmpty()) {
               result = (String)results[0].get('Name');
           }
           return result;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }           
    }
}
