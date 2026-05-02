/**
 * @description       : 
 * @author            : SFDC-Hermes
 * @group             : 
 * @last modified on  : 2026-04-12
 * @last modified by  : SFDC-Hermes
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   2026-04-12   SFDC-Hermes   Initial Version
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
}