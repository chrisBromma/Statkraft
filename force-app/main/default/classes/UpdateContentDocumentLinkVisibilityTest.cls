@isTest
public without sharing class UpdateContentDocumentLinkVisibilityTest {

        @testSetup static void setup() {
            msTestDataFactory.createTestPortalContext();
        }

        @isTest
    	static void myUnitTest() {

        Contract__c attachedcontract = [SELECT Id FROM Contract__c WHERE RED_Contract_ID__c = 'UKTestContract1'];
        //[Select id from Contract__c where id = 'a0K0Y000005aJbjUAE'];
         string before = 'Testing base 64 encode';            
         Blob beforeblob = Blob.valueOf(before);
        
          
           
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';   
		//cv.Document_Category__c = 'Rechnung';        
        cv.VersionData =beforeblob;          
        insert cv;         

        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=attachedcontract.id;
        contentlink.ShareType= 'V';
        contentlink.LinkedEntityId = attachedcontract.Id; 
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        insert contentlink;
        
        contentlink = [Select Visibility from ContentDocumentLink where Id = : contentlink.Id];
        System.assertEquals('AllUsers', contentlink.Visibility);
        
    }
        
    
}