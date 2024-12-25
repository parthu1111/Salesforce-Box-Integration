public with sharing class FrupTriggerHandler {


    public static void afterInsert(List<box__FRUP__c> newFrups) {
        
        List<string> ids=new List<string>();
        for(box__FRUP__c frup:newFrups){
            ids.add(frup.Id);
        }
        boxFormHelperMethods.moveFilesToLoanFolder(ids);
    }
}