/**
* @description controller for Lightning Component c:EntityTree which displays the Park-Malo-Unit Tree Hierarchy
* @author Alexander Herrmann
* @created 2018-08-01
*
* History
* Date			Author				Comment
* 2018-08-01	Alexander Herrmann	initial development
*/
public class EntityTreeController {
    
    @AuraEnabled
    public static String getEntityTree(String recordId, String objectName) {
        if (objectName == 'Case') {
            recordId = [select Contract__c from Case where Id = :recordId].Contract__c;
        }
        List<Cross_Entity_Relationship__c> parksandmalos = [select Parent_Entity__c, Parent_Entity__r.Name,/* Parent_Entity__r.RecordType.Name,*/
                                                            Child_Entity__c, Child_Entity__r.Name, Child_Entity__r.Project_Number__c, Child_Entity__r.DSO_Lookup__r.Name, toLabel(Child_Entity__r.Balancing_Area__c), Child_Entity__r.RecordType.Name
                                                            from Cross_Entity_Relationship__c
                                                            where Parent_Entity__c in (select Entity__c
                                                                                       from Entity_Contract_Relationship__c
                                                                                       where Contract__c = :recordId)
                                                            order by Parent_Entity__r.Name, Child_Entity__r.Name];
        Map<Id, Park> parks = new Map<Id, Park>();
        Map<Id, Malo> malos = new Map<Id, Malo>();
        for (Cross_Entity_Relationship__c cer : parksandmalos) {
            parks.put(cer.Parent_Entity__c, new Park(cer.Parent_Entity__c,
                                                     cer.Parent_Entity__r.Name/*,
                                                     cer.Parent_Entity__r.RecordType.Name*/));
            malos.put(cer.Child_Entity__c, new Malo(cer.Child_Entity__c,
                                                    cer.Parent_Entity__c,
                                                    cer.Child_Entity__r.Name,
                                                    cer.Child_Entity__r.Project_Number__c,
                                                    cer.Child_Entity__r.DSO_Lookup__r.Name,
                                                    cer.Child_Entity__r.Balancing_Area__c/*,
                                                    cer.Child_Entity__r.RecordType.Name*/));
        }
        List<Cross_Entity_Relationship__c> malosandunits = [select Parent_Entity__c, Parent_Entity__r.Name,
                                                            Child_Entity__c, Child_Entity__r.Name, /*Child_Entity__r.RecordType.Name, */Child_Entity__r.Account__r.Name,
                                                            Child_Entity__r.Commissioning_Date__c, Child_Entity__r.Status__c
                                                            from Cross_Entity_Relationship__c
                                                            where Parent_Entity__c in :malos.keySet()
                                                            order by Parent_Entity__r.Name, Child_Entity__r.Name];
        Map<Id, Unit> units = new Map<Id, Unit>();
        for (Cross_Entity_Relationship__c cer : malosandunits) {
            units.put(cer.Child_Entity__c, new Unit(cer.Child_Entity__c,
                                                    cer.Parent_Entity__c,
                                                    cer.Child_Entity__r.Name,
                                                    cer.Child_Entity__r.Account__r.Name,
                                                    cer.Child_Entity__r.Account__c,
                                                    cer.Child_Entity__r.Commissioning_Date__c,
                                                    cer.Child_Entity__r.Status__c/*,
                                                    cer.Child_Entity__r.RecordType.Name*/));
        }
        Tree tree = new Tree();
        for(Unit unit : units.values()) {
            List<Unit> unitList = new List<Unit>();
            if (tree.unitMapByMaloId.containsKey(unit.maloId)) {
                unitList = tree.unitMapByMaloId.remove(unit.maloId);
            }
            unitList.add(unit);
            tree.unitMapByMaloId.put(unit.maloId, unitList);
        }
        for(Malo malo : malos.values()) {
            List<Malo> maloList = new List<Malo>();
            if (tree.maloMapByParkId.containsKey(malo.parkId)) {
                maloList = tree.maloMapByParkId.remove(malo.parkId);
            }
            maloList.add(malo);
            tree.maloMapByParkId.put(malo.parkId, maloList);
        }
        tree.parkList.addAll(parks.values());
        return JSON.serialize(tree);
    }
    
    public class Tree {
        public List<Park> parkList {get;set;}
        public Map<String, List<Malo>> maloMapByParkId {get;set;}
        public Map<String, List<Unit>> unitMapByMaloId {get;set;}
        public Tree() {
            parkList = new List<Park>();
            maloMapByParkId = new Map<String, List<Malo>>();
            unitMapByMaloId = new Map<String, List<Unit>>();
        }
    }
    
    public class Park {
        public String parkId {get;set;}
        public String name {get;set;}
        /*public String recTyp {get;set;}*/
        public Park(String parkId, String name/*, String recTyp*/){
            this.parkId = parkId;
            this.name = name;
            /*this.recTyp = recTyp;*/
        }
    }
    
    public class Malo {
        public String maloId {get;set;}
        public String parkId {get;set;}
        public String name {get;set;}
        public String pjn {get;set;}
        public String dso {get;set;}
        public String bal {get;set;}
        /*public String recTyp {get;set;}*/
        public Malo(String maloId, String parkId, String name, String pjn, String dso, String bal/*, String recTyp*/){
            this.maloId = maloId;
            this.parkId = parkId;
            this.name = name;
            this.pjn = pjn;
            this.dso = dso;
            this.bal = bal;
            /*this.recTyp = recTyp;*/
        }
    }
    
    public class Unit {
        public String unitId {get;set;}
        public String maloId {get;set;}
        public String name {get;set;}
        public String acct {get;set;}
        public String acId {get;set;}
        public Date cmsd {get;set;}
        public String stts {get;set;}
        /*public String recTyp {get;set;}*/
        public Unit(String unitId, String maloId, String name, String acct, String acId, Date cmsd, String stts/*, String recTyp*/){
            this.unitId = unitId;
            this.maloId = maloId;
            this.name = name;
            this.acId = acId;
            this.acct = acct;
            this.cmsd = cmsd;
            this.stts = stts;
            /*this.recTyp = recTyp;*/
        }
    }
    
}