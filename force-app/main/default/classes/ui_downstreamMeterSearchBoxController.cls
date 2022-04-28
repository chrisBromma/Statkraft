/****************************************************************************************************
 * Class ui_downstreamMeterSearchBoxController
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

public with sharing class ui_downstreamMeterSearchBoxController {
    @AuraEnabled
    public static RelatedListResult fetchRecs(Id recordId) {

        String strTitle = ' (';
        List <SObject> listsObjects = new List <SObject>();

        RelatedListResult result = new RelatedListResult();
        String recordWithPrimaryListSOQL = 'SELECT Id, ';

        recordWithPrimaryListSOQL +=
                '(SELECT Id, Meter__c, Valid_from__c, Valid_to__c, Installed_Capacity__c' +
                        ' FROM Negotiated_Meter_Registrations__r)' +
                        ' FROM MeterRegistration__c' +
                        ' WHERE Id' + ' = \'' + recordId + '\' LIMIT 1';
        SObject record = Database.query(recordWithPrimaryListSOQL)[0];
        List<SObject> primaryRelatedList = record.getSObjects('Negotiated_Meter_Registrations__r');
        Set<Id> relatedListRecordIds = new Set<Id>();
        Set<Id> idsForSecondaryRelatedList = new Set<Id>();
        for (SObject item : primaryRelatedList) {
            relatedListRecordIds.add((Id) item.get('Id'));
            idsForSecondaryRelatedList.add((Id) item.get('Meter__c'));
        }

        String secondaryRelatedListSOQL = 'SELECT Id FROM MeterRegistration__c' +
                ' WHERE Id NOT IN:relatedListRecordIds ' +
                'AND RecordType.DeveloperName = \'Upstream_Registration\' ' +
                'AND Valid_from__c >= 2023.01.01 ' +
                'AND Installed_Capacity__c > 0 ' +
                'AND Installed_Capacity__c <= 100 ' +
                'AND Country__c = \'Germany\'';


        secondaryRelatedListSOQL += ' LIMIT 4';
        listsObjects = Database.query(secondaryRelatedListSOQL);
        Integer intCount = listsObjects.size();

        if (intCount > 4) {
            List <SObject> tempListsObjects = new List<SObject>();
            for (Integer i = 0; i < 4; i++) {
                tempListsObjects.add(listsObjects.get(i));
            }
            result.listsObject = tempListsObjects;
            strTitle += 4 + '+';

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