/****************************************************************************************************
 * Class msContentDocumentLinkHandler
 *
 *   Create By	 : Christian Gottlieb (mindsquare GmbH)
 *   Create Date : 20.03.2019
 *   Description : Trigger Handler for the ContentDocumentLink SObject. This class implements the ITrigger
 * 				   interface to help ensure the trigger code is bulkified and all in one place.
 *
 *
 * 				   Historical Data: Content Versions with the Attachment Type "Historical Data" that are connected to
 * 				   a Case will be forwarded along the path Case --> Opportunity --> Offer --> (Resulting) Contract
 *
 * 				    dvl_ -  Document Validation Logic, certain Documents have their individual validity period, example licences,
 *                          if new documents are added, this logic sets the correct validity ending for established records
 *                  hdp_ -  Historical Data Passing, Documents that are Historical Data will be passed from Offers to their Resulting Contract
 *                  guv_ -  General User Visibility of all documents
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                                Date		    Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	    20.03.2019      Init version.
 *   * Christian Gottlieb (mindsquare GmbH)     29.04.2019      V2 for New Core Model
 *   * Christian Gottlieb (mindsquare GmbH)     02.07.2019      Removed CDLTrigger
 *   * Christian Gottlieb (mindsquare GmbH)     09.07.2019      Now filters for Custom Setting Attachmenttypes__c
 *   * Frank Nehler (mindsquare GmbH)           03.09.2019      Includes changes for Status_Document__c and Validity
 *   * Christian Gottlieb (mindsquare GmbH)     09.01.2019      Filtered out relations to user objects for versioning
 *   * Christian Gottlieb (mindsquare AG)       22.03.2021      Added logic to pass Historical Data from Case to Contract
 *****************************************************************************************************/
public without sharing class msContentDocumentLinkHandler extends TriggerHandlerExtension {
    private msContentDocumentLinkHelper Helper;

    // Constructor
    public msContentDocumentLinkHandler() {
        super();
        Helper = new msContentDocumentLinkHelper(
                (List<ContentDocumentLink>) Trigger.old,
                (List<ContentDocumentLink>) Trigger.new,
                (Map<Id, ContentDocumentLink>) Trigger.oldMap,
                (Map<Id, ContentDocumentLink>) Trigger.newMap
        );
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            Helper.dvl_identifyCVsToLoad();
            Helper.hdp_initializeDocumentToOfferMap();
            Helper.hdp_identifyCVsToLoad();
            Helper.load_ContentVersions();
            Helper.dvl_mapCDLToContentVersionsAndCheckIfNeedToProceed();
            Helper.load_AttachmentTypes();
            Helper.dvl_sortAttachmentTypes();
            Helper.dvl_identifyContentVersionsForFurtherProcessing();
            Helper.hdp_identifyOffersToLoad();
            Helper.load_Offers();
            Helper.hdp_buildDataModel();
            Helper.load_ContentDocumentLinks();
            Helper.hdp_listEstablishedConnections();
            Helper.dvl_identifyContentVersionsToLoadFurther();
            Helper.load_ContentVersionsFurther();
            Helper.dvl_buildDataModel();
            msContentDocumentLinkHelper.calculateSapCheckboxes((Map<Id, ContentDocumentLink>) Trigger.newMap);
        }
        if (Trigger.isDelete) {
            //TODO: This part needs to be refactored:
            msContentDocumentLinkHelper.calculateSapCheckboxes((Map<Id, ContentDocumentLink>) Trigger.oldMap);
        }
    }


    public override void beforeInsert(SObject obj) {
        ContentDocumentLink link = (ContentDocumentLink) obj;
        Helper.guv_setVisibility(link);
    }

    public override void afterInsert(SObject obj) {
        ContentDocumentLink currentRecord = (ContentDocumentLink) obj;
        Helper.dvl_updateValidityPeriodsForDocuments(currentRecord);
        Helper.hdp_passFileIfNecessary(currentRecord);
    }

    public override void andFinally() {
        if (!Helper.contentDocumentLinkInsertList.isEmpty()) {
            lstInsert.addAll(Helper.contentDocumentLinkInsertList);
        }
        if (!Helper.contentVersionUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contentVersionUpdateMap.values());
        }

        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
        if (!lstUpdate.isEmpty()) {
            update(lstUpdate);
        }
    }
}