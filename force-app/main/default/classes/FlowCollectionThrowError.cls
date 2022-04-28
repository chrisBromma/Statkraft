global without sharing class FlowCollectionThrowError {
    @InvocableMethod(
        category='Exceptions'
        label='Throw an Exception'
        description='Throw an Exception with a custom message from your flow'
    )
    global static void throwError(List<String> errorMessage) {
        throw new applicationException(errorMessage[0]);
    }
    global class applicationException extends Exception {}
}