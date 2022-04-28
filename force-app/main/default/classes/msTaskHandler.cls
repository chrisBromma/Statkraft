public without sharing class msTaskHandler extends TriggerHandlerExtension{

    public msTaskHandler() {
        super();
    }


    public override void bulkAfter() {
        if(isDisabled) {
            return;
        } else {
            if(Trigger.isUpdate) {
                msTaskHelper.validateAMCTasks((Map<Id,Task>) Trigger.oldMap, (List<Task>) Trigger.new);
            }
        }
    }
}