public with sharing class FileService {
    private static final Integer DEFAULT_PAGE_SIZE = 40;
    private static final Integer MAX_PAGE_SIZE = 200;
    private static final Integer EXTRA_ROW_FOR_HAS_MORE = 1;
    private static final Set<String> IMAGE_EXTENSIONS = new Set<String>{ 'png', 'jpg', 'jpeg', 'gif', 'bmp', 'svg', 'webp' };
    private static final Map<String, String> ICON_MAP = new Map<String, String>{
        'pdf' => 'doctype:pdf',
        'png' => 'doctype:image',
        'jpg' => 'doctype:image',
        'jpeg' => 'doctype:image',
        'gif' => 'doctype:image',
        'bmp' => 'doctype:image',
        'svg' => 'doctype:image',
        'webp' => 'doctype:image',
        'doc' => 'doctype:word',
        'docx' => 'doctype:word',
        'xls' => 'doctype:excel',
        'xlsx' => 'doctype:excel',
        'ppt' => 'doctype:ppt',
        'pptx' => 'doctype:ppt',
        'csv' => 'doctype:csv',
        'json' => 'doctype:code',
        'txt' => 'doctype:txt',
        'zip' => 'doctype:zip'
    };

    public static List<FileController.RecordNameDto> getObjectNameFieldList(String objectName, List<String> recordIds) {
        List<FileController.RecordNameDto> results = new List<FileController.RecordNameDto>();
        if (String.isBlank(objectName) || recordIds == null || recordIds.isEmpty()) {
            return results;
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        if (!globalDescribe.containsKey(objectName)) {
            throw new AuraHandledException('Invalid object API name.');
        }

        Set<Id> idSet = new Set<Id>();
        for (String recordId : recordIds) {
            if (String.isNotBlank(recordId)) {
                idSet.add(recordId);
            }
        }
        if (idSet.isEmpty()) {
            return results;
        }

        try {
            String nameField = getNameFieldApiName(globalDescribe.get(objectName).getDescribe());
            String query = 'SELECT Id, ' + String.escapeSingleQuotes(nameField) + 
                           ' FROM ' + String.escapeSingleQuotes(objectName) + 
                           ' WHERE Id IN :idSet';

            for (SObject record : Database.query(query, AccessLevel.USER_MODE)) {
                FileController.RecordNameDto dto = new FileController.RecordNameDto();
                dto.id = (String)record.get('Id');
                dto.name = String.valueOf(record.get(nameField));
                results.add(dto);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return results;
    }

    public static FileController.FileQueryResult getFilesByObjectRelation(
        FileController.FileQueryRequest request,
        FileController.FileQueryCursor cursor
    ) {
        FileController.FileQueryResult result = new FileController.FileQueryResult();

        if (request == null) {
            result.message = 'Request parameters cannot be null.';
            return result;
        }

        normalizeRequest(request);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        String validationError = validateRequest(request, globalDescribe);
        if (validationError != null) {
            result.message = validationError;
            return result;
        }

        Datetime cursorModifiedDate = cursor != null ? cursor.cursorModifiedDate : null;
        Id cursorVersionId = cursor != null ? cursor.cursorVersionId : null;

        FileController.FilePageDto pageData = result.data;

        try {
            QueryOptions options = buildQueryOptions(request);
            Set<Id> parentRecordIds = collectParentRecordIds(request);
            RelatedContext relatedContext = resolveRelatedContext(request, globalDescribe);

            if (!String.isBlank(relatedContext.errorMessage)) {
                result.message = relatedContext.errorMessage;
                return result;
            }

            Map<Id, String> parentNameById = getParentNameById(request.parentObjectApiName, parentRecordIds, globalDescribe);
            DocumentLinkContext linkContext = collectDocumentLinkContext(request, relatedContext, parentRecordIds, options);
            pageData.totalCount = linkContext.documentIds.size();
            if (linkContext.documentIds.isEmpty()) {
                result.isSuccess = true;
                return result;
            }

            List<ContentVersion> versions = queryLatestContentVersions(
                linkContext.documentIds,
                options,
                request.exceptField,
                cursorModifiedDate,
                cursorVersionId
            );
            if (versions.isEmpty()) {
                result.isSuccess = true;
                return result;
            }

            trimVersionsForPaging(pageData, versions, options.normalizedPageSize);
            loadRelatedRecordsForPage(request, relatedContext, linkContext, versions, globalDescribe);
            appendFileDtos(pageData, versions, relatedContext, linkContext, parentNameById, request.recordId);
            updateCursor(pageData, versions);
        } catch (Exception e) {
            result.message = toUserFacingError(e, 'An error occurred while retrieving attached files');
            return result;
        }

        result.isSuccess = true;
        return result;
    }

    public static FileController.DeletePermissionResult checkDeleteFilePermission(Id linkedEntityId) {
        FileController.DeletePermissionResult result = new FileController.DeletePermissionResult();
        if (linkedEntityId == null) {
            result.message = 'Invalid deletion request parameters.';
            return result;
        }

        try {
            Id ownerId = getRecordOwnerId(linkedEntityId);
            Boolean isOwner = (ownerId != null && ownerId == UserInfo.getUserId());
            Boolean isSystemAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';

            if (!isOwner && !isSystemAdmin) {
                result.message = 'Insufficient permissions. Only the record owner or System Administrator can delete files.';
                return result;
            }

            result.isAllowed = true;
            result.message = '';
            return result;
        } catch (Exception e) {
            result.message = toUserFacingError(e, 'An error occurred while verifying delete permissions');
            return result;
        }
    }

    public static FileController.FileQueryResult deleteFileLink(Id linkedEntityId, Id contentDocumentId) {
        FileController.FileQueryResult result = new FileController.FileQueryResult();
        if (linkedEntityId == null || contentDocumentId == null) {
            result.message = 'Invalid deletion request parameters.';
            return result;
        }

        try {
            FileController.DeletePermissionResult permission = checkDeleteFilePermission(linkedEntityId);
            if (!permission.isAllowed) {
                result.message = permission.message;
                return result;
            }

            List<ContentDocumentLink> targetLinks = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :linkedEntityId
                AND ContentDocumentId = :contentDocumentId
                WITH USER_MODE
                LIMIT 1
            ];

            if (targetLinks.isEmpty()) {
                result.message = 'Target file link for deletion could not be found.';
                return result;
            }

            delete targetLinks;
            result.isSuccess = true;
            result.message = 'File link successfully deleted.';
            return result;
        } catch (Exception e) {
            result.message = toUserFacingError(e, 'An error occurred while deleting the file');
            return result;
        }
    }

    private static QueryOptions buildQueryOptions(FileController.FileQueryRequest request) {
        QueryOptions options = new QueryOptions();
        options.recordId = request.recordId;
        options.normalizedPageSize = (request.pageSize == null || request.pageSize <= 0)
            ? DEFAULT_PAGE_SIZE
            : Math.min(request.pageSize, MAX_PAGE_SIZE);
        options.queryLimit = options.normalizedPageSize + EXTRA_ROW_FOR_HAS_MORE;
        options.normalizedSearchKeyword = request.searchKeyword == null ? null : request.searchKeyword + '%';
        options.createdByIds = (request.createdByIds == null || request.createdByIds.isEmpty())
            ? null
            : request.createdByIds;

        Date createdDateFrom = String.isBlank(request.createdDateFrom) ? null : Date.valueOf(request.createdDateFrom);
        Date createdDateTo = String.isBlank(request.createdDateTo) ? null : Date.valueOf(request.createdDateTo);
        options.createdDateFromDt = createdDateFrom == null
            ? null
            : Datetime.newInstanceGMT(createdDateFrom.year(), createdDateFrom.month(), createdDateFrom.day(), 0, 0, 0);
        options.createdDateToExclusive = createdDateTo == null
            ? null
            : Datetime.newInstanceGMT(
                createdDateTo.addDays(1).year(),
                createdDateTo.addDays(1).month(),
                createdDateTo.addDays(1).day(),
                0,
                0,
                0
            );
        return options;
    }

    private static Set<Id> collectParentRecordIds(FileController.FileQueryRequest request) {
        Id recordId = request.recordId;
        Set<Id> parentRecordIds = new Set<Id>{ recordId };
        if (String.isBlank(request.firstField) || String.isBlank(request.relatedObjectApiName)) {
            return parentRecordIds;
        }

        String hierarchyQuery =
            'SELECT Id FROM ' + String.escapeSingleQuotes(request.parentObjectApiName) +
            ' WHERE ' + String.escapeSingleQuotes(request.firstField) + ' = :recordId';
        if (!String.isBlank(request.operator)) {
            hierarchyQuery += ' ' + request.operator + ' ' + String.escapeSingleQuotes(request.secondField) + ' = :recordId';
        }

        for (SObject child : Database.query(hierarchyQuery, AccessLevel.USER_MODE)) {
            parentRecordIds.add((Id)child.get('Id'));
        }
        return parentRecordIds;
    }

    private static RelatedContext resolveRelatedContext(
        FileController.FileQueryRequest request,
        Map<String, Schema.SObjectType> globalDescribe
    ) {
        RelatedContext context = new RelatedContext();
        context.effectiveRelatedObjectApiName = request.relatedObjectApiName;

        if (String.isBlank(request.relatedObjectApiName)) {
            context.isDirectParentFileMode = true;
            context.effectiveRelatedObjectApiName = request.parentObjectApiName;
            return context;
        }

        Schema.DescribeSObjectResult relatedDescribe = globalDescribe.get(request.relatedObjectApiName).getDescribe();
        context.relatedToParentField = resolveRelatedToParentField(request, relatedDescribe);
        if (String.isBlank(context.relatedToParentField)) {
            context.errorMessage = 'Could not find parent reference field on the related object.';
            return context;
        }
        return context;
    }

    private static Map<Id, String> getParentNameById(
        String parentObjectName, 
        Set<Id> parentRecordIds,
        Map<String, Schema.SObjectType> globalDescribe
    ) {
        Map<Id, String> parentNameById = new Map<Id, String>();
        if (String.isBlank(parentObjectName) || parentRecordIds == null || parentRecordIds.isEmpty()) {
            return parentNameById;
        }

        Schema.SObjectType sObjectType = globalDescribe.get(parentObjectName);
        if (sObjectType == null) return parentNameById;

        String nameField = getNameFieldApiName(sObjectType.getDescribe());
        String parentNameQuery = 'SELECT Id, ' + String.escapeSingleQuotes(nameField) + 
                                 ' FROM ' + String.escapeSingleQuotes(parentObjectName) + 
                                 ' WHERE Id IN :parentRecordIds';

        for (SObject parentRecord : Database.query(parentNameQuery, AccessLevel.USER_MODE)) {
            Object nameVal = parentRecord.get(nameField);
            parentNameById.put((Id)parentRecord.get('Id'), nameVal != null ? String.valueOf(nameVal) : '');
        }
        return parentNameById;
    }

    private static DocumentLinkContext collectDocumentLinkContext(
        FileController.FileQueryRequest request,
        RelatedContext relatedContext,
        Set<Id> parentRecordIds,
        QueryOptions options
    ) {
        DocumentLinkContext context = new DocumentLinkContext();

        Id linkedEntityId = request.recordId;
        Datetime createdDateFromDt = options.createdDateFromDt;
        Datetime createdDateToExclusive = options.createdDateToExclusive;
        String normalizedSearchKeyword = options.normalizedSearchKeyword;
        List<Id> createdByIds = options.createdByIds;
        List<Id> relatedRecordIds = request.relatedRecordIds;

        String query = 'SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ';
        if (relatedContext.isDirectParentFileMode) {
            query += 'LinkedEntityId = :linkedEntityId';
        } else {
            query +=
                'LinkedEntityId IN (' +
                'SELECT Id FROM ' + String.escapeSingleQuotes(request.relatedObjectApiName) +
                ' WHERE ' + String.escapeSingleQuotes(relatedContext.relatedToParentField) + ' IN :parentRecordIds ';
            if(relatedRecordIds != null && !relatedRecordIds.isEmpty()){
                query += ' AND Id IN :relatedRecordIds ';
            }
            query += ')';
        }
        if (createdDateFromDt != null) {
            query += ' AND ContentDocument.ContentModifiedDate >= :createdDateFromDt';
        }
        if (createdDateToExclusive != null) {
            query += ' AND ContentDocument.ContentModifiedDate < :createdDateToExclusive';
        }
        if (normalizedSearchKeyword != null) {
            query += ' AND ContentDocument.Title LIKE :normalizedSearchKeyword';
        }
        if (createdByIds != null) {
            query += ' AND ContentDocument.CreatedById IN :createdByIds';
        }

        for (ContentDocumentLink link : Database.query(query, AccessLevel.USER_MODE)) {
            context.documentIds.add(link.ContentDocumentId);
            if (!context.docToRelatedRecordId.containsKey(link.ContentDocumentId)) {
                context.docToRelatedRecordId.put(link.ContentDocumentId, link.LinkedEntityId);
            }
        }
        return context;
    }

    private static List<ContentVersion> queryLatestContentVersions(
        Set<Id> documentIds,
        QueryOptions options,
        String exceptField,
        Datetime cursorModifiedDate,
        Id cursorVersionId
    ) {
        Integer queryLimit = options.queryLimit;

        String query =
            'SELECT Id, ContentDocumentId, Title, FileExtension, ContentSize, ContentSizeLong, LastModifiedDate ' +
            'FROM ContentVersion ' +
            'WHERE IsLatest = true ' +
            'AND ContentDocumentId IN :documentIds';

        if(String.isNotBlank(exceptField)){
            for(String field : exceptField.split(',')){
                String trimmedField = field.trim();
                if(String.isNotBlank(trimmedField)){
                    query += ' AND ' + String.escapeSingleQuotes(trimmedField) + ' = false ';
                }
            }
        }

        if (cursorModifiedDate != null && cursorVersionId != null) {
            query += ' AND (LastModifiedDate < :cursorModifiedDate OR (LastModifiedDate = :cursorModifiedDate AND Id < :cursorVersionId))';
        }

        query += ' ORDER BY LastModifiedDate DESC, Id DESC LIMIT :queryLimit';
        return Database.query(query, AccessLevel.USER_MODE);
    }

    private static void loadRelatedRecordsForPage(
        FileController.FileQueryRequest request,
        RelatedContext relatedContext,
        DocumentLinkContext linkContext,
        List<ContentVersion> versions,
        Map<String, Schema.SObjectType> globalDescribe
    ) {
        if (relatedContext.isDirectParentFileMode) {
            return;
        }

        Set<Id> relatedRecordIds = new Set<Id>();
        for (ContentVersion ver : versions) {
            Id relatedRecordId = linkContext.docToRelatedRecordId.get(ver.ContentDocumentId);
            if (relatedRecordId != null) {
                relatedRecordIds.add(relatedRecordId);
            }
        }
        if (relatedRecordIds.isEmpty()) {
            return;
        }

        Schema.SObjectType relatedType = globalDescribe.get(request.relatedObjectApiName);
        String nameField = (relatedType != null) ? getNameFieldApiName(relatedType.getDescribe()) : 'Name';

        String relatedQuery =
            'SELECT Id, ' + String.escapeSingleQuotes(nameField) + ', ' + String.escapeSingleQuotes(relatedContext.relatedToParentField) +
            ' FROM ' + String.escapeSingleQuotes(request.relatedObjectApiName) +
            ' WHERE Id IN :relatedRecordIds';
        relatedContext.relatedMap = new Map<Id, SObject>(Database.query(relatedQuery, AccessLevel.USER_MODE));
    }

    private static void trimVersionsForPaging(FileController.FilePageDto pageData, List<ContentVersion> versions, Integer normalizedPageSize) {
        if (versions.size() > normalizedPageSize) {
            pageData.hasMore = true;
            versions.remove(versions.size() - 1);
        }
    }

    private static void appendFileDtos(
        FileController.FilePageDto pageData,
        List<ContentVersion> versions,
        RelatedContext relatedContext,
        DocumentLinkContext linkContext,
        Map<Id, String> parentNameById,
        Id recordId
    ) {
        for (ContentVersion ver : versions) {
            SObject relatedRecord = relatedContext.relatedMap.get(linkContext.docToRelatedRecordId.get(ver.ContentDocumentId));
            FileController.FileDto fileDto = toFileDto(ver, relatedContext.effectiveRelatedObjectApiName);

            if (relatedContext.isDirectParentFileMode) {
                fileDto.relatedRecordId = String.valueOf(recordId);
                fileDto.relatedRecordName = parentNameById.get(recordId);
                fileDto.parentRecordName = parentNameById.get(recordId);
            } else if (relatedRecord != null) {
                Id parentId = (Id)relatedRecord.get(relatedContext.relatedToParentField);
                fileDto.relatedRecordId = (String)relatedRecord.get('Id');
                String nameField = getNameFieldApiName(relatedRecord.getSObjectType().getDescribe());
                fileDto.relatedRecordName = String.valueOf(relatedRecord.get(nameField));
                fileDto.parentRecordName = parentNameById.get(parentId);
            }

            pageData.files.add(fileDto);
        }
    }

    private static FileController.FileDto toFileDto(ContentVersion ver, String relatedObjectApiName) {
        FileController.FileDto fileDto = new FileController.FileDto();
        fileDto.documentId = ver.ContentDocumentId;
        fileDto.versionId = ver.Id;
        fileDto.title = ver.Title;
        fileDto.extension = ver.FileExtension;
        fileDto.fileName = ver.Title + (String.isNotBlank(ver.FileExtension) ? '.' + ver.FileExtension : '');
        fileDto.icon = getFileIconByExtension(ver.FileExtension);
        fileDto.isImage = isImageExtension(ver.FileExtension);
        fileDto.createdDate = ver.LastModifiedDate;
        fileDto.contentSize = ver.ContentSize;
        Decimal fileSizeBytes = ver.ContentSizeLong != null
            ? Decimal.valueOf(String.valueOf(ver.ContentSizeLong))
            : (ver.ContentSize == null ? null : Decimal.valueOf(ver.ContentSize));
        fileDto.fileMetaInfo = buildFileMetaInfo(ver.LastModifiedDate, fileSizeBytes, ver.FileExtension);
        fileDto.relatedObjectApiName = relatedObjectApiName;
        fileDto.thumbnailUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + ver.Id;
        fileDto.downloadUrl = '/sfc/servlet.shepherd/document/download/' + ver.ContentDocumentId;
        return fileDto;
    }

    private static void updateCursor(FileController.FilePageDto pageData, List<ContentVersion> versions) {
        ContentVersion lastVersion = versions[versions.size() - 1];
        pageData.cursorModifiedDate = lastVersion.LastModifiedDate;
        pageData.cursorVersionId = lastVersion.Id;
    }

    private static Id getRecordOwnerId(Id recordId) {
        if (recordId == null) {
            return null;
        }

        Schema.DescribeSObjectResult describeResult = recordId.getSObjectType().getDescribe();
        if (!describeResult.fields.getMap().containsKey('ownerid')) {
            return null;
        }

        String query = 'SELECT OwnerId FROM ' + String.escapeSingleQuotes(describeResult.getName()) + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.query(query, AccessLevel.USER_MODE);
        return records.isEmpty() ? null : (Id)records[0].get('OwnerId');
    }

    private static String getNameFieldApiName(Schema.DescribeSObjectResult describeResult) {
        for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
            Schema.DescribeFieldResult fDescribe = field.getDescribe();
            if (fDescribe.isNameField()) {
                return fDescribe.getName();
            }
        }
        return 'Id';
    }

    private static String getReferenceFieldApiName(Schema.DescribeSObjectResult sourceDescribe, String targetObjectApiName) {
        List<String> candidates = new List<String>();
        for (String fieldApiName : sourceDescribe.fields.getMap().keySet()) {
            Schema.DescribeFieldResult fieldDescribe = sourceDescribe.fields.getMap().get(fieldApiName).getDescribe();
            if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
                continue;
            }

            for (Schema.SObjectType referencedType : fieldDescribe.getReferenceTo()) {
                if (referencedType.getDescribe().getName() == targetObjectApiName) {
                    candidates.add(fieldApiName);
                    break;
                }
            }
        }

        if (candidates.isEmpty()) {
            return null;
        }

        candidates.sort();
        return candidates[0];
    }

    private static String resolveRelatedToParentField(
        FileController.FileQueryRequest request,
        Schema.DescribeSObjectResult relatedDescribe
    ) {
        if (!String.isBlank(request.relatedToParentField)) {
            return request.relatedToParentField;
        }
        return getReferenceFieldApiName(relatedDescribe, request.parentObjectApiName);
    }

    private static void normalizeRequest(FileController.FileQueryRequest request) {
        request.parentObjectApiName = normalizeString(request.parentObjectApiName);
        request.relatedObjectApiName = normalizeString(request.relatedObjectApiName);
        request.firstField = normalizeString(request.firstField);
        request.operator = String.isBlank(request.operator) ? null : request.operator.trim().toUpperCase();
        request.secondField = normalizeString(request.secondField);
        request.relatedToParentField = normalizeString(request.relatedToParentField);
        request.searchKeyword = normalizeString(request.searchKeyword);
        request.createdDateFrom = normalizeString(request.createdDateFrom);
        request.createdDateTo = normalizeString(request.createdDateTo);
    }

    private static String validateRequest(FileController.FileQueryRequest request, Map<String, Schema.SObjectType> globalDescribe) {
        if (request.recordId == null || String.isBlank(request.parentObjectApiName)) {
            return 'Required request parameters (recordId / parentObjectApiName) are missing.';
        }
        if (!globalDescribe.containsKey(request.parentObjectApiName)) {
            return 'Invalid parent object API name.';
        }
        if (!String.isBlank(request.relatedObjectApiName) && !globalDescribe.containsKey(request.relatedObjectApiName)) {
            return 'Invalid related object API name.';
        }
        if (!String.isBlank(request.relatedToParentField)) {
            if (String.isBlank(request.relatedObjectApiName)) {
                return 'Related object API name is required when specifying a related parent field.';
            }
            if (!Pattern.matches('^[a-zA-Z0-9_]+$', request.relatedToParentField)) {
                return 'Invalid related parent field API name.';
            }

            Schema.DescribeSObjectResult relatedDescribe = globalDescribe.get(request.relatedObjectApiName).getDescribe();
            if (!isReferenceFieldToTarget(relatedDescribe, request.relatedToParentField, request.parentObjectApiName)) {
                return 'The specified related parent field does not reference the target parent object.';
            }
        }
        if (request.createdByIds != null) {
            for (Id createdById : request.createdByIds) {
                if (createdById == null) {
                    return 'Invalid CreatedById parameter.';
                }
            }
        }
        String exceptFieldError = validateExceptField(request.exceptField);
        if (exceptFieldError != null) {
            return exceptFieldError;
        }
        if (!isValidDateString(request.createdDateFrom)) {
            return 'Invalid Created Date (From) value.';
        }
        if (!isValidDateString(request.createdDateTo)) {
            return 'Invalid Created Date (To) value.';
        }
        if (!String.isBlank(request.createdDateFrom) && !String.isBlank(request.createdDateTo)) {
            Date fromDate = Date.valueOf(request.createdDateFrom);
            Date toDate = Date.valueOf(request.createdDateTo);
            if (fromDate > toDate) {
                return 'End Date cannot be earlier than Start Date.';
            }
        }

        String lookbackError = validateLookbackRange(request);
        if (lookbackError != null) {
            return lookbackError;
        }

        if (!String.isBlank(request.firstField) && !String.isBlank(request.relatedObjectApiName)) {
            if (!isSafeFieldPath(request.firstField)) {
                return 'Invalid Hierarchy Condition Field 1.';
            }
            if (String.isBlank(request.operator) != String.isBlank(request.secondField)) {
                return 'Condition Field 2 is required when an operator is specified.';
            }
            if (!String.isBlank(request.operator) && request.operator != 'AND' && request.operator != 'OR') {
                return 'Hierarchy operator must be either AND or OR.';
            }
            if (!String.isBlank(request.secondField) && !isSafeFieldPath(request.secondField)) {
                return 'Invalid Hierarchy Condition Field 2.';
            }
        }
        return null;
    }

    private static String validateLookbackRange(FileController.FileQueryRequest request) {
        if (request.fileLookbackMonths == null || request.fileLookbackMonths <= 0) {
            return null;
        }
        if (String.isBlank(request.createdDateFrom)) {
            return 'Please set a Start Date for search period. (Maximum ' + request.fileLookbackMonths + ' months)';
        }
        Date fromDate = Date.valueOf(request.createdDateFrom);
        Date toDate = String.isBlank(request.createdDateTo) ? Date.today() : Date.valueOf(request.createdDateTo);
        Date earliestAllowed = toDate.addMonths(-request.fileLookbackMonths);
        if (fromDate < earliestAllowed) {
            return 'Lookback period cannot exceed ' + request.fileLookbackMonths + ' months.';
        }
        return null;
    }

    private static String validateExceptField(String exceptField) {
        if (String.isBlank(exceptField)) {
            return null;
        }
        for (String field : exceptField.split(',')) {
            String trimmedField = String.isBlank(field) ? null : field.trim();
            if (String.isBlank(trimmedField)) {
                continue;
            }
            if (!Pattern.matches('^[a-zA-Z0-9_]+$', trimmedField)) {
                return 'Invalid field specified in except field parameter.';
            }
        }
        return null;
    }

    private static String toUserFacingError(Exception e, String fallbackPrefix) {
        String msg = (e == null || String.isBlank(e.getMessage())) ? '' : e.getMessage();
        if (isAccessError(msg)) {
            return 'Insufficient privileges to access files. Please contact your administrator for required object/field level access.';
        }
        return fallbackPrefix + ': ' + msg;
    }

    private static Boolean isAccessError(String msg) {
        if (String.isBlank(msg)) {
            return false;
        }
        String lower = msg.toLowerCase();
        return lower.contains('insufficient permissions')
            || lower.contains('inaccessible')
            || lower.contains('insufficient access')
            || lower.contains('no access')
            || lower.contains('not accessible')
            || lower.contains('security');
    }

    private static String normalizeString(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static Boolean isValidDateString(String value) {
        if (String.isBlank(value)) {
            return true;
        }
        try {
            Date.valueOf(value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean isImageExtension(String extension) {
        if (String.isBlank(extension)) return false;
        return IMAGE_EXTENSIONS.contains(extension.toLowerCase());
    }

    private static String buildFileMetaInfo(Datetime createdDate, Decimal fileSizeBytes, String extension) {
        List<String> parts = new List<String>();
        if (createdDate != null) {
            parts.add(createdDate.formatGmt('yyyy-MM-dd'));
        }

        String formattedSize = formatFileSize(fileSizeBytes);
        if (!String.isBlank(formattedSize)) {
            parts.add(formattedSize);
        }

        if (!String.isBlank(extension)) {
            parts.add(extension.toUpperCase());
        }

        return String.join(parts, ' · ');
    }

    private static String formatFileSize(Decimal bytes) {
        if (bytes == null || bytes < 0) {
            return '';
        }
        if (bytes < 1024) {
            return String.valueOf(bytes.setScale(0)) + ' B';
        }
        if (bytes < 1024 * 1024) {
            Decimal kb = (bytes / 1024).setScale(0);
            return String.valueOf(kb) + ' KB';
        }

        Decimal mb = bytes / (1024 * 1024);
        return String.valueOf(mb.setScale(1)) + ' MB';
    }

    private static Boolean isSafeFieldPath(String fieldPath) {
        if (String.isBlank(fieldPath)) {
            return false;
        }
        if (fieldPath.startsWith('.') || fieldPath.endsWith('.') || fieldPath.contains('..')) {
            return false;
        }
        return Pattern.matches('^[a-zA-Z0-9_\\.]+$', fieldPath);
    }

    private static Boolean isReferenceFieldToTarget(
        Schema.DescribeSObjectResult sourceDescribe,
        String fieldApiName,
        String targetObjectApiName
    ) {
        if (sourceDescribe == null || String.isBlank(fieldApiName) || String.isBlank(targetObjectApiName)) {
            return false;
        }

        Map<String, Schema.SObjectField> fieldMap = sourceDescribe.fields.getMap();
        if (!fieldMap.containsKey(fieldApiName)) {
            return false;
        }

        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
        if (fieldDescribe.getType() != Schema.DisplayType.Reference) {
            return false;
        }

        for (Schema.SObjectType referencedType : fieldDescribe.getReferenceTo()) {
            if (referencedType.getDescribe().getName() == targetObjectApiName) {
                return true;
            }
        }
        return false;
    }

    private static String getFileIconByExtension(String extension) {
        if (extension == null) return 'doctype:unknown';
        String normalizedExtension = extension.toLowerCase();
        return ICON_MAP.containsKey(normalizedExtension) ? ICON_MAP.get(normalizedExtension) : 'doctype:unknown';
    }

    private class QueryOptions {
        Id recordId;
        Integer normalizedPageSize;
        Integer queryLimit;
        String normalizedSearchKeyword;
        List<Id> createdByIds;
        Datetime createdDateFromDt;
        Datetime createdDateToExclusive;
    }

    private class RelatedContext {
        Map<Id, SObject> relatedMap = new Map<Id, SObject>();
        String relatedToParentField;
        Boolean isDirectParentFileMode = false;
        String effectiveRelatedObjectApiName;
        String errorMessage;
    }

    private class DocumentLinkContext {
        Map<Id, Id> docToRelatedRecordId = new Map<Id, Id>();
        Set<Id> documentIds = new Set<Id>();
    }
}