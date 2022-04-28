public without sharing class FlowUoWCommit {
    @InvocableMethod(Label='Commit data in Unit of Work' Category='Flow UoW')
    public static void commitWork(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(instanceName);
        instance.commitWork();
    }

    public class Input {
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
    }
}