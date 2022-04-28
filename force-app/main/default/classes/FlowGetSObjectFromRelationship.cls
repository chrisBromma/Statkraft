public with sharing class FlowGetSObjectFromRelationship {
    @InvocableMethod(label='Flow Tool: Get List of Related Objects from List of SObjects via Relationship' category='Flow Toolbox')
    public static Output[] extractSObjects(Input[] inputs) {
        Output[] result = new List<Output>{};
        for (Input inputItem : inputs) {
            Output obj = new Output();
            String lookupField = inputItem.lookupIdField;
            String lookupRelationship = lookupField.contains('__c') ? lookupField.replace('__c', '__r') : lookupField;
            Set<SObject> outputSObjects = new Set<SObject>();

            for (SObject loopObj : inputItem.records) {
                if (loopObj.getSObject(lookupRelationship) != null) {
                    SObject relatedObject = loopObj.getSObject(lookupRelationship);
                    outputSObjects.add(relatedObject);
                }
            }
            List<SObject> outputSObjectList = new List<SObject>(outputSObjects);
            if (inputItem.fields != null) {
                outputSObjectList = msLepton.setFieldsFromFieldset(outputSObjectList, inputItem.fields.split(','));
            }

            obj.records = outputSObjectList;
            result.add(obj);
        }

        return result;
    }

    public class Input {
        @InvocableVariable(label='1. List to extract records from' required=true)
        public sObject[] records;

        @InvocableVariable(label='2. Lookup Field for your SObjects (e.g. "Meter__c" for extracting Meter from Meter_Registration__c' required=true)
        public String lookupIdField;

        @InvocableVariable(label='3.Field Set (Comma-Separated) of fields you absolutely need, even if null (no relations)')
        public String fields;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='List of Extracted SObjects')
        public Sobject[] records;
    }
}