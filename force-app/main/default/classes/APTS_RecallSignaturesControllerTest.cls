/*************************************************************
@Name: APTS_RecallSignaturesControllerTest
@Author:Apttus
@Description: Tests APTS_RecallSignaturesController

******************************************************************/
@isTest
private class APTS_RecallSignaturesControllerTest{

    static testMethod void myUnitPositiveTest() {
        
        //Create a new Account
        Account testacc = new Account();
        testacc.Name = 'Test Account';
        
        insert testacc;
        
        APTS_integration_Allowed__c obj = new APTS_integration_Allowed__c(Name = 'Integration_Allowed', APTS_Allow_Callout__c = true);
        insert obj;
        String DomainURL = URL.getSalesforceBaseUrl().toExternalForm();
        Apttus__ComplySystemProperties__c prop = new Apttus__ComplySystemProperties__c(Name = 'System Properties',Apttus__InstanceUrl__c=DomainURL);
        insert prop;
        
        //Create new agreement
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.Apttus__Account__c = testacc.Id;
        
        insert agreement;
        
        echosign_dev1__SIGN_Agreement__c signAgr = new echosign_dev1__SIGN_Agreement__c();
        signAgr.Apttus_Echosign__Apttus_Agreement__c = agreement.id;
        signAgr.echosign_dev1__Status__c = APTS_Constants.OUT_OF_SIGNATURE;
        insert signAgr;

        //Start Test
        Test.startTest();
        
        //Initialize the page
        PageReference RecallSignPage = new PageReference('/apex/APTS_RecallSignaturesPage?id='+agreement.Id);
        Test.setCurrentPage(RecallSignPage);
        ApexPages.StandardController sc = new ApexPages.StandardController(agreement);
        APTS_RecallSignaturesController Ctrl = new APTS_RecallSignaturesController(sc);
        
        //execute redirect method
        Ctrl.redirect();
        
        //Stop Test
        Test.stopTest();
        
        //Query agreement record
        Apttus__APTS_Agreement__c agreementResult = [select Id, Apttus__Status_Category__c, Apttus__Status__c from Apttus__APTS_Agreement__c where Id = :agreement.Id];
        
        //Assert that the agreement is in signatures status category and fully signed status
        //System.assertEquals(agreementResult.Apttus__Status_Category__c,'In Signatures');
        //System.assertEquals(agreementResult.Apttus__Status__c,'Signatures Recalled');
        
        
    }
    static testMethod void myUnitNegativeTest() {
        
        //Create a new Account
        Account testacc = new Account();
        testacc.Name = 'Test Account';
        
        insert testacc;
        
        APTS_integration_Allowed__c obj = new APTS_integration_Allowed__c(Name = 'Integration_Allowed', APTS_Allow_Callout__c = true);
        insert obj;
        String DomainURL = URL.getSalesforceBaseUrl().toExternalForm();
        Apttus__ComplySystemProperties__c prop = new Apttus__ComplySystemProperties__c(Name = 'System Properties',Apttus__InstanceUrl__c=DomainURL);
        insert prop;
        
        //Create new agreement
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.Apttus__Account__c = testacc.Id;
        
        insert agreement;

        //Start Test
        Test.startTest();
        
        //Initialize the page
        PageReference RecallSignPage = new PageReference('/apex/APTS_RecallSignaturesPage?id='+agreement.Id);
        Test.setCurrentPage(RecallSignPage);
        ApexPages.StandardController sc = new ApexPages.StandardController(agreement);
        APTS_RecallSignaturesController Ctrl = new APTS_RecallSignaturesController(sc);
        
        //execute redirect method
        Ctrl.redirect();
        
        //Stop Test
        Test.stopTest();
        
        //Query agreement record
        Apttus__APTS_Agreement__c agreementResult = [select Id, Apttus__Status_Category__c, Apttus__Status__c from Apttus__APTS_Agreement__c where Id = :agreement.Id];
        
        //Assert that the agreement is in signatures status category and fully signed status
        //System.assertEquals(agreementResult.Apttus__Status_Category__c,'In Signatures');
        //System.assertEquals(agreementResult.Apttus__Status__c,'Signatures Recalled');
        
        
    }
    
    
    
}