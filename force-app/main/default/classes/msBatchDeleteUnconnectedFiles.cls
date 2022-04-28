/****************************************************************************************************
* Class msBatchDeleteUnconnectedFiles
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-09-02
*   Description	:	This class serves as a cleaner for the ContentManager Component, it will delete all
*                   files that where uploaded, but not connected to any Contract__c or Account records or
*                   who's connection was deleted later on.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-09-02       	Init version.
*   * Dennis Grzyb (mindsquare AG)   	                2021-07-15       	Extend BatchJobBase for Scheduler Framework.
*****************************************************************************************************/

global without sharing class msBatchDeleteUnconnectedFiles extends BatchJobBase implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    global msBatchDeleteUnconnectedFiles(){}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        super.startLogging(BC?.getJobId());
        return Database.getQueryLocator(
                'SELECT Id, ContentDocumentId FROM ContentVersion ' +
                        'WHERE msUploadedByDocumentManagerCmp__c = TRUE ' +
                        'AND IsLatest = TRUE'
        );
    }

    global void execute(Database.BatchableContext bc, List<ContentVersion> scope) {
        super.logInformation(scope, BC?.getJobId(), 'Found ' + scope.size() + ' records.');
        Set<Id> allContentDocumentIds = new Set<Id>();
        Set<Id> allContentDocumentIdsToKeep = new Set<Id>();
        for(ContentVersion cvItem : scope) {
            allContentDocumentIds.add(cvItem.ContentDocumentId);
        }
        List<ContentDocumentLink> allLinks = [  SELECT Id, LinkedEntityId, ContentDocumentId
                                                FROM ContentDocumentLink
                                                WHERE ContentDocumentId IN :allContentDocumentIds];
        for(ContentDocumentLink linkItem : allLinks) {
            String linkedEntityIdPrefix = ((String) linkItem.LinkedEntityId).substring(0,3);
            if(linkedEntityIdPrefix == '001' || linkedEntityIdPrefix == 'a0K') {
                allContentDocumentIdsToKeep.add(linkItem.ContentDocumentId);
            }
        }
        Boolean didDelete = allContentDocumentIds.removeAll(allContentDocumentIdsToKeep);
        if(didDelete || allContentDocumentIdsToKeep.size() == 0) {
            List<ContentDocument> filesToDelete = [SELECT Id FROM ContentDocument WHERE Id IN : allContentDocumentIds];
            delete filesToDelete;
            super.logInformation(filesToDelete, BC?.getJobId(), 'Deleted ' + filesToDelete.size() + ' files.');
        }
        super.logEndOfBatch(scope, BC?.getJobId(), true, 'Finished processing.');
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(BC.getJobId());
    }
}