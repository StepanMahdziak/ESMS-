trigger TaskCustomTrigger on Task (before insert,after insert) {
    
    List<Task> newTasks = new List<Task>();
    List<Simploud__Template_Item__c> formList = new  List<Simploud__Template_Item__c>();
    List<Simploud__Quality_Event__c> qeList = new List<Simploud__Quality_Event__c> ();
    List<Simploud__Training_Material__c> tmList = new List<Simploud__Training_Material__c> ();
    Set<String> whatIdSet = new Set<String>();
    for (Task taskId: Trigger.new) {
        if (taskId.Simploud__TaskType__c == 'General/Training' )
        {
            whatIdSet.add(taskId.WhatId);
        }
    }
    tmList = [Select Id, Name, Course__c, Template__c ,Simploud__Status__c, Trainer__c, No_Trainer__c From Simploud__Training_Material__c Where Id IN:whatIdSet or Course__c IN:whatIdSet];
    qeList = [Select Id, Template__c  From Simploud__Quality_Event__c Where Id IN:whatIdSet];
    if (!tmList.isEmpty())
    {
        for (Simploud__Training_Material__c tm : tmList)
        {
            for (Task task: Trigger.new) {
                
                if (Trigger.isBefore && tm.Id == task.WhatId)
                {
                    task.Subject = tm.Name;
                }
                if ( Trigger.isAfter && tm.Course__c == task.WhatId && tm.Simploud__Status__c != 'Cancelled' && tm.Simploud__Status__c != 'Obsolete')
                {
                    Task newTask = new Task();
                    newTask.Subject = task.Subject;
                    newTask.ActivityDate = task.ActivityDate;
                    newTask.ownerId = task.OwnerId;
                    newTask.Priority = task.Priority;
                    newTask.WhatId = tm.Id;
                    newTask.RecordTypeId = task.RecordTypeId;
                    newTask.Simploud__TaskType__c = task.Simploud__TaskType__c;
                    newTask.Status = task.Status;
                    newTask.Simploud__Training_Task__c = true;
                    newTasks.add(newTask);
                }
                if (tm.Id == task.WhatId )
                {
                    if (tm.Template__c != null)
                    {
                        Simploud__Template_Item__c form_i = new Simploud__Template_Item__c();
                        form_i.Simploud__Parent_ID__c = task.Id;
                        form_i.Name = 'Task Checklist';
                        form_i.Simploud__Template__c = tm.Template__c;
                        formList.add(form_i);
                    }
                    if (tm.Trainer__c != null && Trigger.isBefore)
                    {
                        task.Trainer__c = tm.Trainer__c;
                    }
                    
                    if (tm.No_Trainer__c != null && Trigger.isBefore)
                    {
                        task.No_Trainer__c = tm.No_Trainer__c;
                    }
                }
            }
        }
        
        if (!newTasks.isEmpty() && Trigger.isAfter)
            insert newTasks;     
        
    }
    
    if (!qeList.isEmpty() )
    {
        for (Simploud__Quality_Event__c qe : qeList)
        {
            for (Task task: Trigger.new) {
                if (Trigger.isAfter && qe.Id == task.WhatId && qe.Template__c != null)
                {
                    Simploud__Template_Item__c form_i = new Simploud__Template_Item__c();
                    form_i.Simploud__Parent_ID__c = task.Id;
                    form_i.Name = 'Investigation Checklist';
                    form_i.Simploud__Template__c = qe.Template__c;
                    formList.add(form_i);
                    
                    system.debug('Form_i' + form_i);
                }
                if (Trigger.isBefore && qe.Id == task.WhatId && qe.Template__c != null)
                {
                    task.No_Trainer__c = true;
                }
                
            }
        }
    }
    
    if (!formList.isEmpty() && Trigger.isAfter)
        insert formList;  

    
  
    
}