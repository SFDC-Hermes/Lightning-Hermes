public with sharing class FileController {

    @AuraEnabled
    public static List<RecordNameDto> getObjectNameFieldList(String objectName, List<String> recordIds) {
        return FileService.getObjectNameFieldList(objectName, recordIds);
    }

    @AuraEnabled
    public static FileQueryResult getFilesByObjectRelation(FileQueryRequest request, FileQueryCursor cursor) {
        return FileService.getFilesByObjectRelation(request, cursor);
    }

    @AuraEnabled
    public static DeletePermissionResult checkDeleteFilePermission(Id linkedEntityId) {
        return FileService.checkDeleteFilePermission(linkedEntityId);
    }

    @AuraEnabled
    public static FileQueryResult deleteFileLink(Id linkedEntityId, Id contentDocumentId) {
        return FileService.deleteFileLink(linkedEntityId, contentDocumentId);
    }

    // =========================================================================
    // Data Transfer Objects (DTOs)
    // =========================================================================
    public class RecordNameDto {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
    }

    public class FileQueryResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public FilePageDto data;
        public FileQueryResult() {
            this.isSuccess = false;
            this.message = '';
            this.data = new FilePageDto();
        }
    }

    public class DeletePermissionResult {
        @AuraEnabled public Boolean isAllowed;
        @AuraEnabled public String message;
        public DeletePermissionResult() {
            this.isAllowed = false;
            this.message = '';
        }
    }

    public class FileDto {
        @AuraEnabled public String documentId;
        @AuraEnabled public String versionId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileName;
        @AuraEnabled public String extension;
        @AuraEnabled public String icon;
        @AuraEnabled public Boolean isImage;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Integer contentSize;
        @AuraEnabled public String fileMetaInfo;
        @AuraEnabled public String relatedObjectApiName;
        @AuraEnabled public String thumbnailUrl;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String relatedRecordId;
        @AuraEnabled public String relatedRecordName;
        @AuraEnabled public String parentRecordName;
    }

    public class FilePageDto {
        @AuraEnabled public List<FileDto> files;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Datetime cursorModifiedDate;
        @AuraEnabled public Id cursorVersionId;
        public FilePageDto() {
            this.files = new List<FileDto>();
            this.hasMore = false;
            this.totalCount = 0;
            this.cursorModifiedDate = null;
            this.cursorVersionId = null;
        }
    }

    public class FileQueryRequest {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String parentObjectApiName { get; set; }
        @AuraEnabled public String relatedObjectApiName { get; set; }
        @AuraEnabled public String relatedToParentField { get; set; }
        @AuraEnabled public String firstField { get; set; }
        @AuraEnabled public String operator { get; set; }
        @AuraEnabled public String secondField { get; set; }
        @AuraEnabled public String exceptField { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public String searchKeyword { get; set; }
        @AuraEnabled public String createdDateFrom { get; set; }
        @AuraEnabled public String createdDateTo { get; set; }
        @AuraEnabled public List<Id> createdByIds { get; set; }
        @AuraEnabled public Integer fileLookbackMonths { get; set; }
        @AuraEnabled public List<Id> relatedRecordIds { get; set; }
    }

    public class FileQueryCursor {
        @AuraEnabled public Datetime cursorModifiedDate { get; set; }
        @AuraEnabled public Id cursorVersionId { get; set; }
    }
}