trigger TrialItemCustomTrigger on Simploud__Trial_Item__c ( before insert) {

    
    if (Trigger.isBefore)    
    {
        for(Simploud__Trial_Item__c ti : Trigger.new)
        {
            List<Simploud__Trial_Item__c> existItems =  [SELECT id FROM Simploud__Trial_Item__c 
                            WHERE simploud__Trial__c =: ti.Simploud__Trial__c AND Client_Document__c != null AND Client_Document__c =: ti.Client_Document__c ];
            if (existItems.size() > 0)
            {
              ti.addError('This documnet already exist for this trial');
            }
            
        }
    }
}