/****************************************************************************************************
 * Class msContentVersionHandler
 *
 *   Create By	 : Christian Gottlieb (mindsquare GmbH)
 *   Create Date : 14.03.2019
 *   Description :
 *                  dvl_ -  Document Validation Logic, certain Documents have their individual validity period, example licences,
 *                          if new documents are added, this logic sets the correct validity ending for established records
 *                  hdp_ -  Historical Data Passing, Documents that are Historical Data will be passed from Offers to their Resulting Contract
 *
 *                 Trigger Handler for the ContentVersion SObject. This class implements the ITrigger
 * 				   interface to help ensure the trigger code is bulkified and all in one place.

 * 				   Document Validity:
 * 				   This class handles the case that a new Content Version is created, that will effectively overwrite
 * 				   Historical Data:
 * 				   If the Attachment Type switches to "Historical Data" and the Content Version is currently connected
 * 				   to a Case, then the Content Version will be connected to all files along the path:
 * 				   Case --> Opportunity --> Offer --> (Resulting) Contract
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                                Date		    Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	    14.03.2019      Init version.
 *   * Christian Gottlieb (mindsquare GmbH)     29.04.2019      V2 for New Core Model
 *   * Christian Gottlieb (mindsquare GmbH)     09.07.2019      Now filters via Custom Setting Attachmenttypes__c
 *   * Steffen Naundorf   (mindsquare GmbH)     09.07.2019      Now with notifications carrying the Attachment type
 *   * Christian Gottlieb (mindsquare AG)       23.03.2021      Added passing of Historical Data from Case to Contract on update
 *****************************************************************************************************/
public without sharing class msContentVersionHandler extends TriggerHandlerExtension {
    private msContentVersionHelper Helper;

    // Constructor
    public msContentVersionHandler() {
        super();
        Helper = new msContentVersionHelper(
                (List<ContentVersion>) Trigger.old,
                (List<ContentVersion>) Trigger.new,
                (Map<Id, ContentVersion>) Trigger.oldMap,
                (Map<Id, ContentVersion>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            Helper.hdp_identifyNewHistoricalDataFiles();
            Helper.load_ContentDocumentLinks();
            Helper.hdp_mapContentDocumentLinksAndIdentifyOffers();
            Helper.load_Offers();
            Helper.hdp_mapOffersToTraceToResultingContracts();
            Helper.hdp_identifyEstablishedLinksToResultingContracts();
            //TODO: This needs to be refactored and checked if we can reduce SOQL load
            msContentVersionHelper.calculateSapCheckboxes((Map<Id, ContentVersion>) Trigger.oldMap, (List<ContentVersion>) Trigger.new);
        }
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        ContentVersion oldVersion = (ContentVersion) oldObj;
        ContentVersion newVersion = (ContentVersion) obj;
        Helper.hdp_linkHistoricalDataToContractIfNotYetLinked(oldVersion, newVersion);
    }

    public override void andFinally() {
        if (!Helper.contentDocumentLinkInsertList.isEmpty()) {
            lstInsert.addAll(Helper.contentDocumentLinkInsertList);
        }

        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
    }
}