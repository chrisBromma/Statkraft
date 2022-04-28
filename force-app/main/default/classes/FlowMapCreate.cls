public class FlowMapCreate {
    @InvocableMethod(label='Flow Tool: Create 1-to-1 Field to Object Mapping' category='Flow Toolbox: 1-to-1 Object Mapping')
    public static Output[] createMap(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            FlowMapElement[] flowMap = new List<FlowMapElement>{};

            for (sObject sObj : inputItem.records) {
                FlowMapElement obj = new FlowMapElement(sObj, inputItem.mappingField);
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
        @InvocableVariable(label='Records to put into your Map' required=true)
        public sObject[] records;

        @InvocableVariable(label='Field to Map by (if not unique, the latest record will be mapped)' required=true)
        public String mappingField;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='Map')
        public FlowMapElement[] flowMap;
    }
}