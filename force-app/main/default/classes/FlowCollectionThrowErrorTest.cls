@IsTest
public without sharing class FlowCollectionThrowErrorTest {
    @IsTest
    public static void FlowCollectionThrowErrorTest() {
        String errorMessage = 'Test Error';
        String resultingErrorMessage;
        try {
            FlowCollectionThrowError.throwError(new List<String>{errorMessage});
        } catch (Exception e) {
            resultingErrorMessage = e.getMessage();
        }
        System.assertEquals(errorMessage, resultingErrorMessage);
    }
}