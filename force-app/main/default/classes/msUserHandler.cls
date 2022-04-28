public without sharing class msUserHandler extends TriggerHandlerExtension {

    // Variables
    private static final String globalCustomerCommunityUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Global Customer Community User' LIMIT 1].Id;
    private Set<Id> globalCustomerCommunityUserIds = new Set<Id>();
    private static Map<Id, Set<String>> globalCustomerCommunityUsersSubscriptionsMap = new Map<Id, Set<String>>();

    // Constructor
    public msUserHandler() {
        super();
    }

    //bulkBefore
    public override void bulkBefore() {
            if (Trigger.isInsert || Trigger.isUpdate) {
                List<User> newUsers = (List<User>) Trigger.new;
                for (User newUser : newUsers) {
                    if (newUser.ProfileId == globalCustomerCommunityUserProfileId) {
                        newUser.UserPreferencesDisableAllFeedsEmail = true;
                        globalCustomerCommunityUsersSubscriptionsMap.put(newUser.ContactId, new Set<String>());
                    }
                }
                if (Trigger.isUpdate) {
                    List<msUserNotificationSetting__c> globalCustomerCommunityUsersSubscriptions = [
                            SELECT msNotificationType__c, msIsEmail__c, msContact__c
                            FROM msUserNotificationSetting__c
                            WHERE msContact__c IN :globalCustomerCommunityUsersSubscriptionsMap.keySet()
                    ];
                    for (msUserNotificationSetting__c subscriptionItem : globalCustomerCommunityUsersSubscriptions) {
                        if (globalCustomerCommunityUsersSubscriptionsMap.containsKey(subscriptionItem.msContact__c)) {
                            globalCustomerCommunityUsersSubscriptionsMap.get(subscriptionItem.msContact__c).add(subscriptionItem.msNotificationType__c);
                        }
                    }
                }
            }
    }

    //bulkAfter
    public  override void bulkAfter() {
        
            if (Trigger.isInsert || Trigger.isUpdate) {
                List<User> newUsers = (List<User>) Trigger.new;
                for (User newUser : newUsers) {
                    if (newUser.ProfileId == globalCustomerCommunityUserProfileId) {
                        globalCustomerCommunityUserIds.add(newUser.Id);
                        if (Trigger.isInsert) {
                            lstInsert.add(generateSubscription(newUser.ContactId, 'downreg_notification'));
                            lstInsert.add(generateSubscription(newUser.ContactId, 'submeter_enabled'));
                            lstInsert.add(generateSubscription(newUser.ContactId, 'live_metering_notification'));
                            lstInsert.add(generateSubscription(newUser.ContactId, 'masterdata_confirmation'));
                            lstInsert.add(generateSubscription(newUser.ContactId, 'masterdata_confirmation_reminder'));
                        }
                        if (Trigger.isUpdate) {
                            if (globalCustomerCommunityUsersSubscriptionsMap.get(newUser.ContactId) != null) {
                                Set<String> notedSubscriptions = globalCustomerCommunityUsersSubscriptionsMap.get(newUser.ContactId);
                                if (!notedSubscriptions.contains('downreg_notification')) {
                                    lstInsert.add(generateSubscription(newUser.ContactId, 'downreg_notification'));
                                }
                                if (!notedSubscriptions.contains('submeter_enabled')) {
                                    lstInsert.add(generateSubscription(newUser.ContactId, 'submeter_enabled'));
                                }
                            }
                        }
                    }
                }
            }
    }

    //beforeInsert
     
    /*public override void beforeInsert(SObject obj) {
        
            addToLoopCount();
    }*/

    //beforeUpdate
    public override void beforeUpdate(SObject oldObj, SObject obj) {
        if (isDisabled) {
            return;
        } else {
            addToLoopCount();
        }

        User tempUser = (User) obj;
        User tempUserOld = (User) oldObj;
        if (tempUser.IsActive == false && tempUserOld.IsActive == true) {
            tempUser.Activate_User_at__c=null;
        }
    }

    //beforeDelete
    /*public override void beforeDelete(SObject obj) {
        
            addToLoopCount();
    }*/

    //afterInsert
    /*public override void afterInsert(SObject obj) {
     
            addToLoopCount();
    }*/

    //afterUpdate
    /*public override void afterUpdate(SObject oldObj, SObject obj) {

            addToLoopCount();
    }*/

    //afterDelete
    /*public override void afterDelete(SObject obj) {
        
            addToLoopCount();
    }*/

    //andFinally
    public override void andFinally() {
        if (isDisabled) {
            return;
        }

        if (!globalCustomerCommunityUserIds.isEmpty()) {
            disableNetworkMembersAllFeedEmail();
        }

        // insert lstInsert-List
        try {
            if (!lstInsert.isEmpty()) {
                insert(lstInsert);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on msUserHandler Finally insert: ' + e);
        }
        // upsert lstUpsert-List
//        try{
//            if( !lstUpsert.isEmpty() ) {
//                Database.upsert(lstUpsert);
//            }
//        } catch (Exception e ) { System.debug(LoggingLevel.ERROR, 'Exception on msUserHandler Finally upsert: ' + e); }
        // update lstUpdate-List
        try {
            if (!lstUpdate.isEmpty()) {
                update(lstUpdate);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception on msUserHandler Finally update: ' + e);
        }
        // delete lstDelete-List
//        try{
//            if( !lstDelete.isEmpty() ) {
//                Database.delete(lstDelete);
//            }
//        } catch (Exception e ) { System.debug(LoggingLevel.ERROR, 'Exception on msUserHandler Finally delete: ' + e); }
    }
    
    private void disableNetworkMembersAllFeedEmail() {
        if (!globalCustomerCommunityUserIds.isEmpty()) {
            List<NetworkMember> networkMembers = [SELECT Id,PreferencesDisableAllFeedsEmail FROM NetworkMember WHERE MemberId IN :globalCustomerCommunityUserIds];
            for (NetworkMember networkMember : networkMembers) {
                networkMember.PreferencesDisableAllFeedsEmail = true;
                lstUpdate.add(networkMember);
            }
            globalCustomerCommunityUserIds = new Set<Id>();
        }
    }

    private msUserNotificationSetting__c generateSubscription(Id contactId, String messageType) {
        msUserNotificationSetting__c signUp = new msUserNotificationSetting__c();
        signUp.msContact__c = contactId;
        signUp.msNotificationType__c = messageType;
        signUp.msIsEmail__c = true;
        return signUp;
    }
}