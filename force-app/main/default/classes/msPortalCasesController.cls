/**
 * Created by Fabian on 14.03.2019.
 */

public without sharing class msPortalCasesController {
    @AuraEnabled
    public static Map<String, List<Case>> getCases(String userId, String[] contractIds, String[] plantIds) {
        Map<String, List<Case>> resultList = new Map<String, List<Case>>();

        List<Case> myCases = new List<Case>();
        myCases = [
            SELECT
                Account.Name,
                AccountId,
                Technology__c,
                Registration_Date__c,
                Product__c,
                Priority,
                ClosedDate,
                Contact_Made__c,
                Reason,
                Origin,
                CaseNumber,
                Case_Creator__c,
                Case_Creator__r.Name,
                CreatedDate,
                Status,
                Subject,
                Type,
                Description,
                Contract__c,
                Contract__r.Name,
                Meter__r.Name,
                Meter__c
            FROM Case
            WHERE Case_Creator__c = :userId
        ];

        List<Case> myPlants = new List<Case>();
        myPlants = [
            SELECT
                Account.Name,
                AccountId,
                Technology__c,
                Registration_Date__c,
                Product__c,
                Priority,
                ClosedDate,
                Contact_Made__c,
                Reason,
                Origin,
                CaseNumber,
                Case_Creator__c,
                Case_Creator__r.Name,
                CreatedDate,
                Status,
                Subject,
                Type,
                Description,
                Contract__c,
                Contract__r.Name,
                Meter__r.Name,
                Meter__c
            FROM Case
            WHERE Meter__c IN :plantIds
        ];

        List<Case> myContracts = new List<Case>();
        myContracts = [
                SELECT
                        Account.Name,
                        AccountId,
                        Technology__c,
                        Registration_Date__c,
                        Product__c,
                        Priority,
                        ClosedDate,
                        Contact_Made__c,
                        Reason,
                        Origin,
                        CaseNumber,
                        Case_Creator__c,
                        Case_Creator__r.Name,
                        CreatedDate,
                        Status,
                        Subject,
                        Type,
                        Description,
                        Contract__c,
                        Contract__r.Name,
                        Meter__r.Name,
                        Meter__c,
                        Contract__r.Alternative_Contract_Name__c
                FROM Case
                WHERE Contract__c IN :contractIds
                AND (
                        (
                                RecordTypeId IN (:msUtility.CASE_STANDARD_REC_TYPE_ID, :msUtility.CASE_MASTERDATA_CHANGEREQ_REC_TYPE_ID)
                                AND
                                Reason IN :new List<String>(getCaseReasonFromPicklist())
                        )
                        OR Show_On_Portal__c = TRUE
                )
                Order by Status ASC, CreatedDate DESC
        ];

        for (Case tmp : myContracts) {
            tmp.Contract__r.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(tmp.Contract__r.Name, '/');
        }
        for (Case tmp : myPlants) {
            tmp.Contract__r.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(tmp.Contract__r.Name, '/');
        }
        for (Case tmp : myCases) {
            tmp.Contract__r.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(tmp.Contract__r.Name, '/');
        }

        resultList.put('myCases', myCases);
        resultList.put('myPlants', myPlants);
        resultList.put('myContracts', myContracts);

        return resultList;
    }

    private static List<String> getCaseReasonFromPicklist() {
        List<String> caseReasonsList = new List<String>();

        List<msUtility.LabelValuePair> caseReasonsLvp = new List<msUtility.LabelValuePair>();

        Schema.DescribeFieldResult fieldResult = CaseReason__mdt.Reason__c.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry f : ple){
            caseReasonsLvp.add(new msUtility.LabelValuePair(f.getLabel(), f.getValue()));
            caseReasonsList.add(f.getValue());
        }
        return caseReasonsList;
    }
}