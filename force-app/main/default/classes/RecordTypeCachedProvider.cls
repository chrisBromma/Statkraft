public class RecordTypeCachedProvider {
    private Map<Id, RecordType> recordTypes = new Map<Id, RecordType>();
    private Map<String, List<RecordType>> sObjectTypes = new Map<String, List<RecordType>>();
    private Map<String, RecordType> recordTypeBySObjectAndDeveloperName = new Map<String, RecordType>();


    private static RecordTypeCachedProvider instance;

    private RecordTypeCachedProvider() {

    }


    public static RecordTypeCachedProvider getInstance() {
        if (instance == null) {
            instance = new RecordTypeCachedProvider();
            instance.load();
        }
        return instance;
    }


    /*returns the list with all record types, DARE YOU to modify this map */
    public Map<Id, RecordType> getRecordTypes() {
        return this.recordTypes;
    }


    /**
    * (re)loads the recordtypes from db to cache
    **/
    public void load() {
        recordTypes = new Map<Id, RecordType>(
        [
                SELECT SystemModstamp,
                        SobjectType,
                        NamespacePrefix,
                        Name,
                        LastModifiedDate,
                        LastModifiedById,
                        IsActive,
                        Id,
                        DeveloperName,
                        Description,
                        CreatedDate,
                        CreatedById,
                        BusinessProcessId
                FROM RecordType
        ]);
        for (RecordType rc : recordTypes.values()) {
            if (!sObjectTypes.containsKey(rc.SobjectType)) {
                sObjectTypes.put(rc.SobjectType, new List<RecordType>());
            }
            sObjectTypes.get(rc.SobjectType).add(rc);
            recordTypeBySObjectAndDeveloperName.put(rc.SobjectType + '-' + rc.DeveloperName, rc);
        }
    }

    public RecordType byDeveloperName(String sObjectType, String developerName) {

        return recordTypeBySObjectAndDeveloperName.get(sObjectType + '-' + developerName);

    }

    public List<RecordType> byDeveloperName(Set<String> developerNames) {

        List<RecordType> filteredRecordTypes = new List<RecordType>();

        for (RecordType recType : recordTypes.values()) {
            if (developerNames.contains(recType.DeveloperName)) {
                filteredRecordTypes.add(recType);
            }
        }

        return filteredRecordTypes;
    }

    public List<RecordType> byDeveloperName(String sObjectType, Set<String> developerNames) {

        List<RecordType> filteredRecordTypes = new List<RecordType>();

        for (String devName : developerNames) {
            String sobjectWithDevName = sObjectType + '-' + devName;
            if (recordTypeBySObjectAndDeveloperName.containsKey(sobjectWithDevName)) {
                filteredRecordTypes.add(recordTypeBySObjectAndDeveloperName.get(sobjectWithDevName));
            }
        }

        return filteredRecordTypes;
    }

    public List<RecordType> bySObjectType(String SObjectType) {
        return this.sObjectTypes.get(SObjectType);
    }

    public RecordType byId(Id id) {
        return this.recordTypes.get(id);
    }

    public RecordType getDefaultRecordTypeMappingForCurrentUser(String forObject) {
        SObjectType stype = Schema.getGlobalDescribe().get(forObject);
        if (stype == null) {
            System.debug(LoggingLevel.ERROR, 'cant get SObjectType for ' + forObject);
            return null;
        }

        List<Schema.RecordTypeInfo> infos = stype.getDescribe().getRecordTypeInfos();
        for (Schema.RecordTypeInfo info : infos) {
            if (info.isDefaultRecordTypeMapping()) { //default record type for user?
                return recordTypes.get(info.recordTypeId);
            }
        }
        return null;
    }

}