@isTest
class PrepareSandboxTest {

    private final static String SANDBOX_NAME = 'sbx';

    @isTest
    static void runApexClass_should_work() {
        Test.startTest();
        Test.testSandboxPostCopyScript(
            new PrepareSandbox(),
            UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(),
            SANDBOX_NAME
        );
        Test.stopTest();
    }
}