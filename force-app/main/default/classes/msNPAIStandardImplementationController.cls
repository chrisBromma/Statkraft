/****************************************************************************************************
 * Class msNPAIStandardImplementationController
 *
 *   Created By :   Fabian Murk (mindsquare AG)
 *   Create Date :   29.04.2021
 *   Description :
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        Date             Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)      29.04.2021         Init version.
 *****************************************************************************************************/

public without sharing class msNPAIStandardImplementationController {
    public static Id STANDARD_IMPLEMENTATION_TEMPLATE = Schema.SObjectType.Implementation__c.getRecordTypeInfosByDeveloperName()
        .get('Standard_Implementation_Template')
        .getRecordTypeId();

    @AuraEnabled
    public static List<templateWrapper> getImplementationTemplates() {
        List<templateWrapper> templateWrappers = new List<templateWrapper>();
        for (Implementation__c implementation : [
            SELECT Name, Activity_Description__c, Implementation_Type__c
            FROM Implementation__c
            WHERE RecordTypeId = :STANDARD_IMPLEMENTATION_TEMPLATE
        ]) {
            templateWrappers.add(new templateWrapper(implementation));
        }
        return templateWrappers;
    }
    @AuraEnabled
    public static void createStandardImplementations(String standardImplementations) {
        insert convertTemplateToImplementation(
            (List<templateWrapper>) JSON.deserialize(standardImplementations, List<templateWrapper>.class)
        );
    }
    public static List<Implementation__c> convertTemplateToImplementation(List<templateWrapper> templateWrappers) {
        List<Implementation__c> implementationsToCreate = new List<Implementation__c>();
        for (templateWrapper templateWrapper : templateWrappers) {
            implementationsToCreate.add(
                new Implementation__c(
                    Name = templateWrapper.Name,
                    Activity_Description__c = templateWrapper.Activity_Description,
                    Implementation_Type__c = templateWrapper.Implementation_Type,
                    OwnerId = templateWrapper.assignee,
                    StartDate__c = templateWrapper.startDate,
                    EndDate__c = templateWrapper.endDate,
                    NPC_Case__c = templateWrapper.caseId
                )
            );
        }
        return implementationsToCreate;
    }
    public class templateWrapper {
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Activity_Description { get; set; }
        @AuraEnabled
        public String Implementation_Type { get; set; }
        @AuraEnabled
        public Boolean shouldBeCreated { get; set; }
        @AuraEnabled
        public String assignee { get; set; }
        @AuraEnabled
        public Date startDate { get; set; }
        @AuraEnabled
        public Date endDate { get; set; }
        @AuraEnabled
        public String caseId { get; set; }

        public templateWrapper(Implementation__c implementation) {
            Name = implementation.Name;
            Activity_Description = implementation.Activity_Description__c;
            Implementation_Type = implementation.Implementation_Type__c;
            shouldBeCreated = false;
        }
    }
}