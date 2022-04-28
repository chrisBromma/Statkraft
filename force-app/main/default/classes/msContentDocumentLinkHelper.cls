/****************************************************************************************************
 * Class msContentDocumentLinkHelper
 *
 *   Create By	 : Frank Nehler (mindsquare GmbH)
 *   Create Date : 03.04.2019
 *   Description :
 *                  dvl_ -  Document Validation Logic, certain Documents have their individual validity period, example licences,
 *                          if new documents are added, this logic sets the correct validity ending for established records
 *                  hdp_ -  Historical Data Passing, Documents that are Historical Data will be passed from Offers to their Resulting Contract
 *                  guv_ -  General User Visibility of all documents
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                                Date		    Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Frank Nehler (mindsquare GmbH)	        03.04.2019      Init version.
 *****************************************************************************************************/

public without sharing class msContentDocumentLinkHelper {

    private List<ContentDocumentLink> triggerOld;
    private List<ContentDocumentLink> triggerNew;
    private Map<Id, ContentDocumentLink> oldMap;
    private Map<Id, ContentDocumentLink> newMap;
    private static final String ATTACHMENT_TYPE_BILLING_DOCUMENT = 'Billing document';
    private static final String ATTACHMENT_TYPE_HISTORICAL_DATA = 'Historical Data';
    private static final String ATTACHMENT_TYPE_OTHER = 'Other';
    private static final String CONTRACT_API_NAME = 'Contract__c';

    public msContentDocumentLinkHelper(
            List<ContentDocumentLink> oldList,
            List<ContentDocumentLink> newList,
            Map<Id, ContentDocumentLink> mapOld,
            Map<Id, ContentDocumentLink> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //SOQL Maps
    private Map<Id, Attachmenttypes__c> attachmentTypesMap = new Map<Id, Attachmenttypes__c>();
    private Map<Id, ContentDocumentLink> contentDocumentLinkMap = new Map<Id, ContentDocumentLink>();
    private Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
    private Map<Id, Offer__c> offerMap = new Map<Id, Offer__c>();

    //DML Lists/Maps
    public List<ContentDocumentLink> contentDocumentLinkInsertList = new List<ContentDocumentLink>();
    public Map<Id, ContentVersion> contentVersionUpdateMap = new Map<Id, ContentVersion>();

    //Document Validation Logic variables
    private Set<Id> dvl_ContentDocumentIdsToLoad = new Set<Id>();
    private Set<Id> dvl_EntityIdsToLoadCDLsFor = new Set<Id>();
    private Boolean dvl_loadAttachmentTypes = false;
    private Set<String> dvl_contractAttachmentTypes = new Set<String>();
    private Set<String> dvl_contentDocumentIdsToLoadFurther = new Set<String>();
    private ListMapContainer dvl_recordToConVersMap = new ListMapContainer(ContentVersion.SObjectType);
    private Map<Id, ContentVersion> dvl_contDocLinkToConVerMap = new Map<Id, ContentVersion>();

    //Historical Data Passing variables
    private Set<Id> hdp_ContentDocumentIdsToLoad = new Set<Id>();
    private Map<Id, Set<Id>> hdp_documentIdToOfferIdMap = new Map<Id, Set<Id>>();
    private Set<Id> hdp_offerIds = new Set<Id>();
    private Map<Id, Id> hdp_offerIdsToContractIds = new Map<Id, Id>();
    private Map<Id, Set<Id>> hdp_establishedHistoricalDataConnections = new Map<Id, Set<Id>>();
    private Map<Id, ContentVersion> hdp_contDocLinkToConVerMap = new Map<Id, ContentVersion>();

    //SOQL Methods
    public void load_AttachmentTypes() {
        if (dvl_loadAttachmentTypes) {
            attachmentTypesMap = new Map<Id, Attachmenttypes__c>([
                    SELECT msPicklist_Value_API_Name__c, Related_Object__c, msIsSendNotifications__c, msIsShowInPortal__c
                    FROM Attachmenttypes__c
                    WHERE msIsSendNotifications__c = TRUE
                    AND msIsShowInPortal__c = TRUE
                    AND Related_Object__c = :CONTRACT_API_NAME
            ]);
        }
    }

    public void load_ContentDocumentLinks() {
        if (!hdp_offerIdsToContractIds.isEmpty() || !dvl_EntityIdsToLoadCDLsFor.isEmpty()) {
            contentDocumentLinkMap = new Map<Id, ContentDocumentLink>([
                    SELECT ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE (LinkedEntityId IN :hdp_offerIdsToContractIds.values()
                    AND ContentDocumentId IN :hdp_documentIdToOfferIdMap.keySet())
                    OR LinkedEntityId IN :dvl_EntityIdsToLoadCDLsFor
            ]);
        }
    }

    public void load_ContentVersions() {
        if (!dvl_ContentDocumentIdsToLoad.isEmpty()
                || !hdp_ContentDocumentIdsToLoad.isEmpty()) {
            contentVersionMap = new Map<Id, ContentVersion>([
                    SELECT Id, ContentDocumentId, Attachement_Type__c,
                            Validity_end_date__c, Validity_start_date__c, Status_Document__c,
                            IsLatest
                    FROM ContentVersion
                    WHERE (ContentDocumentId IN :dvl_ContentDocumentIdsToLoad
                    OR ContentDocumentId IN :hdp_ContentDocumentIdsToLoad)
                    AND IsLatest = TRUE
            ]);
        }
    }

    public void load_ContentVersionsFurther() {
        if (!dvl_contentDocumentIdsToLoadFurther.isEmpty()) {
            for (ContentVersion versionToLoadFurther : [
                    SELECT Id, ContentDocumentId, Attachement_Type__c,
                            Validity_end_date__c, Validity_start_date__c, Status_Document__c
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :dvl_contentDocumentIdsToLoadFurther
                    AND IsLatest = TRUE
                    AND Id NOT IN :contentVersionMap.keySet()
            ]) {
                contentVersionMap.put(versionToLoadFurther.Id, versionToLoadFurther);
            }
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

    //Document Validation Logic methods
    public void dvl_identifyCVsToLoad() {
        for (ContentDocumentLink linkItem : triggerNew) {
            if (dvl_cdlIsRelevantForValidation(linkItem)) {
                dvl_ContentDocumentIdsToLoad.add(linkItem.ContentDocumentId);
            }
        }
    }

    private Boolean dvl_cdlIsRelevantForValidation(ContentDocumentLink linkItem) {
        return linkItem.LinkedEntityId.getSobjectType() != User.SObjectType;
    }

    public void dvl_mapCDLToContentVersionsAndCheckIfNeedToProceed() {
        for (ContentDocumentLink linkItem : triggerNew) {
            if (dvl_cdlIsRelevantForValidation(linkItem)) {
                for (ContentVersion versionItem : contentVersionMap.values()) {
                    if (linkItem.ContentDocumentId == versionItem.ContentDocumentId
                            && versionItem.IsLatest) {
                        dvl_contDocLinkToConVerMap.put(linkItem.Id, versionItem);
                        if (versionItem.Attachement_Type__c != null) {
                            dvl_loadAttachmentTypes = true;
                        }
                        break;
                    }
                }
            }
        }
    }

    public void dvl_sortAttachmentTypes() {
        for (Attachmenttypes__c attTypeItem : attachmentTypesMap.values()) {
            if (attTypeItem.Related_Object__c == CONTRACT_API_NAME
                    && attTypeItem.msIsShowInPortal__c
                    && attTypeItem.msIsSendNotifications__c) {
                dvl_contractAttachmentTypes.add(attTypeItem.msPicklist_Value_API_Name__c);
            }
        }
    }

    public void dvl_identifyContentVersionsForFurtherProcessing() {
        if (!dvl_ContentDocumentIdsToLoad.isEmpty()) {
            for (ContentVersion versionItem : contentVersionMap.values()) {
                if (dvl_ContentDocumentIdsToLoad.contains(versionItem.ContentDocumentId)
                        && dvl_ContentVersionIsRelevant(versionItem)) {
                    for (ContentDocumentLink linkItem : triggerNew) {
                        if (linkItem.ContentDocumentId == versionItem.ContentDocumentId
                                && linkItem.LinkedEntityId.getSobjectType() != User.SObjectType) {
                            dvl_EntityIdsToLoadCDLsFor.add(linkItem.LinkedEntityId);
                        }
                    }
                }
            }
        }
    }

    private Boolean dvl_ContentVersionIsRelevant(ContentVersion version) {
        return version.IsLatest
                && version.Attachement_Type__c != ATTACHMENT_TYPE_BILLING_DOCUMENT
                && version.Attachement_Type__c != ATTACHMENT_TYPE_OTHER
                && version.Attachement_Type__c != null
                && !dvl_contractAttachmentTypes.contains(version.Attachement_Type__c);
    }

    public void dvl_identifyContentVersionsToLoadFurther() {
        if (!dvl_EntityIdsToLoadCDLsFor.isEmpty()) {
            Set<Id> loadedContentDocumentIds = new Set<Id>();
            for (ContentVersion versionItem : contentVersionMap.values()) {
                if (versionItem.IsLatest) {
                    loadedContentDocumentIds.add(versionItem.ContentDocumentId);
                }
            }
            for (ContentDocumentLink linkItem : contentDocumentLinkMap.values()) {
                if (dvl_EntityIdsToLoadCDLsFor.contains(linkItem.LinkedEntityId)
                        && !loadedContentDocumentIds.contains(linkItem.ContentDocumentId)) {
                    dvl_contentDocumentIdsToLoadFurther.add(linkItem.ContentDocumentId);
                }
            }
        }
    }

    public void dvl_buildDataModel() {
        ListMapContainer contentDocuToContLinks = new ListMapContainer(ContentDocumentLink.SObjectType);
        for (ContentDocumentLink contLink : contentDocumentLinkMap.values()) {
            contentDocuToContLinks.addToMap(contLink.ContentDocumentId, contLink);
        }
        for (ContentVersion contVer : contentVersionMap.values()) {
            List<ContentDocumentLink> relatedContentDocumentLinks = contentDocuToContLinks.get(contVer.ContentDocumentId);
            for (ContentDocumentLink contDocLink : relatedContentDocumentLinks) {
                if (!newMap.containsKey(contDocLink.Id)) {
                    dvl_recordToConVersMap.addToMap(contDocLink.LinkedEntityId, contVer);
                }
            }
        }
    }

    public void dvl_updateValidityPeriodsForDocuments(ContentDocumentLink link) {
        if (dvl_cdlIsRelevantForValidation(link)) {
            ContentVersion relatedVersion = dvl_contDocLinkToConVerMap.get(link.Id);
            if (dvl_ContentVersionIsRelevant(relatedVersion)) {
                dvl_checkForExistingDocuments(link, relatedVersion);
            }
        }
    }

    private void dvl_checkForExistingDocuments(ContentDocumentLink currentRecord, ContentVersion relatedContentVersion) {

        //check if other content versions exist;
        if (dvl_recordToConVersMap.containsKey(currentRecord.LinkedEntityId)) {
            List<ContentVersion> contentVersionsOfEntity = dvl_recordToConVersMap.get(currentRecord.LinkedEntityId);

            //check if new File is active
            if (relatedContentVersion.Validity_end_date__c >= Date.today()
                    || relatedContentVersion.Validity_end_date__c == null) {
                relatedContentVersion.Status_Document__c = true;
                if (relatedContentVersion.Validity_start_date__c == null) {
                    relatedContentVersion.Validity_start_date__c = Date.today();
                }

                //check if active file with same Attachment Type exists
                for (ContentVersion contVer : contentVersionsOfEntity) {
                    if (contVer.Attachement_Type__c == relatedContentVersion.Attachement_Type__c
                            && relatedContentVersion.Status_Document__c == true) {
                        contVer.Validity_end_date__c = Date.today();
                        contVer.Status_Document__c = false;
                        contentVersionUpdateMap.put(contVer.Id, contVer);
                    }
                }
            }
        } else if (relatedContentVersion.Validity_end_date__c >= Date.today()
                || relatedContentVersion.Validity_end_date__c == null) {
            relatedContentVersion.Status_Document__c = true;
            if (relatedContentVersion.Validity_start_date__c == null) {
                relatedContentVersion.Validity_start_date__c = Date.today();
            }
        }
        contentVersionUpdateMap.put(relatedContentVersion.Id, relatedContentVersion);
    }

    //Historical Data Passing Methods
    public void hdp_identifyCVsToLoad() {
        for (ContentDocumentLink linkItem : triggerNew) {
            if (hdp_linkIsRelevant(linkItem)) {
                hdp_ContentDocumentIdsToLoad.add(linkItem.ContentDocumentId);
            }
        }
    }

    private Boolean hdp_linkIsRelevant(ContentDocumentLink linkItem) {
        return linkItem.LinkedEntityId.getSobjectType() == Offer__c.SObjectType;
    }

    public void hdp_initializeDocumentToOfferMap() {
        for (ContentDocumentLink item : triggerNew) {
            if (hdp_linkIsRelevant(item)) {
                msLepton.addToMap(item.ContentDocumentId, item.LinkedEntityId, hdp_documentIdToOfferIdMap);
            }
        }
    }

    public void hdp_identifyOffersToLoad() {
        if (!hdp_ContentDocumentIdsToLoad.isEmpty()) {
            for (ContentVersion versionItem : contentVersionMap.values()) {
                if (versionItem.Attachement_Type__c == ATTACHMENT_TYPE_HISTORICAL_DATA
                        && hdp_documentIdToOfferIdMap.containsKey(versionItem.ContentDocumentId)) {
                    hdp_offerIds.addAll(hdp_documentIdToOfferIdMap.get(versionItem.ContentDocumentId));
                }
            }
        }
    }

    public void hdp_buildDataModel() {
        for (Id offerId : hdp_offerIds) {
            Offer__c offerToTrace = offerMap.get(offerId);
            if (offerToTrace.Resulting_Contract__c != null) {
                hdp_offerIdsToContractIds.put(offerToTrace.Id, offerToTrace.Resulting_Contract__c);
            }
        }
        for (ContentDocumentLink contDocLink : triggerNew) {
            for (ContentVersion contVer : contentVersionMap.values()) {
                if (contVer.IsLatest && contDocLink.ContentDocumentId == contVer.ContentDocumentId) {
                    hdp_contDocLinkToConVerMap.put(contDocLink.Id, contVer);
                }
            }
        }
    }

    public void hdp_listEstablishedConnections() {
        if (!hdp_offerIdsToContractIds.values().isEmpty()) {
            for (ContentDocumentLink linkItem : contentDocumentLinkMap.values()) {
                if (hdp_offerIdsToContractIds.values().contains(linkItem.LinkedEntityId)
                        && hdp_documentIdToOfferIdMap.keySet().contains(linkItem.ContentDocumentId)) {
                    msLepton.addToMap(linkItem.ContentDocumentId,
                            linkItem.LinkedEntityId,
                            hdp_establishedHistoricalDataConnections);
                }
            }
        }
    }

    public void hdp_passFileIfNecessary(ContentDocumentLink link) {
        if (hdp_linkIsRelevant(link)) {
            ContentVersion relatedContentVersion = hdp_contDocLinkToConVerMap.get(link.Id);
            if (relatedContentVersion.Attachement_Type__c == ATTACHMENT_TYPE_HISTORICAL_DATA
                    && link.LinkedEntityId.getSobjectType() == Offer__c.SObjectType) {
                Set<Id> establishedConnections = hdp_establishedHistoricalDataConnections.get(link.ContentDocumentId);
                if (establishedConnections == null) {
                    establishedConnections = new Set<Id>();
                }
                Id contractIdToPassTo = hdp_offerIdsToContractIds.get(link.LinkedEntityId);
                if (contractIdToPassTo != null && !establishedConnections.contains(contractIdToPassTo)) {
                    contentDocumentLinkInsertList.add(new ContentDocumentLink(
                            ContentDocumentId = link.ContentDocumentId,
                            LinkedEntityId = contractIdToPassTo
                    ));
                    establishedConnections.add(contractIdToPassTo);
                    msLepton.addToMap(link.ContentDocumentId, contractIdToPassTo, hdp_establishedHistoricalDataConnections);
                }
            }
        }
    }

    //General User Visibility of Documents methods
    public void guv_setVisibility(ContentDocumentLink link) {
        link.Visibility = 'AllUsers';
    }


    public static void calculateSapCheckboxes(Map<Id, ContentDocumentLink> contentDocumentLinks) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        Map<Id, Set<Id>> contentDocumentByLinkedEntityIds = new Map<Id, Set<Id>>();
        for (ContentDocumentLink cdl : contentDocumentLinks.values()) {
            if (cdl.LinkedEntityId.getSobjectType() == Account.SObjectType) {
                accountIds.add(cdl.LinkedEntityId);
                contentDocumentIds.add(cdl.ContentDocumentId);
                fillContentDocumentByEntityMap(contentDocumentByLinkedEntityIds, cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
            if (cdl.LinkedEntityId.getSobjectType() == Contract__c.SObjectType) {
                contractIds.add(cdl.LinkedEntityId);
                contentDocumentIds.add(cdl.ContentDocumentId);
                fillContentDocumentByEntityMap(contentDocumentByLinkedEntityIds, cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        msContractSapCheckboxesHelper checkboxesHelper = new msContractSapCheckboxesHelper();
        Map<Id, Attachmenttypes__c> attachmentTypeByContentDocumentId = checkboxesHelper.getAttachmentTypesByDocumentIds(contentDocumentIds);
        Set<Id> accountIdsToCalculate = extractRecordIdsForSapCalculation([
                SELECT Id, Tax_or_VAT__c, Company_Registration__c
                FROM Account
                WHERE Id IN :accountIds
        ],
                checkboxesHelper.accountSapCheckboxes,
                attachmentTypeByContentDocumentId,
                contentDocumentByLinkedEntityIds
        );
        Set<Id> contractIdsToCalculate = extractRecordIdsForSapCalculation([
                SELECT Id, Single_Signed_Contract__c, Double_Signed_Contract__c
                FROM Contract__c
                WHERE Id IN :contractIds
        ],
                checkboxesHelper.contractSapCheckboxes,
                attachmentTypeByContentDocumentId,
                contentDocumentByLinkedEntityIds
        );
        if (!accountIdsToCalculate.isEmpty() || !contractIdsToCalculate.isEmpty()) {
            msContractSapCheckboxesQueueable.enqueueCalculation(new msContractSapCheckboxesQueueable(accountIdsToCalculate, contractIdsToCalculate));
        }
    }

    private static Set<Id> extractRecordIdsForSapCalculation(
            List<SObject> records,
            Set<SObjectField> checkboxes,
            Map<Id, Attachmenttypes__c> attachmentTypeByContentDocumentId,
            Map<Id, Set<Id>> contentDocumentByLinkedEntityIds
    ) {
        Set<Id> resultIds = new Set<Id>();
        for (SObject sObj : records) {
            shouldTriggerSapCheckForRecord(resultIds, contentDocumentByLinkedEntityIds.get(sObj.Id), checkboxes, attachmentTypeByContentDocumentId, sObj);
        }
        return resultIds;
    }

    private static void shouldTriggerSapCheckForRecord(Set<Id> resultIds, Set<Id> cdIds, Set<SObjectField> checkboxes, Map<Id, Attachmenttypes__c> attachmentTypeByContentDocumentId, SObject sObj) {
        for (Id contentDocumentId : cdIds) {
            if (attachmentTypeByContentDocumentId.get(contentDocumentId) != null
                    && shouldTriggerSapCheckForRecord(checkboxes, attachmentTypeByContentDocumentId.get(contentDocumentId), sObj)) {
                resultIds.add(sObj.Id);
                return;
            }
        }
    }

    private static Boolean shouldTriggerSapCheckForRecord(Set<SObjectField> checkboxes, Attachmenttypes__c currentAttachmentType, SObject sObj) {
        for (SObjectField field : checkboxes) {
            if ((Boolean) currentAttachmentType.get(field.getDescribe().getName())) {
                if ((Trigger.isInsert && !((Boolean) sObj.get(field))) || (Trigger.isDelete && (Boolean) sObj.get(field))) {
                    return true;
                }
            }
        }
        return false;
    }

    private static void fillContentDocumentByEntityMap(Map<Id, Set<Id>> contentDocumentByLinkedEntityIds, Id entityId, Id contentDocId) {
        if (!contentDocumentByLinkedEntityIds.containsKey(entityId)) {
            contentDocumentByLinkedEntityIds.put(entityId, new Set<Id>{
                    contentDocId
            });
        } else {
            contentDocumentByLinkedEntityIds.get(entityId).add(contentDocId);
        }
    }
}