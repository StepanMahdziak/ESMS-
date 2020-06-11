trigger GeneralDocumentCustomTrigger on Simploud__General_Document__c (before update,after update) {
    
    for (Simploud__General_Document__c cd:trigger.new)
    {
        
        String newStatus = cd.Simploud__Status__c;
        system.debug('New status:'+newStatus);
        String oldStatus = (String)trigger.oldMap.get(cd.Id).get('Simploud__Status__c');
        system.debug('Old status:'+oldStatus);
        
        List<ContentDocumentLink> documentLinks = new List< ContentDocumentLink>();
        if (newStatus !=oldStatus && newStatus =='Uploaded')
        {
            try
            {
                documentLinks = [SELECT ID, ContentDocumentId, LinkedEntityId
                                 FROM ContentDocumentLink
                                 WHERE LinkedEntityId =: cd.Id];
                system.debug('Size:' + documentLinks.size());
                if (documentLinks.isEmpty())
                {
                    cd.addError('You need to attach a file before releasing the document');
                }
                
            } catch(exception e) {
                cd.addError('You need to attach a file before releasing the document');
                
            }
        }
        
    }
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            for(Simploud__General_Document__c gd:trigger.new){
                System.enqueueJob(new MetadataUpdateQueuebale(gd));
            }
        }
    }
    
}