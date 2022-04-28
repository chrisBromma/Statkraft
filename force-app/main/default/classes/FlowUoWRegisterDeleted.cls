public without sharing class FlowUoWRegisterDeleted {
    @InvocableMethod(Label='Register record for delete' Category='Flow UoW')
    public static void registerDelete(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(instanceName);

        for (Input input : inputs) {
            instance.registerDeleted(input.record);
        }
    }

    public class Input {
        @InvocableVariable(Label='VARIABLE: Source Record' Required=true)
        public SObject record;
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
    }
}