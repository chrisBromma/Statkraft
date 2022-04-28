/****************************************************************************************************
* Class msKAMCalendarController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   20.10.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   20.10.2020      	    Init version.
*****************************************************************************************************/

public without sharing class msKAMCalendarController {

    @AuraEnabled
    public static List<EventObj> getEvents(String calendarId) {
        List<Event>events = [SELECT Id,Subject,StartDateTime,EndDateTime,Description,OwnerId FROM Event WHERE OwnerId = :calendarId];

        List<EventObj> eventRecords = new List<EventObj>();
        for (Event obj : events) {
            EventObj newEv = new EventObj(obj.Id,
                    String.valueOf(obj.Subject),
                    DateTime.valueOf(obj.StartDateTime),
                    DateTime.valueOf(obj.EndDateTime),
                    String.valueOf(obj.Description),
                    String.valueOf(obj.OwnerId)
            );
            eventRecords.add(newEv);
        }

        return eventRecords;
    }

    public class EventObj {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public DateTime startDateTime { get; set; }
        @AuraEnabled public DateTime endDateTime { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String owner { get; set; }


        public EventObj(String i, String t, DateTime s, DateTime e, String d, String o) {
            this.Id = i;
            this.title = t;
            this.startDateTime = s;
            this.endDateTime = e;
            this.description = d;
            this.owner = o;
        }

    }
}