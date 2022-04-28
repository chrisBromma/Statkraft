public without sharing class msFaqPageController {
    private static final String DEFAULT_FAQ_ITEM_LANGUAGE = 'en_US';
    private static final Set<String> ACCEPTABLE_TOPICS = new Set<String>{'Energy know-how','Portal & Processes'};

    @AuraEnabled
    public static FaqTopicsWrapper getFaqTopicsWrapper(String FaqLanguage) {

        // Check passed language. Only 3 languages supported right now: en_US, fr, de
        switch on FaqLanguage {
            when 'en_GB' {
                FaqLanguage = 'en_US'; // Why? Because Language__c in FAQ_Item__c contains en_US and not en_GB
            }
            when 'de' {
                FaqLanguage = 'de';
            }
            when 'fr' {
                FaqLanguage = 'fr';
            }
            when else { // Default/fallback language, if posted something different.
                FaqLanguage = 'en_US';
            }
        }

        FaqTopicsWrapper result = new FaqTopicsWrapper();
        result.items = getFaqItemsByTopic(FaqLanguage);
        result.topics = new List<String>(result.items.keySet());
        result.topics.sort();
        return result;
    }

    private static Map<String, List<FaqItemsWrapper>> getFaqItemsByTopic(String FaqLanguage) {


        // Check whether User is logged-on or not.
        // user.ContactId != NULL means, that users is logged-on
        User user = [SELECT Name, Profile.Name, ContactId, LanguageLocaleKey, MobilePhone, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Set<FAQ_Item__c> filteredItems = new Set<FAQ_Item__c>();
        List<FAQ_Item__c> faq_items = new List<FAQ_Item__c>();
        // List<String> pickListValues = new List<String>(); // ? Never used?

        // FAQ-items for guest users:
        if(user.Name == 'Customer Portal Site Guest User' || user.ContactId == null) {
            // FAQ items visible for guests, marked 'public' via checkbox. (Shows only public FAQ-items)
            faq_items = [
                    SELECT Id, Name, msQuestion__c, msAnswer__c, toLabel(msTopic__c), Language__c, msMarkets__c
                    FROM FAQ_Item__c
                    WHERE msTopic__c IN :ACCEPTABLE_TOPICS
                    AND Language__c = :FaqLanguage
                    AND msPublished__c = TRUE
                    AND msPublic__c = TRUE
            ];

            // Fill FAQ items for the guest-user
            for (FAQ_Item__c faq_item : faq_items) {
                filteredItems.add(faq_item);
            }
        }
        // FAQ items for logged-on users
        else {
            String language = validateUserLanguage();
            Set<String> markets = msUtility.getUserMarkets();

            if (!markets.isEmpty()) {

                // Check if User is logged in
                if (user.ContactId != null) { // All FAQ items visible. (Shows public and non-public FAQ-items)
                    faq_items = [
                            SELECT Id, Name, msQuestion__c, msAnswer__c, toLabel(msTopic__c), Language__c, msMarkets__c
                            FROM FAQ_Item__c
                            WHERE msTopic__c IN :ACCEPTABLE_TOPICS
                            AND Language__c = :language
                            AND msPublished__c = TRUE
                    ];

                    // Fill FAQ items for logged-on users
                    for (FAQ_Item__c faq_item : faq_items) {
                        if (faq_item.msMarkets__c != null) {
                            List<String> itemMarkets = faq_item.msMarkets__c.split(';'); // e.g. France;Germany;UKFlex;UK;Belgium
                            for (String market : itemMarkets) {
                                if (markets.contains(market)) {
                                    filteredItems.add(faq_item);
                                }
                            }
                        }
                    }
                }
            }
            else{
                return null;
            }
        }

        List<FAQ_Item__c> items = new List<FAQ_Item__c>(filteredItems);

        Map<String, List<FaqItemsWrapper>> results = new Map<String, List<FaqItemsWrapper>>();
        if (!items.isEmpty()) {
            for (FAQ_Item__c faq_item : items) {
                if (!results.containsKey(faq_item.msTopic__c)) {
                    results.put(faq_item.msTopic__c, new List<FaqItemsWrapper>());
                }
                FaqItemsWrapper itemWrapper = new FaqItemsWrapper();
                itemWrapper.faqItem = faq_item;
                itemWrapper.question = faq_item.msQuestion__c;
                itemWrapper.answer = faq_item.msAnswer__c;
                results.get(faq_item.msTopic__c).add(itemWrapper);
            }
        }
        return results;

    }

    private static String validateUserLanguage() {
        String resultLanguage = DEFAULT_FAQ_ITEM_LANGUAGE;
        List<String> languagePicklistValues = getLanguagePicklistValues();
        String userLanguage = UserInfo.getLanguage();
        if (isUserLanguageExistInPicklistValues(languagePicklistValues, userLanguage)) {
            resultLanguage = userLanguage;
        }
        return resultLanguage;
    }

    private static List<String> getLanguagePicklistValues() {
        List<String> results = new List<String>();
        for (Schema.PicklistEntry picklistEntry : FAQ_Item__c.Language__c.getDescribe().getPicklistValues()){
            results.add(picklistEntry.getValue());
        }
        return results;
    }

    private static Boolean isUserLanguageExistInPicklistValues(List<String> languagePicklistValues, String userLanguage) {
        Boolean isLanguageExist = false;
        for (String value : languagePicklistValues) {
            if (value == userLanguage) {
                isLanguageExist = true;
            }
        }
        return isLanguageExist;
    }

    public class FaqTopicsWrapper {
        @AuraEnabled public List<String> topics { get; set; }
        @AuraEnabled public Map<String, List<FaqItemsWrapper>> items { get; set; }

    }

    public class FaqItemsWrapper {
        @AuraEnabled public Boolean isOpen { get; set; }
        @AuraEnabled public FAQ_Item__c faqItem { get; set; }
        @AuraEnabled public String question { get; set; }
        @AuraEnabled public String answer { get; set; }

        public FaqItemsWrapper() {
            isOpen = false;
        }
    }
}