public with sharing class FlowExecuteSOQL {
    @InvocableMethod(label='Flow Tool: Execute SOQL query' category='Flow Toolbox: Queries')
    public static Output[] executeSOQL(Input[] input) {
        Output[] result = new List<Output>{};

        for (Input inputItem : input) {
            List<SObject> records = Database.query(inputItem.query);
            Output op = new Output();
            List<SObject> recordList = new List<SObject>();
            if (inputItem.fields != null) {
                records = msLepton.setFieldsFromFieldset(records, inputItem.fields.split(','));
            }
            op.records = records;
            op.length = records.size();
            result.add(op);
        }

        return result;
    }

    public class Input {
        @InvocableVariable(label='1. SOQL Query' required=true)
        public String query;

        @InvocableVariable(
            label='2. Field Set for Fields you absolutely need on your queried Object, even if null (no relations, comma-separated)'
        )
        public String fields;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='List of Records')
        public Sobject[] records;
        @InvocableVariable(label='length of result list')
        public integer length;
    }
}