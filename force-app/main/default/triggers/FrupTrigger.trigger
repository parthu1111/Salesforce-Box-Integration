trigger FrupTrigger on box__FRUP__c (after insert,after update,before insert,before update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            FrupTriggerHandler.afterInsert(Trigger.new);
        }
    }
}