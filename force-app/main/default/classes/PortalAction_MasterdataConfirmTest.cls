/**
 * Created by georgluch on 22.09.21.
 */

@IsTest
private class PortalAction_MasterdataConfirmTest {

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest static void testMasterdata_confirmation() {
        msUtility.throwFakeException = false;

        Test.startTest();
        System.enqueueJob(new PortalAction_MasterdataConfirmInit());
        Test.stopTest();
    }

    @IsTest static void testMasterdata_confirmation_reminder() {
        msUtility.throwFakeException = false;

        Test.startTest();
        System.enqueueJob(new PortalAction_MasterdataConfirmReminder());
        Test.stopTest();
    }

    @IsTest
    static void executeTest() {
        Exception caughtException;

        Test.startTest();
        try {
            new PortalAction_MasterdataConfirmInit().execute((QueueableContext) null);
        } catch (Exception e) {
            caughtException = e;
        }

        Test.stopTest();
    }
}