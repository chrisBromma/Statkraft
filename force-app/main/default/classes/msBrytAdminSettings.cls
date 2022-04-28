/**
 * Created by georgluch on 26.11.21.
 */

public without sharing class msBrytAdminSettings {

    @AuraEnabled
    public static List<Bryt_Portal_Bulletin_TradeDeactivation__c> getRecordsAboutDisabledTrades() {
        List<Bryt_Portal_Bulletin_TradeDeactivation__c> bulletins = new List<Bryt_Portal_Bulletin_TradeDeactivation__c>();
        if (msBrytUtility.getUserDetails().isAdmin) {
            bulletins = [
                    SELECT Id, Name, Text__c, Publication_Date__c, Color__c, End_Date__c, is_Active__c
                    FROM Bryt_Portal_Bulletin_TradeDeactivation__c
                    ORDER BY CreatedDate DESC
            ];
        }
        return bulletins;
    }

    @AuraEnabled
    public static String getColorPicklistValues() {
        Schema.DescribeFieldResult fieldResult = Bryt_Portal_Bulletin_TradeDeactivation__c.Color__c.getDescribe();
        return JSON.serialize(fieldResult.getPicklistValues());
    }

    @AuraEnabled
    public static void removeMessage(String messageId) {
        Bryt_Portal_Bulletin_TradeDeactivation__c message = [SELECT Id, Name FROM Bryt_Portal_Bulletin_TradeDeactivation__c WHERE Id = :messageId];

        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin ) {
            try {
                delete message;
            } catch (Exception e) {
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }
    }
}