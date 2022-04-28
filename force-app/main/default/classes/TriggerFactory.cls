public without sharing class TriggerFactory {
    /**
     * @description Retrieves Handlers from Trigger Factory Setting and executes them by Order of Execution
     * @author mindsquare AG
     * @param  objType The Object Type of the Trigger you are calling.
     * @throws TriggerException when there is no Trigger Factory Setting or no class found.
     */

    public static void executeTriggerHandlers(Schema.SObjectType objType) {
        List<ITrigger> handlers = getHandlers(objType);

        if (handlers.size() == 0) {
            throw new TriggerException('No Trigger Handler registered for Object Type: ' + objType);
        }

        preventDataLoaderUsage(Url.getCurrentRequestUrl().toExternalForm());

        //Calculate Rollups only once for an SObject, does not need to run in every Handler.
        if (Trigger.isExecuting) {
            try {
                Rollup.runFromTrigger();
            } catch (Exception e) {
                //silent death
                //Exception is thrown if there is no Rollup defined for the object
                //Will be fixed in the framework with later releases (01.11.2021)
            }
        }

        for (ITrigger handler : handlers) {
            execute(handler, Trigger.operationType?.name(), Trigger.new, Trigger.oldMap);
        }
    }

    /**
     * @description Takes the Trigger execution methods from the retrieved Handlers and executes them. Starts with bulkBefore / bulkAfter and then goes into single-record methods
     * @author mindsquare AG
     * @param handler The implementation of the Trigger Handler.
     * @param triggerOperation Running Trigger Operation Type
     * @param triggerNew Trigger.new from the running Trigger Context
     * @param triggerOldMap Trigger.oldMap from the running Trigger Context
     */
    @TestVisible
    private static void execute(ITrigger handler, String triggerOperation, List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {
        if (!handler.isDisabled()) {
            //Split the operation type (for example AFTER_INSERT) into its two pieces to determine what we need.
            List<String> operations = triggerOperation.split('_');
            Boolean isBefore = operations[0] == 'BEFORE';
            String dmlOperation = operations[1];

            // Before Trigger
            if (isBefore) {
                // Call the bulk before to handle any caching of data and enable Bulkification
                handler.bulkBefore();

                switch on dmlOperation {
                    when 'DELETE' {
                        for (SObject obj : triggerOldMap.values()) {
                            handler.beforeDelete(obj);
                        }
                    }
                    when 'INSERT' {
                        for (SObject obj : triggerNew) {
                            handler.beforeInsert(obj);
                        }
                    }
                    when 'UPDATE' {
                        for (SObject obj : triggerNew) {
                            handler.beforeUpdate(triggerOldMap.get(obj.Id), obj);
                        }
                    }
                }
            } else {
                // Call the bulk after to handle any caching of data and enable Bulkification
                handler.bulkAfter();

                switch on dmlOperation {
                    when 'DELETE' {
                        for (SObject obj : triggerOldMap.values()) {
                            handler.afterDelete(obj);
                        }
                    }
                    when 'INSERT' {
                        for (SObject obj : triggerNew) {
                            handler.afterInsert(obj);
                        }
                    }
                    when 'UPDATE' {
                        for (SObject obj : triggerNew) {
                            handler.afterUpdate(triggerOldMap.get(obj.Id), obj);
                        }
                    }
                    when 'UNDELETE' {
                        for (SObject obj : triggerNew) {
                            handler.afterUndelete(obj);
                        }
                    }
                }
            }

            // Perform any post processing
            handler.andFinally();
        }
    }

    /**
     * @description retrieves a List of all Trigger Handlers that need to be executed for a given SObject Type. Returns an empty list if no Trigger Handler is registered.
     * @author mindsquare AG
     * @param  objType The SObject Type of the calling Trigger
     * @return A list of all Trigger Handlers of the currently calling Trigger's SObject Type.
     */
    @TestVisible
    private static List<ITrigger> getHandlers(Schema.SObjectType objType) {
        List<ITrigger> handlers = new List<ITrigger>();

        String objectName = objType.getDescribe().getName().toUpperCase();

        if (TriggerMapping.getInstance().containsKey(objectName)) {
            for (String className : TriggerMapping.getInstance().get(objectName)) {
                handlers.add((ITrigger) Type.forName(className).newInstance());
            }
        }
        return handlers;
    }

    @TestVisible
    private static void preventDataLoaderUsage(String requestOrigin) {
        if (
            !requestOrigin.contains('visualforce.com') &&
            !requestOrigin.contains(UserInfo.getOrganizationId().left(14)) &&
            (requestOrigin.contains('Soap/') || requestOrigin.contains('bulkapi'))
        ) {
            Boolean canUseDataloader = FeatureManagement.checkPermission('Can_Use_Dataloader');

            if (canUseDataloader == false) {
                Logger.error('Request URL: ' + requestOrigin);
                Logger.saveLog('Data Loader Prevention');

                SecurityException e = new SecurityException();
                e.setMessage('You are not allowed to use Data Loader. Please ask an administrator, to help!');
                throw e;
            } else {
                Logger.info('Request URL: ' + requestOrigin);
                Logger.saveLog('Data Loader Prevention');
            }
        }
    }
    public class TriggerException extends Exception {
    }
}