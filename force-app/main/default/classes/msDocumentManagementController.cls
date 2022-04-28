/****************************************************************************************************
* Class msDocumentManagementController
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   31.01.2019
*   Description	:	This class is a Controller for the Aura Component msDocumentManager
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            31.01.2019          Init version.
*   * Christian Gottlieb (mindsquare GmbH)      09.07.2019          Update for changes on Custom Setting Att.type
*   * Christian Gottlieb (mindsquare GmbH)      02.09.2019          Update to use fileUploader component
*   * Christian Gottlieb (mindsquare GmbH)      08.01.2020          Now handles multiple documents, added access to India
*****************************************************************************************************/
public without sharing class msDocumentManagementController {

    private static final Set<String> SUPPORTED_COUNTRIES = new Set<String>{
            'France', 'Germany', 'India'
    };


    @AuraEnabled
    public static List<Attachmenttypes__c> getAttachmentTypes(Id recordId) {
        String sObjectName = recordId.getSobjectType().getDescribe().getName();
        String country = '';
        String relatedSObjectLimitation = '';
        switch on sObjectName {
            when 'Account' {
                country = [SELECT Country__c FROM Account WHERE Id = :recordId LIMIT 1].Country__c;
            }
            when 'Contract__c' {
                country = [SELECT Country__c FROM Contract__c WHERE Id = :recordId LIMIT 1].Country__c;
                relatedSObjectLimitation = ' AND Related_Object__c = \'' + sObjectName + '\'' ;
            }
            when 'Opportunity' {
                country = [SELECT Country__c FROM Opportunity WHERE Id = :recordId LIMIT 1].Country__c;
                relatedSObjectLimitation = ' AND Related_Object__c = \'' + sObjectName + '\'' ;
            }
        }
        String countryLimitation = '';
        if (SUPPORTED_COUNTRIES.contains(country)) {
            countryLimitation = 'AND ' + country + '__c = TRUE ';
        }
        String queryString = 'SELECT Name,' +
                'France__c,' +
                'Germany__c,' +
                'India__c, ' +
                'Related_Object__c,' +
                'Time_dependent_document__c,' +
                'msPicklist_Value_API_Name__c ' +
                'FROM Attachmenttypes__c ' +
                'WHERE msIsSendNotifications__c = FALSE ' +
                countryLimitation +
                relatedSObjectLimitation +
                'AND msIsShowInPortal__c = FALSE ORDER BY Name ASC';
        return Database.query(queryString);
    }
    @AuraEnabled
    public static Opportunity getOpp(Id recordId) {
        Opportunity opp = (Opportunity)(Security.stripInaccessible(AccessType.READABLE,[
                SELECT StageName
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
        ])).getRecords()[0];
        return opp;
    }

    @AuraEnabled
    public static List <Contract__c> getContracts(String recordId) {
        List<Contract__c> relatedContracts = [SELECT Name, Alternative_Contract_Name__c FROM Contract__c WHERE Contract_Holder__c = :recordId];
        //for (Contract__c tmp : relatedContracts) {
        //  tmp.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(tmp.Name, '/');
        //}
        return relatedContracts;
    }

    @AuraEnabled
    public static List<fileWrapper> handleInitialUpload(List<Id> contentDocumentIdList, String attachmentType, Date validFrom, Date validTo, List<Id> contractIdsToConnect, String oppStage) {
        List<fileWrapper> fileWrapperList = setSavedByComponentFlag(contentDocumentIdList);
        for (fileWrapper fileWrapperItem : fileWrapperList) {
            fileWrapperItem.attachmentType = attachmentType;
            fileWrapperItem.validFrom = validFrom;
            fileWrapperItem.validTo = validTo;
            fileWrapperItem.relatedContractIds = contractIdsToConnect;
            fileWrapperItem.oppStage = oppStage;
        }
        return fileWrapperList;
    }

    @AuraEnabled
    public static Boolean updateAndConnect(Id recordId, List<fileWrapper> fileWrapperList) {
        Boolean thereWereFilesToSave = false;
        Set<Id> contentDocumentIds = new Set<Id>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (fileWrapper fileWrapperItem : fileWrapperList) {
            if (!fileWrapperItem.hiddenDelete) {
                contentDocumentIds.add(fileWrapperItem.contentDocumentId);
            }
        }
        if (!contentDocumentIds.isEmpty()) {
            Map<Id, ContentVersion> conVerMap = new Map<Id, ContentVersion>(
            [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE]);

            for (fileWrapper fileWrapperItem : fileWrapperList) {
                if (!fileWrapperItem.hiddenDelete && conVerMap.containsKey(fileWrapperItem.id)) {
                    ContentVersion fileItem = conVerMap.get(fileWrapperItem.id);
                    fileItem = fileWrapperItem.translateIntoContentVersion(fileItem);
                    for (Id contractToConnectToId : fileWrapperItem.relatedContractIds) {
                        cdlList.add(new ContentDocumentLink(
                                ContentDocumentId = fileWrapperItem.contentDocumentId,
                                LinkedEntityId = contractToConnectToId,
                                ShareType = 'I',
                                Visibility = 'InternalUsers'
                        ));
                    }
                    cdlList.add(new ContentDocumentLink(
                            ContentDocumentId = fileWrapperItem.contentDocumentId,
                            LinkedEntityId = recordId,
                            ShareType = 'I',
                            Visibility = 'InternalUsers'
                    ));
                }
            }
            update conVerMap.values();
            insert cdlList;
            thereWereFilesToSave = true;
        }
        return thereWereFilesToSave;
    }

    private static List<fileWrapper> setSavedByComponentFlag(List<Id> contentDocumentIdList) {
        List<ContentVersion> uploadedFiles = [
                SELECT Title, Validity_start_date__c, Validity_end_date__c, Attachement_Type__c, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIdList
                AND IsLatest = TRUE
        ];
        List<fileWrapper> fileWrapperList = new List<fileWrapper>();
        for (ContentVersion fileItem : uploadedFiles) {
            fileItem.msUploadedByDocumentManagerCmp__c = true;
            fileWrapperList.add(new fileWrapper(fileItem));
        }
        update uploadedFiles;
        return fileWrapperList;
    }

    public class fileWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id contentDocumentId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String attachmentType { get; set; }
        @AuraEnabled public Date validFrom { get; set; }
        @AuraEnabled public Date validTo { get; set; }
        @AuraEnabled public List<Id> relatedContractIds { get; set; }
        @AuraEnabled public Boolean isChecked { get; set; }
        @AuraEnabled public Boolean isContractSelectorOpen { get; set; }
        @AuraEnabled public Boolean hiddenDelete { get; set; }
        @AuraEnabled public String oppStage { get; set; }

        public fileWrapper() {
            relatedContractIds = new List<Id>();
            isChecked = false;
            isContractSelectorOpen = false;
            hiddenDelete = false;
        }
        public fileWrapper(ContentVersion conVersion) {
            relatedContractIds = new List<Id>();
            isChecked = false;
            isContractSelectorOpen = false;
            hiddenDelete = false;
            id = conVersion.Id;
            contentDocumentId = conVersion.ContentDocumentId;
            title = conVersion.Title;
            attachmentType = conVersion.Attachement_Type__c;
            validFrom = conVersion.Validity_start_date__c;
            validTo = conVersion.Validity_end_date__c;
        }
        public ContentVersion translateIntoContentVersion(ContentVersion conVersion) {
            conVersion.Attachement_Type__c = attachmentType;
            conVersion.Validity_start_date__c = validFrom;
            conVersion.Validity_end_date__c = validTo;
            conVersion.Stage__c = oppStage;
            return conVersion;
        }
    }
}