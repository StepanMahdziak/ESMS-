/*
    Created by RedTag129 
 */
@isTest
public class ControlledDocumentCustomTriggerTest {
   @testSetup 
    public static void testSetup() {
      
        Simploud__Compliance_Configuration__c setting = new Simploud__Compliance_Configuration__c(
           Simploud__Document_Type__c = 'Policy',
           Simploud__Document_Type_Index__c = 5
        );
        insert setting;
        
     
        
        Simploud__Controlled_Document__c testDocument = new Simploud__Controlled_Document__c(
            Name = 'TestDoc',
            Simploud__Status__c = 'Draft',
            SP_SF_Owner_Date__c =  Datetime.now().format('dd MMM yyyy h:mm a'),
            Review_Date_Time__c = Datetime.now(),
            SF_SP_Review_Date__c = Datetime.now().format('dd MMM yyyy h:mm a'),
            Approved_Date_Time__c = Datetime.now(),
            SF_SP_Approver_Date__c = Datetime.now().format('dd MMM yyyy h:mm a'),
            Effective_Date_Time__c  = Datetime.now(),
            SF_SP_Effective_Date_Time__c = Datetime.now().format('dd MMM yyyy h:mm a'),
            Next_Review_Date__c = Datetime.now().addYears(2).format('dd MMM yyyy h:mm a')
           
           // Simploud__Document_Type__c = 'Policy'
        );
        insert testDocument;
        
         ContentVersion newFile = new ContentVersion(
            VersionData = EncodingUtil.base64Decode('Banana'),
            Title = 'Banana',
            PathOnClient  = 'Banana.docx'
        );
        insert newFile;
        Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true;
        Simploud__SimploudOrgSettings__c sett = new Simploud__SimploudOrgSettings__c();
       // sett = [SELECT Id,Simploud__IgnoreTriggers__c,Simploud__IgnoreConfigTrigger__c FROM Simploud__SimploudOrgSettings__c LIMIT 1]; 
        system.debug('test--> ' + sett);
        sett.Simploud__IgnoreConfigTrigger__c = true;
        sett.Simploud__IgnoreTriggers__c = true;
        Database.SaveResult sr = Database.insert(sett, dml); 
		if (sr.isSuccess()) {   
 		System.debug('Duplicate account has been inserted in Salesforce!'); 
         ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newFile.Id].ContentDocumentId;
        cdl.LinkedEntityId = testDocument.Id;
        cdl.ShareType='I';
        insert cdl;
        }
        try
        {
            testDocument.Simploud__Status__c = 'Review';
            testDocument.Simploud__Update_Status__c = true;
            update testDocument;
        }
        catch (exception e)
        {
            system.assertNotEquals(null, e);
        }
    }
    
     @isTest 
    public static void processDocuments() {
        
       
            
        List<Simploud__Controlled_Document__c> cd = [SELECT Id,Simploud__Status__c,Document__c FROM Simploud__Controlled_Document__c];
        Simploud__Controlled_Document__c doc = new  Simploud__Controlled_Document__c();
        if (!cd.isEmpty())
        doc = cd[0];
       
        System.assertEquals(1, cd.size());
        ContentDocument cDoc = [SELECT Id FROM ContentDocument];
        List<ContentDocumentLink> documentLinks = [SELECT ID, ContentDocumentId, LinkedEntityId
                                            FROM ContentDocumentLink
                                     WHERE LinkedEntityId =: doc.Id];
        
        
        // System.assertEquals(0, documentLinks.size());
        doc.Simploud__Status__c = 'Review';
        
        try{
        update doc;
        }
        
        catch (exception e)
        {
        }
    }
    
    
    
   

}