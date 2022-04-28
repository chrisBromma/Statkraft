public without sharing class FlowUoWRegisterDirty {
    @InvocableMethod(Label='Register record for update' Category='Flow UoW')
    public static void registerDirty(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(instanceName);

        String relationshipPath;
        for (Input input : inputs) {
            if (input.relationshipPath == null || String.isBlank(input.relationshipPath)) {
                instance.registerDirty(input.record);
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
                instance.registerDirty(input.record, relatedToField, input.parent);
            }
        }
    }

    public class Input {
        @InvocableVariable(Label='VARIABLE: Source Record' Required=true)
        public SObject record;
        @InvocableVariable(Label='STATIC: Relationship Path to related Object')
        public String relationshipPath;
        @InvocableVariable(Label='VARIABLE: New Parent Field for Reparenting (currently registered)')
        public SObject parent;
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
    }
}