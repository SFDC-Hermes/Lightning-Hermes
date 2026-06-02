/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-04-12
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-04-12   SFDC-Hermes   Initial Version
 * 1.1   2026-06-02   SFDC-Hermes   String to field type 
 **/
public with sharing class StringUtility {
    private static final Integer MAX_BYTE_LIMIT = 90;

    private static Boolean calculateByte(String txt){
        if (String.isEmpty(txt)) return true;
        Integer byteLength = Blob.valueOf(txt).size(); 
        return byteLength <= MAX_BYTE_LIMIT;
    }

    private static List<String> splitByByte(String input) {
        List<String> result = new List<String>();
        if (String.isEmpty(input)) return result;

        Integer totalBytes = 0;
        String currentChunk = '';

        for (Integer i = 0; i < input.length(); i++) {
            String ch = input.substring(i, i + 1);
            // Measure each character's byte size individually
            Integer chBytes = Blob.valueOf(ch).size();

            if (totalBytes + chBytes > MAX_BYTE_LIMIT) {
                // If adding this char exceeds the limit, push the current chunk and start new
                result.add(currentChunk);
                currentChunk = ch;
                totalBytes = chBytes;
            } else {
                currentChunk += ch;
                totalBytes += chBytes;
            }
        }

        if (!String.isEmpty(currentChunk)) {
            result.add(currentChunk);
        }

        return result;
    }

    // 1.1   2026-06-02   SFDC-Hermes   String to field type 

    private static Object convertFieldValue(String fieldName, Object rawValue, Schema.DescribeFieldResult targetField) {
        if (rawValue == null) {
            return null;
        }

        Schema.DisplayType fieldType = targetField.getType();
        try {
            if (fieldType == Schema.DisplayType.Date) {
                return parseDateValue(rawValue);
            }
            if (isDecimalLikeType(fieldType)) {
                return parseDecimalValue(rawValue);
            }
            if (fieldType == Schema.DisplayType.Integer) {
                Decimal decimalValue = parseDecimalValue(rawValue);
                return decimalValue == null ? null : decimalValue.intValue();
            }
            if (fieldType == Schema.DisplayType.Datetime) {
                return parseDateTimeValue(rawValue);
            }

            String textValue = normalizeString(rawValue);
            return String.isBlank(textValue) ? null : textValue;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field conversion failed. field=' + fieldName + ', value=' + String.valueOf(rawValue)
            );
        }
    }

    private static String normalizeString(Object rawValue) {
        String stringValue = String.valueOf(rawValue);
        if (stringValue == null) {
            return null;
        }

        String normalized = stringValue.trim();
        return (normalized == 'null') ? null : normalized;
    }

    private static Decimal parseDecimalValue(Object rawValue) {
        if (rawValue instanceof Decimal) {
            return (Decimal) rawValue;
        }
        if (rawValue instanceof Integer || rawValue instanceof Long || rawValue instanceof Double) {
            return Decimal.valueOf(String.valueOf(rawValue));
        }

        String normalized = normalizeString(rawValue);
        if (String.isBlank(normalized)) {
            return null;
        }

        normalized = normalized.replace(',', '');
        if (normalized.startsWith('(') && normalized.endsWith(')')) {
            normalized = '-' + normalized.substring(1, normalized.length() - 1);
        }
        return Decimal.valueOf(normalized);
    }

    private static Date parseDateValue(Object rawValue) {
        if (rawValue instanceof Date) {
            return (Date) rawValue;
        }
        if (rawValue instanceof Datetime) {
            return ((Datetime) rawValue).dateGmt();
        }

        String normalized = normalizeString(rawValue);
        if (String.isBlank(normalized)) {
            return null;
        }

        if (normalized.contains('T') || normalized.endsWith('Z')) {
            Datetime parsedDateTime = parseDateTimeValue(normalized);
            return parsedDateTime == null ? null : parsedDateTime.dateGmt();
        }
        if (normalized.length() >= 10) {
            normalized = normalized.substring(0, 10);
        }
        return Date.valueOf(normalized);
    }

    private static Datetime parseDateTimeValue(Object rawValue) {
        if (rawValue instanceof Datetime) {
            return (Datetime) rawValue;
        }
        if (rawValue instanceof Date) {
            Date dateValue = (Date) rawValue;
            return Datetime.newInstanceGmt(dateValue, Time.newInstance(0, 0, 0, 0));
        }

        String normalized = normalizeString(rawValue);
        if (String.isBlank(normalized)) {
            return null;
        }

        String gmtValue = normalizeDateTimeForGmtParse(normalized);
        try {
            return Datetime.valueOfGmt(gmtValue);
        } catch (Exception e) {
            return Datetime.valueOf(gmtValue);
        }
    }

    private static String normalizeDateTimeForGmtParse(String rawText) {
        String normalized = rawText.trim().replace('T', ' ');

        if (normalized.endsWith('Z')) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }

        Integer dotIndex = normalized.indexOf('.');
        if (dotIndex > -1) {
            normalized = normalized.substring(0, dotIndex);
        }

        if (normalized.length() == 10) {
            normalized += ' 00:00:00';
        } else if (normalized.length() == 16) {
            normalized += ':00';
        }
        return normalized;
    }
}
