trigger TrialCustomTrigger on Simploud__Trial__c (after insert, before update) {
    Set<String> whatIdSetIRT = new Set<String>();
    List<Task> taskListOld = new List<Task>();
    List<Task> taskListNew = new List<Task>();
    List<User> userList = [Select Id from User where CT_User__c = TRUE];
    String recordTypeIRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('IRT Access').getRecordTypeId();
    
    for (Simploud__Trial__c trial : trigger.new)
    {
        //
        if (trial.IRT_Access_Req_d__c == 'Yes')
        {
            whatIdSetIRT.add(trial.Id);
        }
    }  
    if (whatIdSetIRT.size()>0 && userList.size() > 0)
    {
        taskListOld = [Select Id,WhatId,OwnerId,Status FROM Task WHERE WhatId IN: whatIdSetIRT AND RecordTypeId =: recordTypeIRT ORDER BY WhatId];
        for (String trialId : whatIdSetIRT)
        {
            
            for (User user_i : userList)
            {
                Task task_i = new Task();
                task_i.WhatId = trialId;
                task_i.OwnerId = user_i.Id;
                task_i.Status = 'Not Started';
                task_i.Subject = 'Obtain IRT Access';
                task_i.RecordTypeId = recordTypeIRT;
                if (taskListOld.size() >0)
                {
                    for (Task taskItem : taskListOld)
                    {
                        if (taskItem.OwnerId == user_i.Id && taskItem.WhatId == trialId)
                        {
                            task_i.Id = taskItem.Id;
                            task_i.Status = taskItem.Status;
                        }
                    }
                    
                }
                taskListNew.add(task_i);
                system.debug('Participant to add: ' + task_i);
            }
        }
        upsert taskListNew;
    }
    
    
    if (Trigger.isUpdate )
    {
        List<String> irtRequiredList = new List<String>{'Almac','Bracket','Bracket CUBE','Codebreak envelopes','eCRF','Endpoint','Firecrest',
            'Flex','Medidata RAVE','Open Label with Almac','Open Label with bracket','Open Label with endpoint',
            'Perceptive','Perceptive Envelope','s clinica','Suvoda','y-prime'};
        for (Simploud__Trial__c cd : trigger.new)
        {

            
            
            String newStatus = cd.Simploud__Status__c;
            system.debug('New status:'+newStatus);
            String oldStatus = (String)trigger.oldMap.get(cd.Id).get('Simploud__Status__c');
            system.debug('Old status:'+oldStatus);
            
           Boolean irtRequired = false;
            for (String irt : irtRequiredList)
            {
                if (cd.Unblinding_Method__c != null)
                {
                    if (cd.Unblinding_Method__c.contains(irt))
                    {
                        irtRequired = true; 
                    }
                }
            }
            if (newStatus == 'In Setup' && irtRequired)
            {
                cd.IRT_Access_Req_d__c = 'Yes';
            }
            else if (newStatus == 'In Setup' && !irtRequired)
            {
                cd.IRT_Access_Req_d__c = 'No';
            }
            
            
            //
            if (newStatus !=oldStatus && newStatus =='Live' && (cd.Override_Document_Check__c == 'No' || cd.Override_Document_Check__c == null))
            {
                try
                {
                    List<String> docTypes = new List<String> ();
                    Set<String> itemTypes = new Set<String> ();
                    if (cd.Document_Types_Needed__c != null)
                    {
                        docTypes = cd.Document_Types_Needed__c.split(';');
                    }
                    system.debug('docTypes :'+docTypes );
                    
                    List<Simploud__Trial_Item__c> itemDocs = new  List<Simploud__Trial_Item__c>();
                    itemDocs = [SELECT Id, Document_Type__c 
                                FROM Simploud__Trial_Item__c 
                                WHERE Simploud__Trial__c =: cd.Id];
                    if (itemDocs.size() > 0)
                    {
                        system.debug('itemDocs:' + itemDocs); 
                        for (Simploud__Trial_Item__c ti : itemDocs)
                        {
                            if (ti.Document_Type__c != null)
                            {
                                itemTypes.add(ti.Document_Type__c);
                            }
                        }
                        system.debug('itemTypes:'+ itemTypes);
                    }
                    
                    String missingTypes = '';
                    
                    for (String docType : docTypes)
                    {
                        if (!itemTypes.contains(docType))
                            missingTypes = missingTypes + docType + ';';
                    }
                    
                    if (missingTypes != '')
                    {
                        cd.addError('The following document types are missing in order to start the trial: '+missingTypes); 
                    }
                    
                    
                    
                } catch(exception e) {
                    cd.addError('You need to link all the controlled documents needed in order to start the trial');
                }
            }
            
        }
    }
    
}