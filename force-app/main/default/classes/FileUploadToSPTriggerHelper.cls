public with sharing class FileUploadToSPTriggerHelper {
    public static void handleTrigger(List<ContentVersion> triggerOld, List<ContentVersion> triggerNew, Map<Id, ContentVersion> oldMap, Map<Id, ContentVersion> newMap, System.TriggerOperation triggerEvent) {
        switch on triggerEvent {
            when AFTER_INSERT {
                updateContentVersion(triggerNew);
            }
            // when AFTER_UPDATE {
            //}
            //when AFTER_DELETE {
            //}
        }
    }

    static void updateContentVersion(List<ContentVersion> triggerNew) {
        Set<Id> cdIds = new Set<Id>();
        Set<Id> cvIds = new Set<Id>();
        Set<Id> linkedEntityIds = new Set<Id>();
        for (ContentVersion cv : triggerNew) {
            cdIds.add(cv.ContentDocumentId);
            cvIds.add(cv.Id);
        }
        List<ContentVersion> cvToUpdate = [SELECT Id,Title FROM ContentVersion WHERE Id IN: cvIds];
        List<ContentDocumentLink> cdlToUpdate = [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdIds];

        for(ContentDocumentLink cdl: cdlToUpdate) {
            linkedEntityIds.add(cdl.LinkedEntityId);
        }
        List<Simploud__Controlled_Document__c> obj = [SELECT Id,Name,Record_Version__c, Simploud__Status__c,Simploud__Version__c FROM Simploud__Controlled_Document__c WHERE Id IN: linkedEntityIds];

        for(ContentDocumentLink cdl: cdlToUpdate) {
            String entityType = cdl.LinkedEntityId.getSobjectType().getDescribe().getLabelPlural();
            if(entityType != 'Users') {
                String docType = entityType.replace(' ','%20');
                if(docType == 'Controlled%20Documents') {
                    for(Simploud__Controlled_Document__c cd :obj ) {
                        if(cd.Simploud__Status__c != null) {
                            for(ContentVersion cv : cvToUpdate) {
                                cv.Title = cd.Name;
                                // cv.Title = cd.Name+' v'+Integer.valueof(cd.Record_Version__c)+' '+cd.Simploud__Status__c;
                            }
                        }
                    }
                }
            }
        }
        update cvToUpdate;
        //add coment to upload more tham one job
        System.enqueueJob(new SharePointFileQueueable(triggerNew));
    }

}