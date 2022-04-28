public with sharing class msBrytAdminBulletins {

    @AuraEnabled
    public static List<Bryt_Portal_Bulletin__c> getBulletins() {
        List<Bryt_Portal_Bulletin__c> bulletins = new List<Bryt_Portal_Bulletin__c>();
        if(msBrytUtility.getUserDetails().isAdmin){
            bulletins = [
                    SELECT Id,Name,Text__c,Publication_Date__c,Color__c,isSticky__c,End_Date__c,is_Active__c
                    FROM Bryt_Portal_Bulletin__c
                    ORDER BY CreatedDate DESC
            ];
        }
        return bulletins;
    }

    @AuraEnabled
    public static String getColorPicklistValues() {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Bryt_Portal_Bulletin__c.Color__c.getDescribe();
        return JSON.serialize(fieldResult.getPicklistValues());
    }
}