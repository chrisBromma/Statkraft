/****************************************************************************************************
     	* Class msCSVtoSObjectRecordsConverterAction
     	*
     	*   Create By	:   MandyBebenroth (mindsquare GmbH)
     	*   Create Date	:   08.09.2020
     	*   Description	:	---
     	*
     	*   Modification Log:
    	*   -------------------------------------------------------------------------------------------------
    	*   * Developer                        	Date             	Description
    	*   * -----------------------------------------------------------------------------------------------                 
    	*   * MandyBebenroth (mindsquare GmbH)		08.09.2020       	Init version.
    	*****************************************************************************************************/
public with sharing class msCSVtoSObjectRecordsConverterAction {

    public class ActionInput {
        @InvocableVariable(Label='Object API Name' Required=true)
        public String objectApiName;

        @InvocableVariable(Label='CSV File ID' Required=true)
        public String contentDocumentId;
    }

    public class ActionOutput {
        @InvocableVariable(Label='List(collection) of Records')
        public SObject[] records;
    }

    public class FlowCustomException extends Exception {
    }

    @InvocableMethod(Label='CSV to SObject records Converter')
    public static ActionOutput[] csvToSObjectsRecordsConverter(ActionInput[] inputs) {
        if (inputs.size() > 1) {
            throw new FlowCustomException('This action is only supported in Screen flows.');
        }

        SObjectType sObjType = ((SObject) Type.forName(inputs[0].objectApiName).newInstance()).getSObjectType();
        Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        Blob csvBlobContent = getCsvContent(inputs[0].contentDocumentId);
        String csvStringContent = blobToString(csvBlobContent, 'ISO-8859-1');
        csvStringContent = csvStringContent.replaceAll('(\r\n|\r)', '\n');

        String[] csvRows = csvStringContent.split('\n');
        String[] fields = csvRows[0].split(','); //Gives all the API names of the fields from the 1st CSV row
        csvRows.remove(0);
        Map<String, Schema.DisplayType> fieldToFieldTypeMap = new Map<String, Schema.DisplayType>();
        for (String field : fields) {
            fieldToFieldTypeMap.put(field, getFieldType(fieldMap, field));
        }

        ActionOutput[] lstOutput = new ActionOutput[]{
        };
        ActionOutput output = new ActionOutput();
        output.records = new SObject[]{
        };
        for (String row : csvRows) {
            SObject obj = sObjType.newSObject();
            String[] fieldInputValues = row.split(',');

            for (Integer i = 0; i < fields.size(); i++) {
                String fieldValue = fieldInputValues[i];
                Schema.DisplayType fieldType = fieldToFieldTypeMap.get(fields[i]);
                obj.put(fields[i], getConvertedFieldValue(fieldType, fieldValue));
            }
            output.records.add(obj);
        }
        lstOutput.add(output);
        return lstOutput;
    }

    static Blob getCsvContent(String contentDocumentId) {

        ContentVersion csvFile = [
                SELECT
                        VersionData
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                AND IsLatest = TRUE
        ];
        return csvFile.VersionData;
    }

    /* Converting the CSV file input(BLOB format) to a string */
    static String blobToString(Blob input, String inCharset) {
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for (Integer i = 0; i < bytesCount; ++i) {
            bytes[i] = hex.mid(i << 1, 2);
        }
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }

    static Object getConvertedFieldValue(Schema.DisplayType fieldType, String fieldValue) {
        Object convertedFieldValue;
        switch on fieldType {//Setting Field value based on the field data type
            when BOOLEAN {
                convertedFieldValue = String.isEmpty(fieldValue) ? false : Boolean.valueOf(fieldValue);
            }
            when DOUBLE {
                convertedFieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue);
            }
            when CURRENCY {
                convertedFieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue);
            }
            when INTEGER {
                convertedFieldValue = String.isEmpty(fieldValue) ? null : Integer.valueOf(fieldValue);
            }
            when DATE {
                convertedFieldValue = String.isEmpty(fieldValue) ? null : Date.valueOf(formatDate(fieldValue));
            }
            when else {
                convertedFieldValue = fieldValue;
            }
        }
        return convertedFieldValue;
    }

    @TestVisible
    static Schema.DisplayType getFieldType(Map<String, SObjectField> fieldMap, String fieldApiName) {
        if (fieldMap.get(fieldApiName) == null) {
            throw new FlowCustomException('Invalid Field Error: ' + fieldApiName + '. Please double check the API name of the field.');
        }
        return fieldMap.get(fieldApiName).getDescribe().getType();
    }

    public static Date formatDate(String unformattedString) {
        
        String dd = unformattedString.substring(0, 2);
        String mm = unformattedString.substring(3, 5);
        String yyyy = unformattedString.substring(6, 10);

        Date newDate = Date.newInstance(
                Integer.valueOf(yyyy),
                Integer.valueOf(mm),
                Integer.valueOf(dd));
        return newDate;
    }

}