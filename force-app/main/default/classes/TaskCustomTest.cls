@isTest
private class TaskCustomTest {
    @isTest static void taskCustomTriggerTest(){
        Simploud__Training_Material__c record1 = new Simploud__Training_Material__c(
            Name = 'TestTM1',
            Trainer__c = UserInfo.getUserId()
        );
        insert record1;
        
        Simploud__Training_Material__c record2 = new Simploud__Training_Material__c(
            Name = 'TestTM2',
            Course__c = record1.Id
        );
        insert record2;
        
        Task task_i = new Task();
        task_i.Subject = 'Test Task';
        task_i.WhatId = record2.Id;
        task_i.Simploud__Training_Task__c = true;
        insert task_i;
        
        List<Task> taskList = [Select Id from Task Where Simploud__TaskType__c = 'General/Training'];
         //System.assertEquals(2,taskList.size());
        
        Simploud__Quality_Event__c record3 = new Simploud__Quality_Event__c(
            Name = 'TestQM1'
        );
        insert record3;

        Task task_j = new Task();
        task_j.Subject = 'Test Task2';
        task_j.WhatId = record3.Id;
        insert task_j;
        taskList = [Select Id from Task Where Simploud__TaskType__c = 'General/Training'];
         //System.assertEquals(3,taskList.size());
    }
    

}