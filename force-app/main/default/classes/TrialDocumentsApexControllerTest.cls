@isTest
public class TrialDocumentsApexControllerTest {
   
    @isTest     
    public static void getDocumentListTest()
    {
       Simploud__Controlled_Document__c doc = new Simploud__Controlled_Document__c(
            Name = 'TestDoc1',
           Internal_External__c = 'External',
           Simploud__Document_Type__c = 'FAQ'           
        );
        insert doc;       
        system.debug('Doc ' + doc);
        
        ContentVersion newVersion = new ContentVersion(
            VersionData = EncodingUtil.base64Decode('Banana'),
            Title = 'Banana',
            PathOnClient  = 'Banana.docx'
        );
        insert newVersion;
        
        ContentDocument cd = [SELECT id from ContentDocument];
        system.debug('newVersion ' + cd.Id);        
                
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = doc.Id,
            ShareType = 'I'
        );   
        insert link;
        system.debug('link ' + link);
        
        Simploud__Trial__c testTrial = new Simploud__Trial__c(
            Name	  = 'TestTrial1',
            Trial_design__c = 'Open label',
            IMP__c = 'IMP11'
        );
        insert testTrial;
        system.debug('testTrial ' + testTrial);
        
        
        Simploud__Trial_Item__c testTrialItem = new Simploud__Trial_Item__c (
            Name = 'TestTrialItem1',
            Controlled_Document__c = doc.Id,
            Simploud__Trial__c = testTrial.Id
        );      
        insert testTrialItem;        
        system.debug('testTrialItem ' + testTrialItem);

   		String returnValue = TrialDocumentsApexController.getDocumentList(testTrial.Id);
                system.debug('returnValue1 ' + returnValue);
        
        Simploud__Training_Material__c tm = new Simploud__Training_Material__c(
            Name = 'TestTraining',
            Trial__c = testTrial.Id
        );
        insert tm;
        system.debug('TM: '+tm);
        
        Task trainTask = new Task();
        trainTask.WhatId = tm.Id;
            insert trainTask;
        
        returnValue = TrialDocumentsApexController.getTaskDocumentList(trainTask.Id);
        system.debug('returnValue2 ' + returnValue);
    }

}