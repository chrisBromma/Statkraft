public without sharing class FlowUoWRegisterRelationship {
    @InvocableMethod(Label='Register Relationship to a yet-to-be-inserted Record' Category='Flow UoW')
    public static void registerRelationship(Input[] inputs) {
        String instanceName = inputs[0].instanceName;
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance(instanceName);

        String relationshipPath = inputs[0].relationshipPath;
        List<String> pathSplit = relationshipPath.split('\\.');

        fflib_SObjectDescribe objectDescribe = fflib_SObjectDescribe.getDescribe(pathSplit[0]);
        Schema.SObjectField relatedToField = objectDescribe.getField(pathSplit[1]);

        for (Input input : inputs) {
            instance.registerRelationship(input.record, relatedToField, input.related);
        }
    }

    public class Input {
        @InvocableVariable(Label='VARIABLE: Source Record' Required=true)
        public SObject record;
        @InvocableVariable(Label='STATIC: Relationship Path to related Object' Required=true)
        public String relationshipPath;
        @InvocableVariable(Label='VARIABLE: Related record to associate' Required=true)
        public SObject related;
        @InvocableVariable(Label='STATIC: Name of Flow' Required=true)
        public String instanceName;
    }
}