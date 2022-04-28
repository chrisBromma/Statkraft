@isTest
public with sharing class FlowSplitStringTest {
    @isTest

   static void testStringSplit(){
       FlowSplitString.Input inputParameter = new FlowSplitString.Input();
       inputParameter.text ='Statkraft;Stat;kraft';
       inputParameter.separator =';';
       List<FlowSplitString.Input> inputParameterList = new List<FlowSplitString.Input>{inputParameter};
       List<List<String>> resultWrapper = FlowSplitString.stringSplit(inputParameterList);
       List<String> result = resultWrapper.get(0);
       system.assert(result.size() ==3, 'There should be 3 elements resulting ' + result);
       system.assert(result.get(0) =='Statkraft', 'First element should be  Statkraft ' + result);
       system.assert(result.get(1) =='Stat', 'Second element should be Stat ' + result);
       system.assert(result.get(2) =='kraft', 'Third element should be kraft ' + result);
       inputParameter.text ='Statkraft';
       inputParameter.separator =';';
       inputParameterList.clear();
       inputParameterList.add(inputParameter);
       resultWrapper = FlowSplitString.stringSplit(inputParameterList);
       result = resultWrapper.get(0);
       system.assert(result.get(0) =='Statkraft', ' no error expected ' + result);
   }

   @isTest
   static void testStringSplitAndClear(){
       FlowSplitString.Input inputParameter = new FlowSplitString.Input();
       inputParameter.text ='[Statkraft;Stat;kraft]';
       inputParameter.separator =';';
       List<FlowSplitString.Input> inputParameterList = new List<FlowSplitString.Input>{inputParameter};
       List<List<String>> resultWrapper = FlowSplitString.stringSplit(inputParameterList);
       List<String> result = resultWrapper.get(0);
       system.assert(result.size() ==3, 'There should be 3 elements resulting ' + result);
       system.assert(result.get(0) =='Statkraft', 'First element should be Statkraft ' + result);
       system.assert(result.get(1) =='Stat', 'Second element should be Stat ' + result);
       system.assert(result.get(2) =='kraft', 'Third element should be kraft ' + result);
   }
}