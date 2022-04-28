/****************************************************************************************************
 * Class ui_downstreamOfferConflRegController
 *
 *   Create By	:   ChristianGottlieb (mindsquare AG)
 *   Create Date	:   2022-02-25
 *   Description	:	---
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------                 
 *   * ChristianGottlieb (mindsquare AG)	            2022-02-25       	Init version.
*****************************************************************************************************/

public with sharing class ui_downstreamOfferConflRegController {
    @AuraEnabled
    public static RelatedListResult fetchRecs(
            Id recordId, String recordSObjectType, String relationshipName,
            String relatedSObjectName, String idFieldOnRelationship,
            String stringCriteria, Integer soqlLimit, String parameters, Boolean onlyOtherRecords) {

        String strTitle = ' (';
        List <SObject> listsObjects = new List <SObject>();
        List<String> parametersList = new List<String>();
        if (parameters != null) {
            parametersList = parameters.split(',');
        }
        RelatedListResult result = new RelatedListResult();
        String recordWithPrimaryListSOQL = 'SELECT Id, ';
        for (String parameter : parametersList) {
            recordWithPrimaryListSOQL += parameter + ', ';
        }
        recordWithPrimaryListSOQL +=
                '(SELECT ' + idFieldOnRelationship +
                        ' FROM ' + relationshipName + ')' +
                        ' FROM ' + recordSObjectType +
                        ' WHERE Id' + ' = \'' + recordId + '\' LIMIT 1';
        SObject record = Database.query(recordWithPrimaryListSOQL)[0];
        List<SObject> primaryRelatedList = record.getSObjects(relationshipName);
        Set<Id> relatedListRecordIds = new Set<Id>();
        Set<Id> idsForSecondaryRelatedList = new Set<Id>();
        for (SObject item : primaryRelatedList) {
            relatedListRecordIds.add((Id) item.get('Id'));
            idsForSecondaryRelatedList.add((Id) item.get(idFieldOnRelationship));
        }

        String secondaryRelatedListSOQL = 'SELECT Id FROM ' + relatedSObjectName +
                ' WHERE ' + idFieldOnRelationship + ' IN :idsForSecondaryRelatedList';
        if (onlyOtherRecords) {
            secondaryRelatedListSOQL += ' AND Id NOT IN:relatedListRecordIds ';
        }

        if (parameters != null) {
            for (Integer i = 0; i < parametersList.size(); i++) {
                stringCriteria = stringCriteria.replace('#parameter[' + i + ']#', String.valueOf(record.get(parametersList[i])).left(10));
            }
        }

        if (String.isNotBlank(stringCriteria)) {
            secondaryRelatedListSOQL += ' ' + stringCriteria;
        }
        secondaryRelatedListSOQL += ' LIMIT ' + soqlLimit;
        listsObjects = Database.query(secondaryRelatedListSOQL);
        Integer intCount = listsObjects.size();

        if (intCount > soqlLimit) {
            List <SObject> tempListsObjects = new List<SObject>();
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
    }
}