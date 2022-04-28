/****************************************************************************************************
* Class msCurtailmentsMockTest
*
*   Create By	:   FlorianPusse (mindsquare GmbH)
*   Create Date	:   FlorianPusse
*   Description	:	TODO: Insert Description
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * FlorianPusse (mindsquare GmbH)		28.03.2019       	Init version.
*****************************************************************************************************/

@IsTest
public with sharing class msCurtailmentsMockTest {


    @IsTest
    public static void testCreateCurtailments(){
        String curtailments = msCurtailmentsMock.createCurtailments('{"names": ["/as_fr_dummy_wind_park/regulation/power/ems/default"],"begin": "2018-02-28T01:00:00Z","end": "2019-04-03T14:13:29Z"}', Datetime.now());
    }
}