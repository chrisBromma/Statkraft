/****************************************************************************************************
 * Class ui_RelatedListController
 *
 *   Create By	:   ChristianGottlieb (mindsquare AG)
 *   Create Date	:   2022-02-24
 *   Description	:	---
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------                 
 *   * ChristianGottlieb (mindsquare AG)	            2022-02-24       	Init version.
*****************************************************************************************************/

public class ui_RelatedListController {

    @AuraEnabled
    public static RelatedListResult fetchRecs(
            Id recordId, String recordSObjectType, String recordRelatedIdName,
            String relatedSObjectType, String relatedParentFieldName, String stringCriteria,
            Integer soqlLimit) {

        String strTitle = ' (';
        List <SObject> listsObjects = new List <SObject>();
        RelatedListResult result = new RelatedListResult();

        String recordSOQL = 'SELECT ' + recordRelatedIdName + ' FROM ' + recordSObjectType + ' WHERE Id' + ' = \'' + recordId + '\' LIMIT 1';
        SObject record = Database.query(recordSOQL)[0];
        Id relatedParentId = (Id) record.get(recordRelatedIdName);
        result.relatedRecordId = relatedParentId;

        String strSOQL = 'SELECT Id FROM ' + relatedSObjectType + ' WHERE ' + relatedParentFieldName + ' = \'' + relatedParentId + '\'';
        if (String.isNotBlank(stringCriteria)) {
            strSOQL += ' ' + stringCriteria;
        }

        strSOQL += ' LIMIT ' + soqlLimit;
        listsObjects = Database.query(strSOQL);
        Integer intCount = listsObjects.size();

        if (intCount > soqlLimit) {
            List <SObject> tempListsObjects = new List <SObject>();
            for (Integer i = 0; i < soqlLimit; i++) {
                tempListsObjects.add(listsObjects.get(i));
            }
            result.listsObject = tempListsObjects;
            strTitle += soqlLimit + '+';

        } else {
            result.listsObject = listsObjects;
            strTitle += String.valueOf(intCount);
        }
        strTitle += ')';
        result.strTitle = strTitle;
        return result;
    }

    public class RelatedListResult {
        @AuraEnabled
        public String strTitle;
        @AuraEnabled
        public List<SObject> listsObject;
        @AuraEnabled
        public Id relatedRecordId;
    }

}