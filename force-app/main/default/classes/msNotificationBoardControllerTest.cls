/****************************************************************************************************
* Class msNotificationBoardControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   20.02.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   20.02.2020      	    Init version.
*****************************************************************************************************/

@IsTest
public with sharing class msNotificationBoardControllerTest {
    static testMethod void testGetMessages() {
        Id networkId = [SELECT Id FROM Network WHERE Name = 'Customer Portal' LIMIT 1].Id;
        ConnectApi.FeedElementPage page = new ConnectApi.FeedElementPage();
        ConnectApi.GenericFeedElement element = new ConnectApi.GenericFeedElement();
        element.createdDate = Datetime.newInstance(2020, 12, 31);
        element.body = new ConnectApi.FeedBody();
        element.capabilities = new ConnectApi.FeedElementCapabilities();
        element.capabilities.readby = new ConnectApi.ReadByCapability();
        page.elements = new List<ConnectApi.FeedElement>();
        page.elements.add(element);

        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFilterFeed(networkId, 'me', '005', null, 100, null, page);

        System.Test.startTest();
        msNotificationBoardController.getMessages();
        System.Test.stopTest();
    }

    static testMethod void testGetUnreadMessages() {
        Id networkId = [SELECT Id FROM Network WHERE Name = 'Customer Portal' LIMIT 1].Id;
        ConnectApi.FeedElementPage page = new ConnectApi.FeedElementPage();
        ConnectApi.GenericFeedElement element = new ConnectApi.GenericFeedElement();
        element.createdDate = Datetime.newInstance(2020, 12, 31);
        element.body = new ConnectApi.FeedBody();
        element.capabilities = new ConnectApi.FeedElementCapabilities();
        element.capabilities.readby = new ConnectApi.ReadByCapability();
        page.elements = new List<ConnectApi.FeedElement>();
        page.elements.add(element);

        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFilterFeed(networkId, 'me', '005', null, 100, null, page);

        System.Test.startTest();
        msNotificationBoardController.getUnreadMessages();
        System.Test.stopTest();
    }

    static testMethod void testMarkAsRead() {
        msTestDataFactory.createTestPortalContext();

        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal' LIMIT 1];
        List<String> messageIds = new List<String>{
                '1234', '4567'
        };

        System.Test.startTest();
        System.runAs(testUser) {
            msNotificationBoardController.markAsRead(messageIds);
            System.Test.stopTest();
        }
    }
}