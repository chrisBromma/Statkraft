public class msEmailMessageHelper {
    public static msEmailMessageHelper instance;
    public static final String FEEDITEM_TYPE_EMAIL_NOTIFICATION = 'EmailMessageEvent';
    private Set<Id> caseIdsEmailMessageEvent = new Set<Id>();

    public msEmailMessageHelper() {
    }

    public static msEmailMessageHelper getInstance(){
        if(instance == null){
            instance = new msEmailMessageHelper();
        }
        return instance;
    }

    public void checkIfEmailWasSentOnCase(EmailMessage newMail){
        if(newMail.ParentId?.getSObjectType() == Case.SObjectType){
            caseIdsEmailMessageEvent.add(newMail.ParentId);
        }
    }

    public void deleteEmailMessagePostsOnCases(){
        if(!caseIdsEmailMessageEvent.isEmpty()){
            deleteEmailMessageEvents(JSON.serialize(caseIdsEmailMessageEvent));
        }
    }

    @future
    public static void deleteEmailMessageEvents(String listOfCaseIds){
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SobjectType>{FeedItem.SObjectType});

        List<Id> caseIdList = (List<Id>) JSON.deserialize(listOfCaseIds, List<Id>.class);
        List<FeedItem> emailMessageCaseFeedItemList = [SELECT Id FROM FeedItem WHERE Type = :FEEDITEM_TYPE_EMAIL_NOTIFICATION AND ParentId IN :caseIdList];
        if(!emailMessageCaseFeedItemList.isEmpty()){
            uow.registerDeleted(emailMessageCaseFeedItemList);
            uow.commitWork();
        }
    }
}