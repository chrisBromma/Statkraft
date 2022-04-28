/****************************************************************************************************
* Class msNotificationBoardController
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

public with sharing class msNotificationBoardController {
    @AuraEnabled
    public static List<MessageWrapper> getMessages() {
        List<MessageWrapper> messages = new List<MessageWrapper>();
        try {
            Datetime blockerDate = Datetime.newInstance(2019, 11, 30);
            Id networkId = [SELECT Id FROM Network WHERE Name = 'Customer Portal' LIMIT 1].Id;
            List<ConnectApi.FeedElement> chatterFeedUnfiltered = new List<ConnectApi.FeedElement>();
            chatterFeedUnfiltered = ConnectApi.ChatterFeeds.getFeedElementsFromFilterFeed(networkId, 'me', '005', null, 100, null).elements;
            if (chatterFeedUnfiltered != null) {
                for (ConnectApi.FeedElement feedItem : chatterFeedUnfiltered) {
                    if (feedItem.createdDate > blockerDate) {
                        MessageWrapper message = new MessageWrapper();
                        message.createdDate = feedItem.createdDate;
                        message.id = feedItem.id;
                        message.message = feedItem.body.text;
                        message.isReadByMe = feedItem.capabilities.readBy.isReadByMe;
                        messages.add(message);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        return messages;
    }


    @AuraEnabled
    public static Integer getUnreadMessages() {
        List<MessageWrapper> messages = getMessages();
        Integer unreadMessages = 0;

        for (MessageWrapper tempWrapper : messages) {
            if (tempWrapper.isReadByMe == false) {
                unreadMessages++;
            }
        }
        return unreadMessages;
    }

    @AuraEnabled
    public static void markAsRead(List<String> messageIds) {
        for (Integer i = 0; i < messageIds.size(); i++) {
            try {
                ConnectApi.ChatterFeeds.setIsReadByMe(Network.getNetworkId(), messageIds[i], true);
            } catch (Exception e) {
            }
        }
    }

    public class MessageWrapper {
        @AuraEnabled public Datetime createdDate { get; set; }
        @AuraEnabled public Id id { get; set; }
        //message is actually an Object is String form, after parsing in Front End, we use message.subject and message.body
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Boolean isReadByMe { get; set; }
    }
}