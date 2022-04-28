public without sharing class FlowUoWRegisterNew {
    @InvocableMethod(Label='Register new record to Unit of Work' Category='Flow UoW')
    public static void registerNew(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(instanceName);

        String relationshipPath;
        for (Input input : inputs) {
            if (input.relationshipPath == null || String.isBlank(input.relationshipPath)) {
                instance.registerNew(input.record);
                continue;
            } else {
                relationshipPath = input.relationshipPath;
                break;
            }
        }
        if (relationshipPath != null) {
            List<String> pathSplit = relationshipPath.split('\\.');
            fflib_SObjectDescribe objectDescribe = fflib_SObjectDescribe.getDescribe(pathSplit[0]);
            Schema.SObjectField relatedToField = objectDescribe.getField(pathSplit[1]);
            for (Input input : inputs) {
                instance.registerNew(input.record, relatedToField, input.parent);
            }
        }
    }

    public class Input {
        @InvocableVariable(Label='VARIABLE: Record you want to register' Required=true)
        public SObject record;
        @InvocableVariable(Label='STATIC: Relationship Path to parent Object')
        public String relationshipPath;
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
        @InvocableVariable(Label='VARIABLE: Parent record to associate')
        public SObject parent;
    }
}