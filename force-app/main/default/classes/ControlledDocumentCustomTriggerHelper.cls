public with sharing class ControlledDocumentCustomTriggerHelper {

    public static void beforeUpdateTriggerHandler(List<Simploud__Controlled_Document__c > triggerNew,  Map<Id, Simploud__Controlled_Document__c> oldMap ){
        Set<Id> cdIds = new Set<Id>();
        for (Simploud__Controlled_Document__c cd:triggerNew) {
            cdIds.add(cd.id);
        }
        List<ContentDocumentLink> documentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId
                                                  FROM ContentDocumentLink
                                                  WHERE LinkedEntityId =: cdIds];
        
        for (Simploud__Controlled_Document__c cd:triggerNew) {
            String newStatus = cd.Simploud__Status__c;
            String oldStatus = (String)oldMap.get(cd.Id).get('Simploud__Status__c');
            Decimal newVersion = cd.Record_Version__c;
            Decimal oldVersion = (Decimal)oldMap.get(cd.Id).get('Record_Version__c');
            Decimal newVersion2 = cd.Record_Version__c;
            Decimal oldVersion2 = (Decimal)oldMap.get(cd.Id).get('Simploud__Version__c');
            String newName = cd.Name;
            if(newStatus == 'Approved'){
                cd.Approved_Date_Time__c = Datetime.now();
            }

            if(newStatus == 'Effective'){
                cd.Effective_Date_Time__c  = Datetime.now();
            }

            if(newStatus!=oldStatus && newStatus =='Effective' && (oldStatus=='Approved' || oldStatus=='Obsolete') && newVersion2==oldVersion) { 
                cd.Record_Version__c = cd.Record_Version__c+1.0;
                cd.Simploud__Version__c = Integer.valueOf(cd.Record_Version__c);
            }

           
            
            //String oldStatus = (String).oldMap.get(cd.Id).get('Simploud__Status__c');
            // if (newStatus !=oldStatus && muq.isProgress == true) {
            //     cd.addError('The process of updating files metadata in Sharepoint is not yet finished, it can take up to few minutes, you will be able to change status when it is completed.');
            // }
            if (newStatus !=oldStatus && newStatus !='Cancelled'  && newStatus !='Obsolete') {
                try
                {
                    if (documentLinks.isEmpty())
                    {
                        cd.addError('You need to attach a file before submitting the document for review');
                    }

                } catch(exception e) {
                    cd.addError('You need to attach a file before submitting the document for review');

                }

            }
        }
    }


    public static void beforeInsertTriggerHandler(List<Simploud__Controlled_Document__c> triggerNew ){
        for (Simploud__Controlled_Document__c cd:triggerNew) {
            String documentType = cd.Simploud__Document_Type__c;
            Integer counter = [Select Count() from Simploud__Controlled_Document__c where Simploud__Document_Type__c =: documentType and Simploud__Previous_Version__c != null];
            Simploud__Compliance_Configuration__c conf = new Simploud__Compliance_Configuration__c();
            conf.Simploud__Document_Type__c = documentType;
            conf.Simploud__Document_Type_Index__c = counter + 1;
            List<Simploud__Compliance_Configuration__c> cdl = new List<Simploud__Compliance_Configuration__c>();
            cdl = [Select Id,Simploud__Document_Type__c,Simploud__Document_Type_Index__c from Simploud__Compliance_Configuration__c where Simploud__Document_Type__c =: documentType];
            if (!cdl.isEmpty())
                conf = cdl[0];
            if (cd.Simploud__Previous_Version__c == null)
                cd.Document_Type_ID1__c = String.valueOf(conf.Simploud__Document_Type_Index__c++).leftPad(5, '0');
            upsert conf;
        }
    }

    public static void afterUpdateTriggerHandler(List<Simploud__Controlled_Document__c> triggerNew, Map<Id, Simploud__Controlled_Document__c> newMap, Map<Id, Simploud__Controlled_Document__c> oldMap ){
        List<Simploud__Controlled_Document__c> idsToUpdate = new List<Simploud__Controlled_Document__c>();
        for (Simploud__Controlled_Document__c cd:triggerNew) {
            String newStatus = cd.Simploud__Status__c;
            String oldStatus = (String)oldMap.get(cd.Id).get('Simploud__Status__c');
            String newName=cd.Name;
            String oldName=(String)oldMap.get(cd.Id).get('Name');
            if(newStatus!=oldStatus || newName!=oldName  )
                idsToUpdate.add(cd);
            if(idsToUpdate.size()!=0) {
                System.enqueueJob(new MetadataUpdateQueuebale(newMap, oldMap));
            }

        }
    }

    public static void afterInsertTriggerHandler(List<Simploud__Controlled_Document__c> triggerNew ){
        List<Simploud__Controlled_Document__c> idsToUpdate = new List<Simploud__Controlled_Document__c>();
        List<Simploud__Controlled_Document__c> cdOld=[SELECT Id, Name,Record_Version__c, Simploud__Document_Type__c, Simploud__Version__c,
                                                      Simploud__Status__c,Internal_External__c,CheckDockType__c,Simploud__Previous_Version__c,Queueable_In_Pro__c
                                                      FROM Simploud__Controlled_Document__c WHERE Id in:idsToUpdate];
        for (Simploud__Controlled_Document__c cd:triggerNew) {
            if (cd.Simploud__Status__c == 'Draft') {
                if(cd.Simploud__Previous_Version__c != null) {
                    idsToUpdate.add(cd);
                    System.enqueueJob(new SharePointVersionControlQueueable(cd));
                }
            }
        }
        for(Simploud__Controlled_Document__c cdOb: cdOld) {
            cdOb.CheckDockType__c = **99*;
        }
        update cdOld;
    }

}
