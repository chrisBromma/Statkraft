@isTest
public class relink_contentdocumentTEST {

    @TestSetup static void setup(){
        msTestDataFactory.createTestPortalContext();
    }
    @isTest static void testrelink_contentdocument() {
        // IS : Contract -> Task -> ContentDocument
        // To be: Contract -> ContentDocument

        Contract__c ContractId = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'GermanTestContract1' ];
        
        Blob body = Blob.valueOf('Test');

        ContentVersion getContentDocument = new ContentVersion();
        getContentDocument.Title = 'Test Content Version';
        getContentDocument.PathOnClient = 'SampleTitle.jpg';
        getContentDocument.VersionData = body;
        getContentDocument.origin = 'H';

        insert getContentDocument;

        ContentVersion getContentDocumentId = [SELECT ContentDocumentId, Id FROM ContentVersion WHERE Id = :getContentDocument.Id];
        System.assert(getContentDocumentId != null);
    
        Task new_task = new task();
        new_task.Subject = 'TEST';
        new_task.WhatId = ContractId.Id;
        insert new_task;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = new_task.Id;
        cdl.ContentDocumentId = getContentDocumentId.ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        
    }
}