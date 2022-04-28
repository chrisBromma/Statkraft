@IsTest
private class DocumentViewerControllerTEST {
    static testMethod void validateDocumentViewerController() {
        //DocumentViewerController TestController = new DocumentViewerController();
        
        Contract__c testContract = new Contract__c();
        
        Attachmenttypes__c newCustomSetting = new Attachmenttypes__c();
        newCustomSetting.Name='Other';
        newCustomSetting.msPicklist_Value_API_Name__c = 'Other';
        newCustomSetting.Germany__c = true;
        newCustomSetting.France__c = true;
        newCustomSetting.Comercial_Document__c = true;
        newCustomSetting.Related_Object__c = 'Contract__c';
        newCustomSetting.msIsShowInPortal__c = false;
        newCustomSetting.msIsSendNotifications__c = false;
        insert newCustomSetting;

        testContract.RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByName().get('Contract PPA').getRecordTypeId();
        testContract.Name ='Test Contract PPA 7593';
        //testContract.Contract_Holder__c = '';
        testContract.Status__c = 'Draft';
        testContract.Contract_Type__c = null;
        testContract.Start_Date__c = Date.today();
        testContract.End_Date__c = Date.today();
        testContract.Country__c = 'Germany';
        
        insert testContract;
        
        Blob file = Blob.valueOf('abc');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'testing upload';
        v.PathOnClient ='/somepath.txt';
        v.Attachement_Type__c = 'Other';
        insert v;
        v = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = v.ContentDocumentId;
        testLink.LinkedEntityId = testContract.Id;
        testLink.ShareType = 'I';
        insert testLink;
        Test.startTest();
		PageReference pageRef  = Page.DocumentViewer;
        pageRef.getParameters().put('id', testContract.Id);
        Test.setCurrentPage(pageRef);
        DocumentViewerController dvc = new DocumentViewerController();
        dvc.getAttachmentTypes();
        dvc.delConnectToId = dvc.FileList[0].ContentDocumentId;
        dvc.deleteRecord();
		Test.stopTest();
    }
}