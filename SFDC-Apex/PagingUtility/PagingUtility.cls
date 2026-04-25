public with sharing class PagingUtility {
    private static final Integer DEFAULT_PAGE_SIZE = 20;
    private static final Integer DEFAULT_PAGE_NUMBER = 1;
    private static final Integer MAX_OFFSET_LIMIT = 2000;

    /**
     * @description Wrapper class to provide data and metadata to the UI (LWC/Aura)
     */
    public class ResultWrapper {
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public List<SObject> recordList { get; set; }
        public ResultWrapper(){
            this.totalCount = 0;
            this.recordList = null;
        }
        public ResultWrapper(Integer totalCount, List<SObject> records) {
            this.totalCount = totalCount;
            this.recordList = records;
        }
    }

    /**
     * 1. Offset-Based Paging (Standard UI)
     * @description Recommended for small to medium datasets (Under 2,000 rows)
     */
    @AuraEnabled(cacheable=true)
    public static ResultWrapper getPagedRecords(String objectName, Integer pageSize, Integer pageNumber) {
        ResultWrapper result = new ResultWrapper();
        if (String.isBlank(objectName)) return result;

        Integer size = (pageSize == null || pageSize < 1) ? DEFAULT_PAGE_SIZE : pageSize;
        Integer page = (pageNumber == null || pageNumber < 1) ? DEFAULT_PAGE_NUMBER : pageNumber;
        Integer offsetValue = (page - 1) * size;

        // Guardrail: Offset Limit
        if (offsetValue > MAX_OFFSET_LIMIT) {
            throw new AuraHandledException('The requested page exceeds the maximum offset limit of 2,000.');
        }

        String safeObj = String.escapeSingleQuotes(objectName);
        String countQuery = 'SELECT COUNT() FROM ' + safeObj;
        String dataQuery = 'SELECT Id, Name, CreatedDate FROM ' + safeObj + 
                           ' ORDER BY CreatedDate DESC LIMIT :size OFFSET :offsetValue';

        try {
            result.totalCount = Database.countQuery(countQuery);
            result.recordList = Database.query(dataQuery);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Paging Error: ' + e.getMessage());
        }
    }

    /**
     * 2. Keyset Pagination (Performance King)
     * @description Recommended for large volumes where random page jumping is not required.
     */
    public static List<SObject> getKeysetRecords(String objectName, Id lastId, Integer pageSize) {
        Integer size = (pageSize == null) ? DEFAULT_PAGE_SIZE : pageSize;
        String safeObj = String.escapeSingleQuotes(objectName);
        
        String query = 'SELECT Id, Name FROM ' + safeObj + 
                       ' WHERE Id > :lastId ORDER BY Id ASC LIMIT :size';
        
        return Database.query(query);
    }

    /**
     * 3. Apex Cursor (Modern High-Volume)
     * @description Recommended for massive datasets (Up to 50M rows)
     */
    public static List<SObject> getRecordsWithCursor(String queryString, Integer startPos, Integer count) {
        try {
            // Initialize the stateful Cursor
            Database.Cursor myCursor = Database.getCursor(queryString);
            
            // Fetch the specific chunk without Offset limitations
            return myCursor.fetch(startPos, count);
        } catch (Exception e) {
            throw new AuraHandledException('Cursor Error: ' + e.getMessage());
        }
    }


}