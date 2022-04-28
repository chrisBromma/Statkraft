/****************************************************************************************************
* Class msKAMCalendarControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   28.10.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   28.10.2020      	    Init version.
*****************************************************************************************************/

@isTest
public without sharing class msKAMCalendarControllerTest {

    @isTest
    public static void testGetEvents() {
        Event newEvent = new Event();
        newEvent.Subject = 'My Test';
        newEvent.StartDateTime = Datetime.now().addHours(-5);
        newEvent.EndDateTime = Datetime.now().addHours(5);
        newEvent.OwnerId = UserInfo.getUserId();

        insert newEvent;

        System.Test.startTest();
        List<msKAMCalendarController.EventObj> events = msKAMCalendarController.getEvents(UserInfo.getUserId());

        System.assert(events.size() == 1);
        System.assert(events[0].title == 'My Test');
        System.Test.stopTest();
    }
}