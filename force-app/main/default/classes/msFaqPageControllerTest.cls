@IsTest
public with sharing class msFaqPageControllerTest {

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
        List<FAQ_Item__c> faqItems = new List<FAQ_Item__c>();
        faqItems.add(new FAQ_Item__c(
                msQuestion__c = '',
                msAnswer__c ='',
                msTopic__c = 'Portal & Processes',
                Language__c= 'de',
                msMarkets__c='Germany',
                msPublic__c = true,
                msPublished__c = true
        ));
        faqItems.add(new FAQ_Item__c(
                msQuestion__c = '',
                msAnswer__c ='',
                msTopic__c = 'Portal & Processes',
                Language__c= 'fr',
                msMarkets__c='France',
                msPublic__c = true,
                msPublished__c = true
        ));
        faqItems.add(new FAQ_Item__c(
                msQuestion__c = '',
                msAnswer__c ='',
                msTopic__c = 'Portal & Processes',
                Language__c= 'en_US',
                msMarkets__c='UK',
                msPublic__c = true,
                msPublished__c = true
        ));
        insert faqItems;
    }

    static testMethod void testGetFaqTopicsWrapper() {

        User testUser = [SELECT Id, Name, ContactId, LanguageLocaleKey FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        System.Test.startTest();
        System.runAs(testUser) {
            msFaqPageController.FaqTopicsWrapper faqItemsWrapper = msFaqPageController.getFaqTopicsWrapper(testUser.LanguageLocaleKey);
            System.Test.stopTest();
        }
    }

    static testMethod void testGetFaqTopicsWrapperForGuest() {

        User testUser = [SELECT Id, Name, ContactId, LanguageLocaleKey FROM User WHERE Name = 'Customer Portal Site Guest User'];
        System.Test.startTest();
        System.runAs(testUser) {
            msFaqPageController.FaqTopicsWrapper faqItemsWrapper = msFaqPageController.getFaqTopicsWrapper('de');
            System.assert(faqItemsWrapper != null, 'Wrapper should have been returned');
            System.assert(faqItemsWrapper.items.get('Portal & Processes') != null, 'Wrapper should contain a list');
            System.assert(faqItemsWrapper.items.get('Portal & Processes').size() > 0, 'This list should not be empty');
            faqItemsWrapper = msFaqPageController.getFaqTopicsWrapper('fr');
            System.assert(faqItemsWrapper.items.get('Portal & Processes').size() > 0, 'This list should not be empty');
            faqItemsWrapper = msFaqPageController.getFaqTopicsWrapper('en_US');
            System.assert(faqItemsWrapper.items.get('Portal & Processes').size() > 0, 'This list should not be empty');
            System.Test.stopTest();
        }
    }

    static testMethod void testGetFaqTopicsWrapperLanguages() {
        // Create a language list
        List<String> languageList = new List<String>();

        // Add languages to the list
        languageList.add('en_GB');
        languageList.add('en_US');
        languageList.add('pl');
        languageList.add('de');
        languageList.add('fr');
        languageList.add('*%&/$&/(');
        languageList.add('');

        User testUser = [SELECT Id, Name, ContactId, LanguageLocaleKey FROM User WHERE Name = 'Customer Portal Site Guest User'];
        System.Test.startTest();
        System.runAs(testUser) {
            for(String languageKeyItem : languageList) {
                msFaqPageController.FaqTopicsWrapper faqItemsWrapperEN = msFaqPageController.getFaqTopicsWrapper(languageKeyItem);
            }

        }
        System.Test.stopTest();
    }

}