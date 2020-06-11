trigger TrainingMaterialCustomTrigger on Simploud__Training_Material__c (after update) {
   Set<String> parentIdSetIRT = new Set<String>();
    List<Simploud__Training_Material__c> tmList = new List<Simploud__Training_Material__c>();
    for (Simploud__Training_Material__c tm : trigger.new)
    {
        Simploud__Training_Material__c oldTM = Trigger.oldMap.get(tm.Id);
        String oldStatus = oldTM.Simploud__Status__c;
        if (tm.Simploud__Status__c != oldStatus && tm.Simploud__Status__c == 'Cancelled')
        {
            parentIdSetIRT.add(tm.Id);
        }
    }
    if (!parentIdSetIRT.isEmpty())
    tmList = [Select Id,Simploud__Status__c From Simploud__Training_Material__c WHERE Course__c IN: parentIdSetIRT];
    
    if (!tmList.isEmpty())
    {
        for (Simploud__Training_Material__c tm : tmList)
        {
            tm.Simploud__Update_Status__c = true;
            tm.Simploud__Update_Status_Comment__c = 'Parent was cancelled';
            tm.Simploud__Status__c = 'Cancelled';
        }
        update tmList;
    }
    
}