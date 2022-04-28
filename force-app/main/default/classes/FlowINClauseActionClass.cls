public class FlowINClauseActionClass {
    @InvocableMethod(label='Flow Tool: SELECT WHERE IN clause query (literal values)' category='Flow Toolbox: Queries')
    public static Output[] filterRecords(Input[] inputList) {
        String[] combinedFilterValuesCollection = new List<String>{};

        for (FlowINClauseActionClass.Input input : inputList) {
            for (String s : input.filteringValuesCollection) {
                if (!combinedFilterValuesCollection.contains(s)) {
                    combinedFilterValuesCollection.add(s);
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
        FlowINClauseActionClass.Output[] outputList = new List<FlowINClauseActionClass.Output>{};

        SObject[] recordList = database.query(query);

        for (Input input : inputList) {
            if (input.enforceValues == null) {
                input.enforceValues = true;
            }
            FlowINClauseActionClass.Output output = new FlowINClauseActionClass.Output();
            List<String> fieldsToEnforce = new List<String>();
            if (input.enforceValues) {
                for (String field : input.fieldsToQuery.split(',')) {
                    if (!field.contains('.')) {
                        fieldsToEnforce.add(field);
                    }
                }
            }

            SObject[] filteredRecords = new List<SObject>{};
            for (SObject s : recordList) {
                if (input.filteringValuesCollection.contains((String) s.get(inputList[0].filterField))) {
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

        @InvocableVariable(label='3. SELECT xxxxx FROM xxxxx WHERE [INSERT THIS] IN xxxxx' required=true)
        public string filterField;

        @InvocableVariable(label='4. SELECT xxxxx FROM xxxxx WHERE xxxxx IN :[INSERT THIS]' required=true)
        public string[] filteringValuesCollection;
    }

    /* Output parameters of the Apex action */
    public class Output {
        @InvocableVariable(label='List of records from output')
        public sObject[] records;
    }
}