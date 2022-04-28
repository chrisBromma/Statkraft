/****************************************************************************************************
 * Class msNPAIStandardImplementationTest
 *
 *   Created By :   Fabian Murk (mindsquare AG)
 *   Create Date :   03.05.2021
 *   Description :
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        Date             Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)      03.05.2021         Init version.
 *****************************************************************************************************/
@IsTest
public without sharing class msNPAIStandardImplementationTest {
    @TestSetup
    public static void testSetup() {
        Implementation__c implementation = new Implementation__c(
            Name = 'testImplementation',
            Activity_Description__c = 'testDescription',
            Implementation_Type__c = 'Before Operational Readiness',
            RecordTypeId = msNPAIStandardImplementationController.STANDARD_IMPLEMENTATION_TEMPLATE
        );
        insert implementation;

        NPC_Cases__c npcCase = new NPC_Cases__c(Name = 'testCase');
        insert npcCase;
    }
    @IsTest
    public static void testGetImplementationTemplates() {
        Test.startTest();
        List<msNPAIStandardImplementationController.templateWrapper> templateWrappers = msNPAIStandardImplementationController.getImplementationTemplates();
        Test.stopTest();

        System.assertEquals('testImplementation', templateWrappers[0].Name);
    }
    @IsTest
    public static void testCreateStandardImplementations() {
        Implementation__c implementation = [
            SELECT Name, Activity_Description__c, Implementation_Type__c
            FROM Implementation__c
            WHERE RecordTypeId = :msNPAIStandardImplementationController.STANDARD_IMPLEMENTATION_TEMPLATE
        ];
        List<msNPAIStandardImplementationController.templateWrapper> templateWrappers = new List<msNPAIStandardImplementationController.templateWrapper>();
        msNPAIStandardImplementationController.templateWrapper templateWrapper = new msNPAIStandardImplementationController.templateWrapper(
            implementation
        );
        templateWrapper.assignee = UserInfo.getUserId();
        templateWrappers.add(templateWrapper);

        Test.startTest();
        msNPAIStandardImplementationController.createStandardImplementations(JSON.serialize(templateWrappers));
        Test.stopTest();

        Implementation__c createdImplementation = [
            SELECT Name
            FROM Implementation__c
            WHERE RecordTypeId != :msNPAIStandardImplementationController.STANDARD_IMPLEMENTATION_TEMPLATE
        ];
        System.assert(createdImplementation != null);
        System.assertEquals(implementation.Name, createdImplementation.Name);
    }
}