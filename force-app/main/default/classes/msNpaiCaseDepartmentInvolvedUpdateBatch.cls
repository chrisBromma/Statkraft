global class msNpaiCaseDepartmentInvolvedUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Map<String, String> departmentMapping = new Map<String, String>{
            'FTG'  => 'FTG',
            'MC'  => 'MC',
            'MT'  => 'MT',
            'Legal'  => 'Legal',
            'MFOC'  => 'MFOC',
            'MCCD'  => 'MCCD',
            'MFOD'  => 'MFOD',
            'MCSO'  => 'MCSO',
            'MCSU'  => 'MCSU',
            'MCX'  => 'Other',
            'MEM'  => 'Other',
            'MEO'  => 'Other',
            'MFI'  => 'MFI',
            'MFM'  => 'MFM',
            'MFNP'  => 'MFNP/T',
            'MFNT'  => 'MFNP/T',
            'MFOTO'  => 'MFOTO',
            'MFOTT'  => 'MFOTT',
            'MFOX'  => 'MFOX',
            'MFR'  => 'MFRM',
            'MIBI'  => 'MI',
            'MIMB'  => 'MI',
            'MIMG'  => 'MI'
    };

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Department_involved__c, DepartmentInvolved__c FROM NPC_Cases__c';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<NPC_Cases__c> scope) {
        List<NPC_Cases__c> casesToSave = new List<NPC_Cases__c>();
        for(NPC_Cases__c c : scope) {
            if(String.isNotEmpty(c.Department_involved__c)) {
                List<String> newValues = new List<String>();
                for(String department : c.Department_involved__c.split(';')) {
                    newValues.add(departmentMapping.get(department));
                }
                c.DepartmentInvolved__c = String.join(newValues, ';');
                casesToSave.add(c);
            }
        }
        update casesToSave;
    }

    global void finish(Database.BatchableContext BC) {
    }
}