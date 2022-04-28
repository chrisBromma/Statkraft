/****************************************************************************************************
     	* Class msCSVtoSObjectRecordsConverterActionTest
     	*
     	*   Create By	:   MandyBebenroth (mindsquare GmbH)
     	*   Create Date	:   08.09.2020
     	*   Description	:	---
     	*
     	*   Modification Log:
    	*   -------------------------------------------------------------------------------------------------
    	*   * Developer                        	Date             	Description
    	*   * -----------------------------------------------------------------------------------------------                 
    	*   * MandyBebenroth (mindsquare GmbH)		08.09.2020       	Init version.
    	*****************************************************************************************************/
@IsTest
public class msCSVtoSObjectRecordsConverterActionTest {

    @TestSetup
    static void createData() {

        ContentVersion cv = new ContentVersion(
                Title = 'Demo Accounts CSV',
                VersionData = createCSVBlob(),
                PathOnClient = 'DemoAccounts.csv'
        );
        insert cv;
    }

    @IsTest
    static void testCsvToSObjectsRecordsConverterMethodExceptions() {
        msCSVtoSObjectRecordsConverterAction.ActionInput[] flowInputs = createFlowInputsList();

/* 1. FlowInput list size more than 1 exception
 */
        try {
            msCSVtoSObjectRecordsConverterAction.ActionInput input = new msCSVtoSObjectRecordsConverterAction.ActionInput();
            flowInputs.add(input);
            msCSVtoSObjectRecordsConverterAction.ActionOutput[] flowOutputs = msCSVtoSObjectRecordsConverterAction.csvToSObjectsRecordsConverter(flowInputs);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('This action is only supported in Screen flows.'));
        }
    }

    @IsTest
    static void testCsvToSObjectsRecordsConverterMethod() {

        msCSVtoSObjectRecordsConverterAction.ActionInput[] flowInputs = createFlowInputsList();
        Test.startTest();
        msCSVtoSObjectRecordsConverterAction.ActionOutput[] flowOutputs = msCSVtoSObjectRecordsConverterAction.csvToSObjectsRecordsConverter(flowInputs);
        Test.stopTest();
        System.assert(flowOutputs[0].records.size() == 3);
    }

    @IsTest
    static void testGetFieldTypeMethodException() {
        try {
            msCSVtoSObjectRecordsConverterAction.getFieldType(Schema.SObjectType.Account.fields.getMap(), 'TestField');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid Field Error'));
        }
    }

    static Blob createCSVBlob() {
        String csvStringContent;
        Blob csvBlobContent;
        String[] fields = new String[]{
                'AccountNumber',
                'AnnualRevenue',
                'NumberOfEmployees',
                'Rating',
                'Name'
        };

        String csvHeader = String.join(fields, ',') + '\n';
        csvStringContent = csvHeader;

        Account[] accRecords = new Account[]{
                new Account(Name = 'CSV Acc1', AnnualRevenue = null, AccountNumber = '', NumberOfEmployees = null, Rating = 'Hot'),
                new Account(Name = 'CSV Acc2', AnnualRevenue = 1000, AccountNumber = '911', NumberOfEmployees = 0, Rating = 'Warm'),
                new Account(Name = 'CSV Acc3', AnnualRevenue = 911007, AccountNumber = '007', NumberOfEmployees = 10, Rating = 'Cold')
        };

        for (Integer i = 0; i < accRecords.size(); i++) {
            Account a = accRecords[i];
            for (Integer j = 0; j < fields.size(); j++) {
                String field = fields[j];
                csvStringContent = csvStringContent + (a.get(field) == null ? '' : a.get(field));
                if (j < fields.size() - 1) {
                    csvStringContent += +',';
                }
            }
            if (i < accRecords.size() - 1) {
                csvStringContent += '\n';
            }
        }
        return Blob.valueOf(csvStringContent);
    }

    static msCSVtoSObjectRecordsConverterAction.ActionInput[] createFlowInputsList() {
        String contentDocumentId;
        ContentVersion cv = [
                SELECT ContentDocumentId,FileType
                FROM ContentVersion
                WHERE Title = 'Demo Accounts CSV'
        ];
        msCSVtoSObjectRecordsConverterAction.ActionInput[] flowInputs = new msCSVtoSObjectRecordsConverterAction.ActionInput[]{
        };
        msCSVtoSObjectRecordsConverterAction.ActionInput input = new msCSVtoSObjectRecordsConverterAction.ActionInput();
        input.objectApiName = 'Account';
        input.contentDocumentId = cv.ContentDocumentId;
        flowInputs.add(input);

        return flowInputs;
    }


}