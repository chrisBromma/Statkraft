/****************************************************************************************************
* Class msNewsFeedController
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Controller for the msNewsFeed Component
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            02.10.2018          Init version.
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019          Version 1 for Prod
*****************************************************************************************************/
public class msNewsFeedController {
    /**
    * @description - This method initializes the Newsfeed with News that are related to the current user
    * based on what markets they have access to and their language.
    */
    @AuraEnabled
    public static List<PortalNews__c> getNews(String newsLimit) {
        Integer feedsLimit = Integer.valueOf(newsLimit);
        String language = '';
        Boolean languageExists = false;
        List<String> pickListValues = new List<String>();
        String userLanguage = UserInfo.getLanguage();

        //get picklist values
        Schema.DescribeFieldResult fieldResult = PortalNews__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValues.add(pickListVal.getValue());
        }
        // check if user language still exist in the pciklist, else set en_US as default
        for (String value : pickListValues) {
            if (value == userLanguage) {
                language = value;
                languageExists = true;
            }
        }
        if (!languageExists) {
            language = 'en_US';
        }

        Set<String> markets = msUtility.getUserMarkets();
        if (!markets.isEmpty()) {
            Set<PortalNews__c> newsSet = new Set<PortalNews__c>();
            List<PortalNews__c> news = (List<PortalNews__c>) [
                    SELECT Publication_Date__c, Title__c, Text__c, msMarkets__c, Language__c, Link__c
                    FROM PortalNews__c
                    WHERE Type__c != 'Maintenance Information'
                    AND Language__c = :UserInfo.getLanguage()
                    AND Publication_Date__c <= :Date.today()
                    AND (End__c >= :Date.today() OR End__c = NULL)
                    ORDER BY CreatedDate DESC
                    LIMIT :feedsLimit
            ];

            for (PortalNews__c newsItem : news) {
                List<String> itemMarkets = newsItem.msMarkets__c.split(';');
                for (String market : itemMarkets) {
                    if (markets.contains(market)) {
                        newsSet.add(newsItem);
                    }
                }
            }
            List<PortalNews__c> results = new List<PortalNews__c>();
            results.addAll(newsSet);

            return results;
        } else {
            return null;
        }
    }
}