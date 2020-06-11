@isTest
public class TrialItemCustomTriggerTest {
    
    @isTest 
    public static void TrialItemCustomTriggerTest()
    {
        Simploud__General_Document__c doc = new Simploud__General_Document__c(
            Name = 'TestDoc1'
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
        
        Simploud__Trial__c testTrial = new Simploud__Trial__c (
            Name = 'TestTrial1'
        );
        insert testTrial;
        system.debug('testTrial ' + testTrial);
        
        
        Simploud__Trial_Item__c testTrialItem = new Simploud__Trial_Item__c (
            Name = 'TestTrialItem1',
            Client_Document__c = doc.Id,
            Simploud__Trial__c = testTrial.Id
        );      
        insert testTrialItem;        
        system.debug('testTrialItem ' + testTrialItem);        
        
        
         List<ContentDocumentLink> linkList = [SELECT ContentDocumentId  
            FROM ContentDocumentLink 
            WHERE ContentDocumentId =: cd.Id]; 
        system.debug('List:' + linkList);
        system.debug('New Version:' + newVersion.ContentDocumentId);
        System.assertEquals( 2, linkList.Size());        
        
    }
    
}