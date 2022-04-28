public class ListMapContainer {

    Map<String, List<SObject>> objectMap;
    SObjectType sobjectType;
    String sobjectTypeString;

    public ListMapContainer(SObjectType sobjType) {
        this.sobjectType = sobjType;
        this.sobjectTypeString = sobjType.getDescribe().getName();

        String typedMapString = 'Map<String,List<' + sobjectTypeString + '>>';
        Type mapType = Type.forName(typedMapString);
        objectMap = (Map<String, List<SObject>>) mapType.newInstance();

    }

    public Map<String, List<SObject>> getMap() {
        return this.objectMap;
    }

    public SObjectType getSObjectType() {
        return this.sobjectType;
    }

    public void addToMap(String key, SObject sObj) {
        if (sObj.getSObjectType() != this.sobjectType) {
            throw new TypeException('The SObject you wanted to add to this Map is not the one the Map is constructed with');
        }
        if (!objectMap.containsKey(key)) {
            Type listType = Type.forName('List<' + sobjectTypeString + '>');
            List<SObject> objectList = (List<SObject>) listType.newInstance();
            this.objectMap.put(key, objectList);
        }
        this.objectMap.get(key).add(sObj);
    }

    public void put(String key, List<SObject> objectList) {
        if (objectList.getSObjectType() != this.sobjectType) {
            throw new TypeException('The SObject List you wanted to put to this Map is not the one the Map is constructed with');
        }
        this.objectMap.put(key, objectList);
    }

    public Boolean containsKey(String key) {
        return this.objectMap.containsKey(key);
    }

    public List<SObject> get(String key) {
        List<SObject> result = this.objectMap.get(key);
        if (result == null) {
            Type listType = Type.forName('List<' + sobjectTypeString + '>');
            result = (List<SObject>) listType.newInstance();
        }
        return result;
    }

    public Set<String> keySet() {
        return this.objectMap.keySet();
    }
}