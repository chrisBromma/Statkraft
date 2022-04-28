/****************************************************************************************************
* Class msBatchDeleteUnconnectedFilesTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-09-02
*   Description	:	Test class for the Apex class msBatchDeleteUnconnectedFiles
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-09-02       	Init version.
*****************************************************************************************************/
@IsTest
private without sharing class msBatchDeleteUnconnectedFilesTest {
    @TestSetup
    private static void setup() {
        ContentVersion newCV = new ContentVersion();
        newCV.Title='ABC';
        newCV.PathOnClient ='test';
        newCV.msUploadedByDocumentManagerCmp__c = true;
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        newCV.VersionData=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert newCV;
    }
    @IsTest
    private static void deleteTest() {
        Test.startTest();
        Database.executeBatch(new msBatchDeleteUnconnectedFiles(), 200);
        Test.stopTest();
        List<ContentDocument> allCD = [SELECT Id FROM ContentDocument WHERE IsDeleted = FALSE];
        System.assertEquals(0,allCD.size());
    }
}