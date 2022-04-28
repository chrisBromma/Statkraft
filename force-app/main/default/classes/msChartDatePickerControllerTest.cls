/****************************************************************************************************
* Class msChartDatePickerControllerTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-10-11
*   Description	:	Test class for the msChartDatePickerController class
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-10-11       	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msChartDatePickerControllerTest {
    @IsTest
    public static void convertTest() {
        Date testDate = Date.today();
        msChartDatePickerController.convertSelectedDates(testDate,0,0,testDate,0,0,'Europe/Berlin');
    }

}