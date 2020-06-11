trigger TriggerUploadFileToSP on ContentVersion (after delete,
                                                 after insert, 
                                                 after undelete, 
                                                 after update,
                                                 before delete, 
                                                 before insert, 
                                                 before update) {
  FileUploadToSPTriggerHelper.handleTrigger(
    Trigger.old, 
    Trigger.new, 
    Trigger.oldMap, 
    Trigger.newMap, 
    Trigger.operationType);

}





