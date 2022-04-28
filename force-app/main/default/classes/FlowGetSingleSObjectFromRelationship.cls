public with sharing class FlowGetSingleSObjectFromRelationship {
    @InvocableMethod(label='Flow Tool: Get Related Object from SObject via Relationship' category='Flow Toolbox')
    public static Output[] extractSObjects(Input[] inputs) {
        Output[] result = new List<Output>{};
        for (Input inputItem : inputs) {
            Output obj = new Output();
            String lookupField = inputItem.lookupIdField;
            String lookupRelationship = lookupField.contains('__c') ? lookupField.replace('__c', '__r') : lookupField;
            SObject outputSObject = inputItem.record.getSObject(lookupRelationship);

            if (inputItem.fields != null) {
                outputSObject = msLepton.setFieldsFromFieldset(new List<SObject>{ outputSObject }, inputItem.fields.split(','))[0];
            }

            obj.record = outputSObject;
            result.add(obj);
        }

        return result;
    }

    public class Input {
        @InvocableVariable(label='1. Record for Extraction' required=true)
        public sObject record;

        @InvocableVariable(label='2. Lookup Field for your SObjects (e.g. "Meter__c" for extracting Meter from Meter_Registration__c' required=true)
        public String lookupIdField;

        @InvocableVariable(label='Field Set of fields on Object you absolutely need, even if null (Comma-Separated, no relations)')
        public String fields;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='Extracted SObjects')
        public Sobject record;
    }
}