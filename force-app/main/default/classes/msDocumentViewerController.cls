public without sharing class msDocumentViewerController {

    @AuraEnabled
    public static DocumentViewerWrapper getContentDocuments(Id recordId, FilterWrapper filters) {
        String sObjectName = recordId.getSobjectType().getDescribe().getName();
        DocumentViewerWrapper documentViewerWrapper;
        if(sObjectName == Account.SObjectType.getDescribe().getName()) {
            documentViewerWrapper = getContentDocumentsForAccount(recordId, filters);
        } else if(sObjectName == Contract__c.SObjectType.getDescribe().getName()) {
            documentViewerWrapper = getContentDocumentsForContract(recordId, filters);
        } else if(sObjectName == Opportunity.SObjectType.getDescribe().getName()) {
            documentViewerWrapper = getContentDocumentsForOpportunity(recordId, filters);
        } else {
            documentViewerWrapper = new DocumentViewerWrapper();
        }
        return documentViewerWrapper;
    }

    @AuraEnabled
    public static void deleteContentDocumentLinkId(Id contentDocumentLinkId) {
        try {
            ContentDocumentLink cdl = new ContentDocumentLink(Id = contentDocumentLinkId);
            delete cdl;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Set<String> getAttachmentTypes() {
        Set<String> attachmentTypes = new Set<String>();
        for(Attachmenttypes__c typeItem : Attachmenttypes__c.getAll().values()) {
            if(!typeItem.msIsSendNotifications__c && !typeItem.msIsShowInPortal__c) {
                attachmentTypes.add(typeItem.msPicklist_Value_API_Name__c);
            }
        }
        return attachmentTypes;
    }

    private static Set<String> getBlacklistedAttachmentTypes() {
        Set<String> blackListedAttachmentTypes = new Set<String>();
        for(Attachmenttypes__c typeItem : Attachmenttypes__c.getAll().values()) {
            if (typeItem.msIsSendNotifications__c || typeItem.msIsShowInPortal__c) {
                blackListedAttachmentTypes.add(typeItem.msPicklist_Value_API_Name__c);
            }
        }
        return blackListedAttachmentTypes;
    }

    private static Set<String> getCommercialDocumentsAttachmentTypes() {
        Set<String> commercialDocs = new Set<String>();
        for (Attachmenttypes__c typeItem : Attachmenttypes__c.getAll().values()) {
            if (typeItem.msIsSendNotifications__c == false && typeItem.msIsShowInPortal__c == false && typeItem.Comercial_Document__c == true ) {
                commercialDocs.add(typeItem.msPicklist_Value_API_Name__c);
            }
        }
        return commercialDocs;
    }

    private static DocumentViewerWrapper getContentDocumentsForAccount(Id recordId, FilterWrapper filters) {
        Set<Id> linkedEntityIds = new Set<Id>();
        Map<Id, Account> accountsByIds = new Map<Id, Account>();
        Map<Id, Contract__c> relatedContracts = new Map<Id, Contract__c>();
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>();

        if(filters.fileRange == 'all' || filters.fileRange == 'accounts') {
            String query = 'SELECT Id, Name FROM Account WHERE Id = :recordId';
            if(filters.showChildAccounts) {
                query += ' OR Negotiating_Party__c = :recordId';
            }
            accountsByIds = new Map<Id, Account>((List<Account>) Database.query(query));
            linkedEntityIds.addAll(accountsByIds.keySet());
        }

        if(filters.fileRange != 'accounts') {
            String query = 'SELECT Id, Name FROM Contract__c WHERE Contract_Holder__c =: recordId';
            if(filters.showChildAccounts) {
                query += ' OR Contract_Holder__r.Negotiating_Party__c =: recordId';
            }
            relatedContracts = new Map<Id, Contract__c>((List<Contract__c>) Database.query(query));
            linkedEntityIds.addAll(relatedContracts.keySet());
        }

        Map<Id, List<ContentDocumentLink>> linkedDocumentByContentDocumentIds = prepareContentDocumentLinkMap(linkedEntityIds);

        return wrapDocumentViewerResult(
                accountsByIds,
                relatedContracts,
                relatedOpportunities,
                linkedDocumentByContentDocumentIds,
                getContentVersionsByLinkedDocumentIds(linkedDocumentByContentDocumentIds.keySet(), filters)
        );
    }

    private static DocumentViewerWrapper getContentDocumentsForOpportunity(Id recordId, FilterWrapper filters) {
        Set<Id> linkedEntityIds = new Set<Id>();
        Map<Id, Account> accountsByIds = new Map<Id, Account>();
        Map<Id, Contract__c> relatedContracts = new Map<Id, Contract__c>();
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>();

        relatedOpportunities = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity WHERE Id = :recordId]);
        linkedEntityIds.addAll(relatedOpportunities.keySet());

        Map<Id, List<ContentDocumentLink>> linkedDocumentByContentDocumentIds = prepareContentDocumentLinkMap(linkedEntityIds);

        return wrapDocumentViewerResult(
                accountsByIds,
                relatedContracts,
                relatedOpportunities,
                linkedDocumentByContentDocumentIds,
                getContentVersionsByLinkedDocumentIds(linkedDocumentByContentDocumentIds.keySet(), filters)
        );
    }

    private static DocumentViewerWrapper getContentDocumentsForContract(Id recordId, FilterWrapper filters) {
        Contract__c contractWithName = [SELECT Id, Name FROM Contract__c WHERE Id = :recordId];
        Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>();

        Map<Id, List<ContentDocumentLink>> linkedDocumentByContentDocumentIds = prepareContentDocumentLinkMap(new Set<Id>{recordId});

        return wrapDocumentViewerResult(
                new Map<Id, Account>(),
                new Map<Id, Contract__c>{ contractWithName.Id => contractWithName},
                relatedOpportunities,
                linkedDocumentByContentDocumentIds,
                getContentVersionsByLinkedDocumentIds(linkedDocumentByContentDocumentIds.keySet(), filters)
        );
    }

    private static Map<Id, List<ContentDocumentLink>> prepareContentDocumentLinkMap(Set<Id> linkedEntityIds) {
        Map<Id, List<ContentDocumentLink>> linkedDocumentByContentDocumentIds = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink cdl : [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :linkedEntityIds
        ]) {
            if(linkedDocumentByContentDocumentIds.get(cdl.ContentDocumentId) == null) {
                linkedDocumentByContentDocumentIds.put(cdl.ContentDocumentId, new List<ContentDocumentLink>());
            }
            linkedDocumentByContentDocumentIds.get(cdl.ContentDocumentId).add(cdl);
        }
        return linkedDocumentByContentDocumentIds;
    }

    private static List<ContentVersion> getContentVersionsByLinkedDocumentIds(Set<Id> linkedDocumentIds, FilterWrapper filters) {
        if(!linkedDocumentIds.isEmpty()) {
            Set<String> blackListedAttachmentTypes;
            Set<String> filterAttachmentTypes = new Set<String>();
            if(String.isNotEmpty(filters.attachmentType)) {
                filterAttachmentTypes.add(filters.attachmentType);
            }

            if(filters.showCommercialDocuments) {
                Set<String> commercialAttachmentTypes = getCommercialDocumentsAttachmentTypes();
                if(String.isEmpty(filters.attachmentType)) {
                    filterAttachmentTypes.addAll(commercialAttachmentTypes);
                } else if(!commercialAttachmentTypes.contains(filters.attachmentType)) {
                    filterAttachmentTypes.remove(filters.attachmentType);
                }
            }
            
            String query = 'SELECT ' +
                    'Validity_start_date__c, ' +
                    'Validity_end_date__c, ' +
                    'Status_Document__c, ' +
                    'Stage__c, ' +
                    'Title, ' +
                    'Id, ' +
                    'Attachement_Type__c, ' +
                    'CreatedDate, ' +
                    'ContentDocumentId ' +
                    'FROM ContentVersion ' +
                    'WHERE ContentDocumentId IN :linkedDocumentIds ' +
                    'AND IsLatest = TRUE ';

            if(filters.showActiveDocuments) {
                query += ' AND Status_Document__c = true ';
            }

            if(String.isNotEmpty(filters.attachmentType) || filters.showCommercialDocuments) {
                query += ' AND Attachement_Type__c IN :filterAttachmentTypes';
            } else {
                blackListedAttachmentTypes = getBlacklistedAttachmentTypes();
                query += ' AND Attachement_Type__c NOT IN :blackListedAttachmentTypes';
            }
            query += ' ORDER BY CreatedDate DESC, Attachement_Type__c ASC';
            
            return Database.query(query);
        }
        return new List<ContentVersion>();
    }

    private static DocumentViewerWrapper wrapDocumentViewerResult(
            Map<Id, Account> relatedAccountsMap,
            Map<Id, Contract__c> relatedContractsMap,
            Map<Id, Opportunity> relatedOpportunitiesMap,
            Map<Id, List<ContentDocumentLink>> linkedDocumentByContentDocumentIds,
            List<ContentVersion> contentVersionsToProcess
    ) {
        DocumentViewerWrapper documentViewerWrapper = new DocumentViewerWrapper();
        Set<String> attachmentTypes = getAttachmentTypes();
        for(ContentVersion contentVersion : contentVersionsToProcess) {
            if(linkedDocumentByContentDocumentIds.get(contentVersion.ContentDocumentId) != null) {
                attachmentTypes.add(contentVersion.Attachement_Type__c);
                for(ContentDocumentLink cdl : linkedDocumentByContentDocumentIds.get(contentVersion.ContentDocumentId)) {
                    if(cdl != null && cdl.LinkedEntityId != null) {
                        DocumentVersionWrapper documentVersionWrapper = new DocumentVersionWrapper(contentVersion);
                        String sObjectName = cdl.LinkedEntityId.getSobjectType().getDescribe().getName();
                        if(sObjectName == Account.SObjectType.getDescribe().getName()) {
                            documentVersionWrapper.relatedEntityName = relatedAccountsMap.get(cdl.LinkedEntityId).Name;
                            documentVersionWrapper.contentDocumentLinkId = cdl.Id;
                            documentVersionWrapper.relatedEntityUrl = '/' + relatedAccountsMap.get(cdl.LinkedEntityId).Id;
                            documentViewerWrapper.accountDocumentWrappers.add(documentVersionWrapper);
                        } else if(sObjectName == Contract__c.SObjectType.getDescribe().getName()) {
                            documentVersionWrapper.relatedEntityName = relatedContractsMap.get(cdl.LinkedEntityId).Name;
                            documentVersionWrapper.contentDocumentLinkId = cdl.Id;
                            documentVersionWrapper.relatedEntityUrl = '/' + relatedContractsMap.get(cdl.LinkedEntityId).Id;
                            documentViewerWrapper.contractDocumentWrappers.add(documentVersionWrapper);
                        } else if(sObjectName == Opportunity.SObjectType.getDescribe().getName()) {
                            documentVersionWrapper.relatedEntityName = relatedOpportunitiesMap.get(cdl.LinkedEntityId).Name;
                            documentVersionWrapper.contentDocumentLinkId = cdl.Id;
                            documentVersionWrapper.relatedEntityUrl = '/' + relatedOpportunitiesMap.get(cdl.LinkedEntityId).Id;
                            documentViewerWrapper.opportunityDocumentWrappers.add(documentVersionWrapper);
                        }
                    }
                }
            }
        }
        documentViewerWrapper.availableAttachmentTypes.addAll(attachmentTypes);
        documentViewerWrapper.availableAttachmentTypes.sort();
        return documentViewerWrapper;
    }

    public class FilterWrapper {
        @AuraEnabled public String attachmentType { get; set; }
        @AuraEnabled public String fileRange { get; set; }
        @AuraEnabled public Boolean showActiveDocuments { get; set; }
        @AuraEnabled public Boolean showCommercialDocuments { get; set; }
        @AuraEnabled public Boolean showChildAccounts { get; set; }
    }

    public class DocumentVersionWrapper {
        @AuraEnabled public String contentVersionTitle { get; set; }
        @AuraEnabled public Boolean contentVersionStatus { get; set; }
        @AuraEnabled public String contentVersionAttachmentType { get; set; }
        @AuraEnabled public Datetime contentVersionCreatedDate { get; set; }
        @AuraEnabled public Date contentVersionValidityStartDate { get; set; }
        @AuraEnabled public Date contentVersionValidityEndDate  { get; set; }
        @AuraEnabled public String relatedEntityName { get; set; }
        @AuraEnabled public String relatedEntityUrl { get; set; }
        @AuraEnabled public String contentDocumentId { get; set; }
        @AuraEnabled public String contentDocumentLinkId { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String stage { get; set; }

        public DocumentVersionWrapper(ContentVersion contentVer) {
            this.contentVersionTitle = contentVer.Title;
            this.contentVersionStatus = contentVer.Status_Document__c;
            this.contentVersionAttachmentType = contentVer.Attachement_Type__c;
            this.contentVersionValidityStartDate = contentVer.Validity_start_date__c;
            this.contentVersionValidityEndDate = contentVer.Validity_end_date__c;
            this.contentVersionCreatedDate = contentVer.CreatedDate;
            this.contentDocumentId = contentVer.ContentDocumentId;
            this.id = contentVer.Id;
            this.stage = contentVer.Stage__c;
        }
    }

    public class DocumentViewerWrapper {
        @AuraEnabled public List<DocumentVersionWrapper> accountDocumentWrappers { get; set; }
        @AuraEnabled public List<DocumentVersionWrapper> contractDocumentWrappers { get; set; }
        @AuraEnabled public List<DocumentVersionWrapper> opportunityDocumentWrappers { get; set; }
        @AuraEnabled public List<String> availableAttachmentTypes { get; set; }

        public DocumentViewerWrapper() {
            this.accountDocumentWrappers = new List<DocumentVersionWrapper>();
            this.contractDocumentWrappers = new List<DocumentVersionWrapper>();
            this.opportunityDocumentWrappers = new List<DocumentVersionWrapper>();
            this.availableAttachmentTypes = new List<String>();
        }
    }
}