trigger ControlledDocumentCustomTrigger on Simploud__Controlled_Document__c (after insert,before insert, before update,after update) {
    if(Trigger.isBefore) {
        if (Trigger.isUpdate ) {
            ControlledDocumentCustomTriggerHelper.beforeUpdateTriggerHandler(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert) {
            ControlledDocumentCustomTriggerHelper.beforeInsertTriggerHandler(Trigger.new);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            ControlledDocumentCustomTriggerHelper.afterUpdateTriggerHandler(Trigger.newMap, Trigger.oldMap );
        }

        if(Trigger.isInsert) {
            ControlledDocumentCustomTriggerHelper.afterInsertTriggerHandler(Trigger.new);
        }
    }

}
