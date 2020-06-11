trigger DocumentLinkCustomTrigger on ContentDocumentLink (before delete) {
    
    for (ContentDocumentLink cdl : Trigger.old)
    {
        List<ContentDocument> contentDocument = [SELECT id,Title FROM ContentDocument WHERE id = : cdl.ContentDocumentId];
        
        try{
            if (contentDocument.size()>0)
            {
                Simploud__Audit_Trail__c auditTrailToInsert = new Simploud__Audit_Trail__c();
                auditTrailToInsert.Simploud__ParentId__c = cdl.LinkedEntityId;
                auditTrailToInsert.Simploud__Activity__c = 'File Removed';
                auditTrailToInsert.Simploud__Field__c = 'Attached File';
                auditTrailToInsert.Simploud__Type__c = 'FILE';
                auditTrailToInsert.Simploud__OldValue__c = contentDocument[0].Title;
                
                
                insert auditTrailToInsert;                
                system.debug('auditTrailToInsert'+auditTrailToInsert);            
            }            
        }
        catch(exception ex)
        {
            cdl.addError('Cant add audit trail ' + ex);
        }
        
    }
}