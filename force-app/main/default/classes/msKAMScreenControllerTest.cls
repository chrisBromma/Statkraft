@isTest
public with sharing class msKAMScreenControllerTest {
    @isTest
    public static void testChangeDocumentOwners() {
        User owner2 = [SELECT Id FROM User WHERE ContactID =null AND IsActive=True ORDER BY Id DESC LIMIT 1];

        Account testAcc = new Account();
            testAcc.name = 'testAcc';
        insert testAcc;

        ContentVersion cv = new ContentVersion();
			cv.title='Test title';
			cv.VersionData=blob.valueof('New Bitmap Image.bmp');
			cv.PathOnClient ='/abc.txt';
			Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            cv.VersionData=bodyBlob; 	
        insert cv;

        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = testAcc.Id;
            cdl.contentDocumentId = contentVersionSelect.contentDocumentId;
        insert cdl;

        List<msKAMScreenController.KAM> kamList = new List<msKAMScreenController.KAM>();
        msKAMScreenController.KAM testKeyAccount = new msKAMScreenController.KAM();
            testKeyAccount.accountId = testAcc.Id;
            testKeyAccount.ownerId = owner2.Id;
        kamList.add(testKeyAccount);

        msKAMScreenController.changeDocumentOwners(kamList);

        ContentVersion newOwner = [SELECT OwnerId FROM ContentVersion WHERE Id = :cv.Id];
        
        System.assert(newOwner.OwnerId == owner2.Id);
    }
}