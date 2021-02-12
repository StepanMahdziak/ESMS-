public with sharing class ControlledDocumentCustomTriggerHelper {
    CustomMetadataWrapper metWrapper;
    //method for setting date on some Statuses
    public static void beforeUpdateTriggerHandler(List<Simploud__Controlled_Document__c > triggerNew,  Map<Id, Simploud__Controlled_Document__c> oldMap ){
        Set<Id> controlDocsIds = new Set<Id>();
        for (Simploud__Controlled_Document__c controlDocs:triggerNew) {
            controlDocsIds.add(controlDocs.id);
        }
        List<ContentDocumentLink> documentLinks = [SELECT Id, ContentDocumentId, LinkedEntityId
                                                   FROM ContentDocumentLink
                                                   WHERE LinkedEntityId =: controlDocsIds];

        for (Simploud__Controlled_Document__c controlDocs:triggerNew) {
            String newStatus = controlDocs.Simploud__Status__c;
            String oldStatus = (String)oldMap.get(controlDocs.Id).get('Simploud__Status__c');
            Decimal newVersion = controlDocs.Record_Version__c;
            Decimal oldVersion = (Decimal)oldMap.get(controlDocs.Id).get('Record_Version__c');
            Decimal newVersion2 = controlDocs.Record_Version__c;
            Decimal oldVersion2 = (Decimal)oldMap.get(controlDocs.Id).get('Simploud__Version__c');
            String newName = controlDocs.Name;
            if(newStatus == 'Review') {
                controlDocs.SP_SF_Owner_Date__c = Datetime.now().format('dd MMM yyyy');
                controlDocs.Author_Date__c = Datetime.now().format('dd MMM yyyy');
            }
            if(newStatus == 'Draft Approval') {
                controlDocs.Review_Date_Time__c = Datetime.now();
                controlDocs.SF_SP_Review_Date__c = Datetime.now().format('dd MMM yyyy');
            }
            if(newStatus == 'Approved') {
                controlDocs.Approved_Date_Time__c = Datetime.now();
                controlDocs.SF_SP_Approver_Date__c = Datetime.now().format('dd MMM yyyy');
            }
            if(newStatus == 'Effective') {
                controlDocs.Effective_Date_Time__c  = Datetime.now();
                // controlDocs.SF_SP_Effective_Date_Time__c = Datetime.now().format('dd MMM yyyy h:mm a');
                controlDocs.SF_SP_Effective_Date_Time__c = Datetime.now().format('dd MMM yyyy');
                controlDocs.Next_Review_Date__c = Datetime.now().addYears(2).format('dd MMM yyyy');
            }
            if(newStatus!=oldStatus && newStatus =='Effective' && (oldStatus=='Approved' || oldStatus=='Obsolete') && newVersion2==oldVersion) {
                controlDocs.Record_Version__c = controlDocs.Record_Version__c+1.0;
                controlDocs.Simploud__Version__c = Integer.valueOf(controlDocs.Record_Version__c);

            }
            //String oldStatus = (String).oldMap.get(controlDocs.Id).get('Simploud__Status__c');
            // if (newStatus !=oldStatus && muq.isProgress == true) {
            //     controlDocs.addError('The process of updating files metadata in Sharepoint is not yet finished, it can take up to few minutes, you will be able to change status when it is completed.');
            // }
            if (newStatus !=oldStatus && newStatus !='Cancelled'  && newStatus !='Obsolete') {
                try
                {
                    if (documentLinks.isEmpty())
                    {
                        controlDocs.addError('You need to attach a file before submitting the document for review');
                    }

                } catch(exception e) {
                    controlDocs.addError('You need to attach a file before submitting the document for review');

                }

            }
        }
    }

    //method for reset value on some fields when new ContentVerion will be created
    public static void beforeInsertTriggerHandler(List<Simploud__Controlled_Document__c> triggerNew ){
        for (Simploud__Controlled_Document__c controlDocs:triggerNew) {
            if(controlDocs.Simploud__Previous_Version__c != null || Test.isRunningTest()) {
                controlDocs.Obs_Version__c = controlDocs.Record_Version__c - 1.1;
                controlDocs.SF_SP_Review_Date__c = null;
                controlDocs.SP_SF_Owner_Date__c =  null;
                controlDocs.SF_SP_Approver_Date__c = null;
                controlDocs.SF_SP_Effective_Date_Time__c = null;
            }
            controlDocs.Created_By_Date__c = Datetime.now().format('dd MMM yyyy');
            String documentType = controlDocs.Simploud__Document_Type__c;
            Integer counter = [Select Count() from Simploud__Controlled_Document__c where Simploud__Document_Type__c =: documentType and Simploud__Previous_Version__c != null];
            Simploud__Compliance_Configuration__c conf = new Simploud__Compliance_Configuration__c();
            conf.Simploud__Document_Type__c = documentType;
            conf.Simploud__Document_Type_Index__c = counter + 1;
            List<Simploud__Compliance_Configuration__c> controlDocsl = new List<Simploud__Compliance_Configuration__c>();
            controlDocsl = [Select Id,Simploud__Document_Type__c,Simploud__Document_Type_Index__c from Simploud__Compliance_Configuration__c where Simploud__Document_Type__c =: documentType];
            if (!controlDocsl.isEmpty())
                conf = controlDocsl[0];
            if (controlDocs.Simploud__Previous_Version__c == null)
                controlDocs.Document_Type_ID1__c = String.valueOf(conf.Simploud__Document_Type_Index__c++).leftPad(5, '0');
            upsert conf;
        }
    }

    //method for updating all fields and will trigger when status has been changed
    public static void afterUpdateTriggerHandler( Map<Id, Simploud__Controlled_Document__c> newMap, Map<Id, Simploud__Controlled_Document__c> oldMap ){
        List<String> fieldsToUpdate = new List<String>();
        List<SharePointSettings__mdt> sharepointSettings = [SELECT DeveloperName,Folder_Title__c,Fields__c, Fields_to_update_in_trigger__c FROM SharePointSettings__mdt];
        String controlledDocsFields;
        for(SharePointSettings__mdt item:sharepointSettings) {
            if(item.DeveloperName == 'Controlled_Documents' ) {
                controlledDocsFields = item.Fields_to_update_in_trigger__c;
            }
        }
        List<String> customMetadataFields = controlledDocsFields.split(';');
        for (Id controlledDocsIds : newMap.keySet()) {
            for(String fields : customMetadataFields) {
                if(newMap.get(controlledDocsIds).get(fields) != oldMap.get(controlledDocsIds).get(fields))
                    fieldsToUpdate.add(fields);
            }
        }
        if(!fieldsToUpdate.isEmpty()) {
            System.enqueueJob(new MetadataUpdateQueuebale(newMap, oldMap));
        }
    }
    //method for calling SharePointVersionControlQueueable when press button 'Create Revision'
    public static void afterInsertTriggerHandler(List<Simploud__Controlled_Document__c> triggerNew ){
        for (Simploud__Controlled_Document__c controlDocs:triggerNew) {
            if (controlDocs.Simploud__Status__c == 'Draft') {
                if(controlDocs.Simploud__Previous_Version__c != null) {
                    System.enqueueJob(new SharePointVersionControlQueueable(controlDocs));
                }
            }
        }

    }


}