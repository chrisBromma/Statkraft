public class FlowListMapCreate {
    @InvocableMethod(Label='Flow Tool: Create 1:N Field to Object List Mapping' category='Flow Toolbox: 1-to-N List Mapping')
    public static Output[] createMap(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            FlowMapElement[] flowMap = new List<FlowMapElement>{};
            Map<String, List<SObject>> mapStringToSObject = new Map<String, List<SObject>>();
            String groupField = inputItem.groupByField;
            if (inputItem.records != null && groupField != null) {
                for (SObject sObj : inputItem.records) {
                    String fieldValue = String.valueOf(sObj.get(groupField));
                    if (!mapStringToSObject.containsKey(fieldValue)) {
                        mapStringToSObject.put(fieldValue, new List<SObject>());
                    }
                    mapStringToSObject.get(fieldValue).add(sObj);
                }

                for (String fieldKey : mapStringToSObject.keySet()) {
                    FlowMapElement flowElem = new FlowMapElement(fieldKey, mapStringToSObject.get(fieldKey), groupField);
                    flowMap.add(flowElem);
                }
            }
            Output obj = new Output();
            obj.flowMap = flowMap;
            result.add(obj);
        }
        return result;
    }

    /* Input(s) for Invocable method */
    public class Input {
        @InvocableVariable(Label='Records to create Map with')
        public SObject[] records;

        @InvocableVariable(Label='String field to group your records by')
        public String groupByField;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(Label='Resulting Map')
        public FlowMapElement[] flowMap;
    }
}