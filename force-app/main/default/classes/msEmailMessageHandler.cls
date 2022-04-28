public class msEmailMessageHandler extends TriggerHandlerExtension{
    
    msEmailMessageHelper helper = msEmailMessageHelper.getInstance();

    public msEmailMessageHandler() {
        super();
    }

    public override void afterInsert(SObject newSO){
        EmailMessage newMail = (EmailMessage) newSO;

        helper.checkIfEmailWasSentOnCase(newMail);
    }


    public override void andFinally(){
        if(Trigger.operationType == TriggerOperation.AFTER_INSERT){
            helper.deleteEmailMessagePostsOnCases();
        }
    }

}