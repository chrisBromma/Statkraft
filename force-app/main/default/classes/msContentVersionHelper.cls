/****************************************************************************************************
 * Class msContentVersionHelper
 *
 *   Create By	 : --
 *   Create Date : --
 *   Description :
 *                  hdp_ -  Historical Data Passing, Documents that are Historical Data will be passed from Offers to their Resulting Contract
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                                Date		    Description
 *   * -----------------------------------------------------------------------------------------------
 *   *
 *****************************************************************************************************/

public without sharing class msContentVersionHelper {

    private List<ContentVersion> triggerOld;
    private List<ContentVersion> triggerNew;
    private Map<Id, ContentVersion> oldMap;
    private Map<Id, ContentVersion> newMap;

    public msContentVersionHelper(
            List<ContentVersion> oldList,
            List<ContentVersion> newList,
            Map<Id, ContentVersion> mapOld,
            Map<Id, ContentVersion> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Global Variables and Statics
    private static final String ATTACHMENT_TYPE_HISTORICAL_DATA = 'Historical Data';

    //SOQL Maps
    private Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
    private Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>();

    //DML Lists/Maps
    public List<ContentDocumentLink> contentDocumentLinkInsertList = new List<ContentDocumentLink>();

    //Historical Data Passing variables
    private Set<Id> hdp_contentDocumentIdsOfNewHistoricalData = new Set<Id>();
    private Map<Id, Set<Id>> hdp_contentDocumentIdToOfferId = new Map <Id, Set<Id>>();
    private Set<Id> hdp_offerIds = new Set<Id>();
    private Map<Id, Id> hdp_offerIdsToContractIds = new Map<Id, Id>();
    private Map<Id, Set<Id>> hdp_establishedFileConnectionsToContracts = new Map<Id, Set<Id>>();

    //SOQL methods
    public void load_ContentDocumentLinks() {
        if (!hdp_contentDocumentIdsOfNewHistoricalData.isEmpty()) {
            cdlMap = new Map<Id, ContentDocumentLink>([
                    SELECT Id, LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE ContentDocumentId IN :hdp_contentDocumentIdsOfNewHistoricalData
            ]);
        }
    }

    public void load_Offers() {
        if (!hdp_offerIds.isEmpty()) {
            offerMap = new Map<Id, Offer__c>([
                    SELECT Id, Resulting_Contract__c
                    FROM Offer__c
                    WHERE Id IN :hdp_offerIds
            ]);
        }
    }

    //Historical Data Passing methods
    public void hdp_identifyNewHistoricalDataFiles() {
        for (ContentVersion newVersion : newMap.values()) {
            if (hdp_isHistoricalData(newVersion)
                    && hdp_isChangedRelevantForTracing(oldMap.get(newVersion.Id), newVersion)) {
                hdp_contentDocumentIdsOfNewHistoricalData.add(newVersion.ContentDocumentId);
            }
        }
    }

    private Boolean hdp_isHistoricalData(ContentVersion file) {
        return file.Attachement_Type__c == ATTACHMENT_TYPE_HISTORICAL_DATA;
    }

    private Boolean hdp_isChangedRelevantForTracing(ContentVersion oldVersion, ContentVersion newVersion) {
        return oldVersion.Attachement_Type__c != newVersion.Attachement_Type__c;
    }

    public void hdp_mapContentDocumentLinksAndIdentifyOffers() {
        for (ContentDocumentLink linkItem : cdlMap.values()) {
            if (hdp_contentDocumentIdsOfNewHistoricalData.contains(linkItem.ContentDocumentId)
                    && linkItem.LinkedEntityId.getSobjectType() == Offer__c.SObjectType) {
                msLepton.addToMap(linkItem.ContentDocumentId, linkItem.LinkedEntityId, hdp_contentDocumentIdToOfferId);
                hdp_offerIds.add(linkItem.LinkedEntityId);
            }
        }
    }

    public void hdp_mapOffersToTraceToResultingContracts() {
        for (Offer__c offerToTrace : offerMap.values()) {
            if (hdp_offerIds.contains(offerToTrace.Id) && offerToTrace.Resulting_Contract__c != null) {
                hdp_offerIdsToContractIds.put(offerToTrace.Id, offerToTrace.Resulting_Contract__c);
            }
        }
    }

    public void hdp_identifyEstablishedLinksToResultingContracts() {
        if (!hdp_offerIdsToContractIds.isEmpty()) {
            for (ContentDocumentLink linkItem : cdlMap.values()) {
                if (hdp_contentDocumentIdsOfNewHistoricalData.contains(linkItem.ContentDocumentId)
                        && hdp_offerIdsToContractIds.values().contains(linkItem.LinkedEntityId)) {
                    msLepton.addToMap(linkItem.ContentDocumentId,
                            linkItem.LinkedEntityId,
                            hdp_establishedFileConnectionsToContracts);
                }
            }
        }
    }

    public void hdp_linkHistoricalDataToContractIfNotYetLinked(ContentVersion oldVersion, ContentVersion newVersion) {
        if (hdp_isHistoricalData(newVersion) && hdp_isChangedRelevantForTracing(oldVersion, newVersion)) {
            Set<Id> establishedConnections = hdp_establishedFileConnectionsToContracts.get(newVersion.ContentDocumentId);
            if (establishedConnections == null) {
                establishedConnections = new Set<Id>();
            }
            if (hdp_contentDocumentIdToOfferId.containsKey(newVersion.ContentDocumentId)) {
                for (Id offerIdToPassFrom : hdp_contentDocumentIdToOfferId.get(newVersion.ContentDocumentId)) {
                    Id contractIdToPassTo = hdp_offerIdsToContractIds.get(offerIdToPassFrom);
                    if (contractIdToPassTo != null
                            && !establishedConnections.contains(contractIdToPassTo)) {
                        contentDocumentLinkInsertList.add(new ContentDocumentLink(
                                ContentDocumentId = newVersion.ContentDocumentId,
                                LinkedEntityId = contractIdToPassTo
                        ));
                        establishedConnections.add(contractIdToPassTo);
                        msLepton.addToMap(newVersion.ContentDocumentId, contractIdToPassTo, hdp_establishedFileConnectionsToContracts);
                    }
                }
            }
        }
    }


    //TODO: This needs to be refactored
    public static void calculateSapCheckboxes(Map<Id, ContentVersion> oldContentVersionsByIds, List<ContentVersion> newContentVersions) {
        msContractSapCheckboxesHelper helper = new msContractSapCheckboxesHelper();
        Set<Id> contentDocumentIdsToProcess = new Set<Id>();
        for (ContentVersion conVersion : newContentVersions) {
            if (conVersion.Attachement_Type__c != oldContentVersionsByIds.get(conVersion.Id).Attachement_Type__c) {
                Attachmenttypes__c oldAttachmentType = helper.attachmentTypes.get(oldContentVersionsByIds.get(conVersion.Id).Attachement_Type__c);
                Attachmenttypes__c newAttachmentType = helper.attachmentTypes.get(conVersion.Attachement_Type__c);
                if (oldAttachmentType != null && newAttachmentType != null) {
                    for (SObjectField objectField : helper.accountSapCheckboxes) {
                        if ((Boolean) oldAttachmentType.get(objectField.getDescribe().getName()) != (Boolean) newAttachmentType.get(objectField.getDescribe().getName())) {
                            contentDocumentIdsToProcess.add(conVersion.ContentDocumentId);
                        }
                    }
                    for (SObjectField objectField : helper.contractSapCheckboxes) {
                        if ((Boolean) oldAttachmentType.get(objectField.getDescribe().getName()) != (Boolean) newAttachmentType.get(objectField.getDescribe().getName())) {
                            contentDocumentIdsToProcess.add(conVersion.ContentDocumentId);
                        }
                    }
                }
            }
        }
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        if (!contentDocumentIdsToProcess.isEmpty()) {
            for (ContentDocumentLink cdl : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIdsToProcess]) {
                if (cdl.LinkedEntityId.getSobjectType() == Account.getSObjectType()) {
                    accountIds.add(cdl.LinkedEntityId);
                } else if (cdl.LinkedEntityId.getSobjectType() == Contract__c.getSObjectType()) {
                    contractIds.add(cdl.LinkedEntityId);
                }
            }
            if (!accountIds.isEmpty() || !contractIds.isEmpty()) {
                msContractSapCheckboxesQueueable.enqueueCalculation(new msContractSapCheckboxesQueueable(accountIds, contractIds));
            }
        }
    }
}