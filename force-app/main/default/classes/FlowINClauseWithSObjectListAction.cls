public with sharing class FlowINClauseWithSObjectListAction {
    @InvocableMethod(label='Flow Tool: SELECT WHERE IN clause query (from another record list)' category='Flow Toolbox: Queries')
    public static Output[] filterRecords(Input[] inputList) {
        String[] combinedFilterValuesCollection = new List<String>{};
        List<List<String>> filterValuesPerInputVariable = new List<List<String>>();

        for (FlowINClauseWithSObjectListAction.Input input : inputList) {
            String fieldFilter = input.idField;
            input.derivedInputFilterValues = new List<String>();
            for (SObject sObj : input.filteringValuesCollection) {
                String idFieldValue = (String) sObj.get(fieldFilter);
                if (!combinedFilterValuesCollection.contains(idFieldValue)) {
                    combinedFilterValuesCollection.add(idFieldValue);
                    input.derivedInputFilterValues.add(idFieldValue);
                }
            }
        }

        /*Convert the filter value string list to a string of comma separated values*/

        string filterValuesList = '(';
        for (integer i = 0; i < combinedFilterValuesCollection.size(); i++) {
            string filterValue = combinedFilterValuesCollection[i];
            filterValuesList += '\'' + filterValue + '\'';
            if (i != combinedFilterValuesCollection.size() - 1)
                filterValuesList += ',';
        }
        filterValuesList += ')';

        string query =
            'Select ' +
            inputList[0].fieldsToQuery +
            ' FROM ' +
            inputList[0].objectApiName +
            ' WHERE ' +
            inputList[0].filterField +
            ' IN ' +
            filterValuesList;
        //System.debug('Query: '+ query);
        FlowINClauseWithSObjectListAction.Output[] outputList = new List<FlowINClauseWithSObjectListAction.Output>{};

        SObject[] recordList = database.query(query);

        for (Input input : inputList) {
            if (input.enforceValues == null) {
                input.enforceValues = true;
            }
            FlowINClauseWithSObjectListAction.Output output = new FlowINClauseWithSObjectListAction.Output();
            SObject[] filteredRecords = new List<SObject>{};
            List<String> fieldsToEnforce = new List<String>();
            if (input.enforceValues) {
                for (String field : input.fieldsToQuery.split(',')) {
                    if (!field.contains('.')) {
                        fieldsToEnforce.add(field);
                    }
                }
            }
            for (SObject s : recordList) {
                if (input.derivedInputFilterValues.contains((String) s.get(input.filterField))) {
                    filteredRecords.add(s);
                }
            }
            if (input.enforceValues) {
                filteredRecords = msLepton.setFieldsFromFieldset(filteredRecords, fieldsToEnforce);
            }
            output.records = filteredRecords;
            outputList.add(output);
        }
        return outputList;
    }

    /* Input parameters for the Apex action */
    public class Input {
        @InvocableVariable(label='1. SELECT xxxxx FROM [INSERT THIS]' required=true)
        public string objectApiName;

        @InvocableVariable(label='2. SELECT [INSERT THIS] FROM xxxxx' required=true)
        public string fieldsToQuery;

        @InvocableVariable(label='Do you want to enforce these fields on your parent Object even if they result in null ?')
        public Boolean enforceValues;

        @InvocableVariable(label='3. SELECT xxxxx FROM xxxxx WHERE [INSERT THIS] IN :listOfValues' required=true)
        public string filterField;

        @InvocableVariable(label='4. SELECT xxxxx FROM xxxxx WHERE xxxxx IN :[INSERT THIS]' required=true)
        public List<SObject> filteringValuesCollection;

        @InvocableVariable(label='5. Which Field from 4. do you want to use?' required=true)
        public string idField;

        public List<String> derivedInputFilterValues;
    }

    /* Output parameters of the Apex action */
    public class Output {
        @InvocableVariable(label='List of records from output')
        public sObject[] records;
    }
}