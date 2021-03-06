public class ai_PicklistValueController {

    public static List<String> getselectOptions(sObject objObject, string field) {
        return getselectOptions(objObject.getSObjectType(), field);
    }

    public static List<String> getselectOptions(sObjectType objObjectType, string field) {
        List<String> allOpts = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = objObjectType.getDescribe().fields.getMap();
        for (Schema.PicklistEntry entry : fieldMap.get(field).getDescribe().getPickListValues()) {
            allOpts.add(entry.getValue());
        }
        return allOpts;
    }

    public static Map<Object,List<String>> getDependentPicklist(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = control.getType() == Schema.DisplayType.Boolean ? null : control.getPicklistValues();

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, List<String>> dependentPicklistValues = new Map<Object, List<String>>();
        for(Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if(entry.isActive()) {
                List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for(Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue = controlEntries == null ? (Object) (index == 1)  : (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null);
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod(index, 6);
                    if(controlValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0)
                        continue;
                    if(!dependentPicklistValues.containsKey(controlValue)) {
                        dependentPicklistValues.put(controlValue, new List<String>());
                    }
                    dependentPicklistValues.get(controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
}