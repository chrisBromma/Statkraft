@IsTest
public with sharing class UnitOfWorkSingletonTest {
    @IsTest
    public static void shouldReturnInstance() {
        fflib_SObjectUnitOfWork instance = UnitOfWorkSingleton.getInstance();

        System.assert(instance != null, 'There was no instance created.');
    }
}