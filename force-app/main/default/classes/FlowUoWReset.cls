public without sharing class FlowUoWReset {
    @InvocableMethod(Label='Reset contents of Unit of Work' Category='Flow UoW')
    public static void refreshUoW(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        UnitOfWorkSingleton.refreshInstance(instanceName);
    }
    public class Input {
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
    }
}