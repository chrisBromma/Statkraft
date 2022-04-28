/**
 * Created by Steffen Naundorf on 02.12.2021.
 */

public without sharing class sapServerCallout implements Queueable {
    private static String token;
    public static fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();
    Case transferCase;

    public sapServerCallout(Case caseInput) {
        transferCase = caseInput;
    }

    public void execute(QueueableContext context) {
        token = getApiToken();

        Id caseId = '5001w000009AWwpAAG';
        transferCase = [SELECT Id, Attachment_Notes__c, AccountId, Contract__c, SAP_Transfer_Data__c FROM Case WHERE Id = :caseId];
        Account account = [SELECT Id, Name, BillingStreet, BillingCity, BillingCountry, BillingCountryCode, BillingPostalCode, VAT_Reseller__c, VAT_Number__c,company_tax_number__c, SAP_Customer__c, SAP_Reference__c FROM Account WHERE Id = :transferCase.AccountId];
        List<Contract__c> contracts = [SELECT Id, Name, Bank_Account_Owner__c, IBAN__c, Bank_Claim__c FROM Contract__c WHERE (Status__c = 'Active' OR Status__c = 'Expired') AND Contract_Holder__c = :account.Id];

        String body = prepareBody(account, contracts);

        callout(body);
    }

    private String prepareBody(Account account, List<Contract__c> contracts) {
        Map<String, Object> dataMap = new Map<String, Object>();
        sapTriggerHelper.TransferData transferData = new sapTriggerHelper.TransferData();
        Case caseToTransfer = transferCase.clone(true);

        if (caseToTransfer.SAP_Transfer_Data__c != null) {
            transferData = (sapTriggerHelper.TransferData) JSON.deserializeStrict(caseToTransfer.SAP_Transfer_Data__c, sapTriggerHelper.TransferData.Class);
            caseToTransfer.SAP_Transfer_Data__c = null;
        }

        //TODO Calculate SAP_Reference__c with the first Contract name, or use already given data

        Map<String, sapTriggerHelper.BankData>bankDuplicateMap = new Map<String, sapTriggerHelper.BankData>();
        for (Contract__c contract : contracts) {
            sapTriggerHelper.BankData bankData = new sapTriggerHelper.BankData(contract);
            bankDuplicateMap.put(sapTriggerHelper.getKey(bankData), bankData);
        }
        for (sapTriggerHelper.BankData bankData : transferData.bankData.values()) {
            bankDuplicateMap.put(sapTriggerHelper.getKey(bankData), bankData);
        }

        List<DocumentWrapper> documents = getSpecificDocuments(transferData, account);

        dataMap.put('Reference', caseToTransfer.Id);
        dataMap.put('Case', caseToTransfer);
        dataMap.put('Account', account);
        dataMap.put('BankData', bankDuplicateMap.values());
        dataMap.put('updateTax', transferData.updateTax);
        dataMap.put('updateVat', transferData.updateVat);
        dataMap.put('Documents', documents);
        dataMap.put('newBP', transferData.newBP);

        String body = JSON.serializePretty(dataMap);
        return body;
    }

    private List<DocumentWrapper> getSpecificDocuments(sapTriggerHelper.TransferData transferData, Account account) {
        Set<ContentVersion>relevantDocuments = new Set<ContentVersion>();
        List<SAP_Transfer_Attachment__mdt> cmdts = [SELECT Szenario__c, Attachment_Type__c, Related_Object__c FROM SAP_Transfer_Attachment__mdt];

        Set<String> accountAttachmentTypes = new Set<String>();
        Map<Id, Set<String>>contractToAttachementType = new Map<Id, Set<String>>();

        Map<Id, List<Id>>contentDocumentIdToContracts = new Map<Id, List<Id>>();
        List<Id>contentDocumentIds = new List<Id>();
        Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>();

        for (SAP_Transfer_Attachment__mdt cmdt : cmdts) {
            //set account attachment types
            if (transferData.scenarios.contains(cmdt.Szenario__c)) {
                accountAttachmentTypes.add(cmdt.Attachment_Type__c);
            }

            //set contract attachment types
            for (Id contractId : transferData.contractToScenarios.keySet()) {
                if (transferData.contractToScenarios.get(contractId).contains(cmdt.Szenario__c)) {
                    if (cmdt.Related_Object__c == 'Contract') {
                        Set<String>attachmentTypes = contractToAttachementType.get(contractId);
                        if (attachmentTypes == null)
                            attachmentTypes = new Set<String>();

                        attachmentTypes.add(cmdt.Attachment_Type__c);
                        contractToAttachementType.put(contractId, attachmentTypes);
                    } else if (cmdt.Related_Object__c == 'Account') {
                        accountAttachmentTypes.add(cmdt.Attachment_Type__c);
                    }
                }
            }
        }

        List<ContentDocumentLink> contentDocumentLinks = [
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.ContentSize
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :account.Id OR LinkedEntityId IN:transferData.contractToScenarios.keySet()
        ];
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            contentDocumentMap.put(cdl.ContentDocumentId, cdl.ContentDocument);
        }


        for (ContentDocumentLink cdl : contentDocumentLinks) {
            if (cdl.LinkedEntityId.getSobjectType() == Contract__c.SObjectType) {
                List<Id> contentDocumentIdsOfEntity = contentDocumentIdToContracts.get(cdl.ContentDocumentId);
                if (contentDocumentIdsOfEntity == null)
                    contentDocumentIdsOfEntity = new List<Id>();

                contentDocumentIds.add(cdl.ContentDocumentId);
                contentDocumentIdsOfEntity.add(cdl.LinkedEntityId);
                contentDocumentIdToContracts.put(cdl.ContentDocumentId, contentDocumentIdsOfEntity);
            } else {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
        }

        List<ContentVersion> contentVersions = [
                SELECT Id, Attachement_Type__c, Title, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN:contentDocumentIds
        ];
        for (ContentVersion cv : contentVersions) {
            List<Id> contractIds = contentDocumentIdToContracts.get(cv.ContentDocumentId);
            if (contractIds != null) {
                for (Id contractId : contractIds) {
                    Set<String> attachmentTypes = contractToAttachementType.get(contractId);
                    if (attachmentTypes != null && attachmentTypes.contains(cv.Attachement_Type__c)) {
                        relevantDocuments.add(cv);
                    }
                }
            }
            if (accountAttachmentTypes.contains(cv.Attachement_Type__c)) {
                relevantDocuments.add(cv);
            }
        }


        List<DocumentWrapper>documents = new List<DocumentWrapper>();
        for (ContentVersion cv : relevantDocuments) {
            ContentDocument contentDocument = contentDocumentMap.get(cv.ContentDocumentId);

            DocumentWrapper documentWrapper = new DocumentWrapper();
            documentWrapper.title = contentDocument.Title;
            documentWrapper.fileExtension = contentDocument.FileExtension;
            documentWrapper.attachmentType = cv.Attachement_Type__c;
            documentWrapper.url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v42.0/sobjects/ContentVersion/' + cv.Id + '/VersionData';

            documents.add(documentWrapper);
        }
        return documents;
    }

    private void callout(String body) {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        sapTriggerHelper sapTriggerHelper = new sapTriggerHelper(uow);
        List<String>messages = new List<String>();
        Case caseToUpdate = new Case(Id = transferCase.Id);

        Http http = new Http();
        String endpoint = ApiSettings.itmds_Endpoint__c;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('content-type', 'application/json');
        request.setHeader('accept', 'application/json');
        request.setHeader('Ocp-Apim-Subscription-Key', ApiSettings.itmds_Subscription_Key__c);
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setBody(body);
        request.setTimeout(60000);
        HttpResponse response = http.send(request);

        Logger.info('Callout Itmds', caseToUpdate.Id);
        Logger.info('Request: ' + request.toString(), caseToUpdate.Id);
        Logger.info('Response Code: ' + response.getStatusCode(), caseToUpdate.Id);
        Logger.info('Response Body: ' + response.getBody(), caseToUpdate.Id);

        if (response.getStatusCode() != 200) {
            Logger.error('Callout failed', caseToUpdate.Id);

            messages.add('Submission failed: SAP not available');
            caseToUpdate.Status = 'In Salesforce Approval';
            caseToUpdate.Progress__c = 'Submission failed';
        } else {
            Logger.info('Case transfered', caseToUpdate.Id);

            messages.add('Data Submitted to SAP');
            messages.add('Awaiting Request creation');
            caseToUpdate.Status = 'In SAP Approval';
            caseToUpdate.Progress__c = 'Submitted to SAP';
        }

        update caseToUpdate;
        if (!messages.isEmpty()) {
            sapTriggerHelper.addMessage(messages, caseToUpdate);
        }

        System.debug(body);
        System.debug(endpoint);
        System.debug(response.getStatus());
        System.debug(response.getBody());
        Logger.saveLog('SAP Transfer - Outgoing');
    }

    public String getApiToken() {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        HttpRequest request = new HttpRequest();
        Http http = new Http();

        String body = 'grant_type=client_credentials&client_id=' + ApiSettings.BlueSeaClientID__c +
                '&client_secret=' + EncodingUtil.urlEncode(ApiSettings.BlueSeaClientSecret__c, 'UTF-8');

        request.setEndpoint(ApiSettings.Statkraft_Token_Endpoint__c);
        request.setMethod('POST');
        request.setHeader('content-type', 'application/X-www-form-urlencoded');
        request.setBody(body);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            Logger.error('Get API Token');
            Logger.error('Request: ' + request.toString());
            Logger.error('Response Code: ' + response.getStatusCode());
            Logger.error('Response Body: ' + response.getBody());
        }

        Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (String) tokenMap.get('access_token');
    }

    @AuraEnabled
    public static Case getCaseDetails(String caseId) {
        return [Select Id, SAP_Transfer_Data__c FROM Case Where Id =:caseId];
    }
    public class ResponseWrapper {
        @AuraEnabled public String Result { get; set; }
        @AuraEnabled public String Message { get; set; }
    }
    public class DocumentWrapper {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String attachmentType { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public String url { get; set; }
    }
}