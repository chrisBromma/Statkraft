/****************************************************************************************************
* Class msNewsFeedController
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Testclass for the Class msNewsFeedController
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            02.10.2018          Init version.
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019          Version 1 for Prod
*****************************************************************************************************/
@IsTest
public with sharing class msNewsFeedControllerTest {

    static testMethod void testGetNews() {

        msTestDataFactory.createTestPortalContext();
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username='FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];


        List<PortalNews__c> allNews = new List<PortalNews__c>();
        for(Integer i=0;i<5;i++){
            PortalNews__c tempNews=new PortalNews__c();
            tempNews.msMarkets__c = 'France';
            tempNews.Language__c='fr';
            tempNews.Text__c='Test';
            tempNews.Title__c='Test';
            tempNews.Publication_Date__c=Date.today().addMonths(-1);
            tempNews.Type__c='News';
            allNews.add(tempNews);
        }
        for(Integer i=0;i<5;i++){
            PortalNews__c tempNews=new PortalNews__c();
            tempNews.msMarkets__c = 'Germany';
            tempNews.Language__c='de';
            tempNews.Text__c='Test';
            tempNews.Title__c='Test';
            tempNews.Publication_Date__c=Date.today().addMonths(-1);
            tempNews.Type__c='News';
            allNews.add(tempNews);
        }
        insert allNews;

        System.Test.startTest();
        System.runAs(testUser) {
            List<PortalNews__c> newsList = msNewsFeedController.getNews('2');
            System.debug(newsList);
            System.assert(newsList.size() > 0, 'None news was added to the list.');
            System.assert(newsList.size() <= 2, 'To much news was added to the list.');

            System.Test.stopTest();
        }
    }
}