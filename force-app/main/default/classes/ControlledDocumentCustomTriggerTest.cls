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
            Name = 'TestDoc1',
            Simploud__Status__c = 'Draft'
            // ,
           // Simploud__Document_Type__c = 'Policy'
        );
        insert testDocument;
        
         ContentVersion newFile = new ContentVersion(
            VersionData = EncodingUtil.base64Decode('Banana'),
            Title = 'Banana',
            PathOnClient  = 'Banana.docx'
        );
        insert newFile;
    }
    
     @isTest 
    public static void processDocuments() {
                
        List<Simploud__Controlled_Document__c> docList = [SELECT Id,Simploud__Status__c,Document__c FROM Simploud__Controlled_Document__c];
        Simploud__Controlled_Document__c doc = new  Simploud__Controlled_Document__c();
        if (!docList.isEmpty())
        doc = docList[0];
        
        System.assertEquals(1, docList.size());
       // System.assertEquals('POL-00005', docList[0].Document__c);
        ContentDocument cDoc = [SELECT Id FROM ContentDocument];
        system.debug('CDOC' + cDoc);

      List<ContentDocumentLink> documentLinks = [SELECT ID, ContentDocumentId, LinkedEntityId
                                            FROM ContentDocumentLink
                                     WHERE LinkedEntityId =: doc.Id];
        
        
       System.assertEquals(0, documentLinks.size());

        system.debug('Doc1:'+doc);
        doc.Simploud__Status__c = 'Review';
		system.debug('Doc2:'+doc);
        
        try{
        update doc;
        }
        
        catch (exception e)
        {
        }
    }
    
    
    
   

}