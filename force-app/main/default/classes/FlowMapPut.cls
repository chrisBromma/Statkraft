public class FlowMapPut {
    @InvocableMethod(label='Flow Tool: Add a new record to your Map or overwrite an existing record (Map.put())' category='Flow Toolbox: 1-to-1 Object Mapping')
    public static Output[] putInMap(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            Boolean replacedInList = false;
            FlowMapElement[] flowMap = inputItem.flowMap;
            SObject sobj = inputItem.record;
            String mappedField = flowMap[0].mappedSObjectField;

            for (FlowMapElement mapElem : flowMap) {
                if (mapElem.record.get(mapElem.mappedSObjectField) == sobj.get(mapElem.mappedSObjectField)) {
                    mapElem.key = (string) sObj.get(mapElem.mappedSObjectField);
                    mapElem.record = sobj;
                    replacedInList = true;
                    break;
                }
            }
            if (!replacedInList) {
                FlowMapElement obj = new FlowMapElement(sobj, mappedField);
                flowMap.add(obj);
            }
            Output obj = new Output();
            obj.flowMap = flowMap;
            result.add(obj);
        }

        return result;
    }

    /* Input(s) for Invocable method */
    public class Input {
        @InvocableVariable(label='Records you want to put into the Map' required=true)
        public sObject record;

        @InvocableVariable(label='Map to put your records into' required=true)
        public FlowMapElement[] flowMap;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='Resulting Map with new values')
        public FlowMapElement[] flowMap;
    }
}