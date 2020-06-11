public with sharing class PreviewComponentController {
    @AuraEnabled(cacheable=true)
    public static list<ContentVersion> retriveFilesFromControlledDocumentsById(String taskId){
        List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE Id =:taskId];
        Set<Id> ids = new Set<Id>();
        for (Task ts: tasks) {
            ids.add(ts.WhatId);
        }
        List<ContentDocumentLink> cdList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN
                                                ( SELECT Id FROM Simploud__Controlled_Document__c WHERE Id IN: ids)];
        Set<Id> ids1 = new Set<Id>();
        for (ContentDocumentLink cdl: cdList) {
            ids1.add(cdl.ContentDocumentId);
        }
        return [SELECT Id, Title, FileExtension, ExternalDocumentInfo1, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : ids1];

    }


    @AuraEnabled(cacheable=true)
    public static List<Simploud__Controlled_Document__c> getControlledDocumentsById(String taskId){
        List<Task> tasks = [SELECT WhatId, Id, ActivityDate, Status FROM Task WHERE Id =:taskId];
        Set<Id> ids = new Set<Id>();
        for (Task ts: tasks) {
            ids.add(ts.WhatId);
        }
        List<Simploud__Controlled_Document__c> cdList = [SELECT Id,Simploud__Document_Type__c, Simploud__Effective_Date__c,
                                                     Simploud__Periodic_Review_Cycle_months__c,
                                                     Simploud__Periodic_Review_Notification_days__c, Internal_External__c,Simploud__Version__c, Have_you_added_settings_and_questions__c
                                                     FROM Simploud__Controlled_Document__c
                                                     WHERE Id IN: ids];
        return cdList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Simploud__Training_Material__c> getTrainingMaterialsById(String taskId){
        List<Task> tasks = [SELECT WhatId, Id, ActivityDate, Status FROM Task WHERE Id =:taskId];
        Set<Id> ids = new Set<Id>();
        for (Task ts: tasks) {
            ids.add(ts.WhatId);
        }
        List<Simploud__Training_Material__c> listTm = [SELECT Id,Did_you_check_all_modules_are_EFFECTIVE__c, Name,Stream__c,Category__c,Simploud__Type__c,Training_Content_List__c, Simploud__Location__c,Simploud__Date_Closed__c, Course_length_hours__c
                                                       FROM Simploud__Training_Material__c
                                                       WHERE Id IN: ids];
        return listTm;
    }


    @AuraEnabled(cacheable=true)
    public static list<ContentVersion> retriveFilesFromTrainingMtById(String taskId){
        List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE Id =:taskId];
        Set<Id> ids = new Set<Id>();
        for (Task ts: tasks) {
            ids.add(ts.WhatId);
        }
        List<ContentDocumentLink> cdList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN
                                                ( SELECT Id FROM Simploud__Training_Material__c WHERE Id IN: ids)];
        Set<Id> ids1 = new Set<Id>();
        for (ContentDocumentLink cdl: cdList) {
            ids1.add(cdl.ContentDocumentId);
        }
        return [SELECT Id, Title, FileExtension, ExternalDocumentInfo1, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN : ids1];

    }



}
