/*
    Created by RedTag129
 */
@isTest
private class Test_MetadataUpdate {
    @isTest
    static void testQueueableRunAndUpdateMetadataCD(){
        ContentVersion cv = TestUtils.mockDataForFileUploadControlledDocuments();
        system.debug('cv>> ' + cv);
        Simploud__Controlled_Document__c controlledDocs = TestUtils.mockControlledDocuments();
        Map<Id,Simploud__Controlled_Document__c > mapControlledDocs = TestUtils.mockMapControlledDocumentsForMetadataUpdate();
        system.debug('mapControlledDocs>> ' + mapControlledDocs);

        Map<Id,Simploud__Controlled_Document__c > mapControlledDocs2 = TestUtils.mockMapControlledDocumentsForMetadataUpdate();
        system.debug('mapControlledDocs2>> ' + mapControlledDocs2);

        Test.startTest();
        MetadataUpdateQueuebale muqc = new MetadataUpdateQueuebale(mapControlledDocs, mapControlledDocs2);
        muqc.setRecordId(controlledDocs.Id);
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        muqc.setCustomMetadata();
        muqc.defineDocType(cv);
        muqc.setFolder();
        muqc.getMetadata(cv);
        muqc.getMetadataURI(cv);
        muqc.fileCheckOut(cv);
        muqc.metadataPOSTControlledDocument();
       // muqc.metadataPOSTLockedDocument();
        muqc.fileCheckIn(cv);
        muqc.metadataRenameFile('Test');
        Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        muqc.getMetadataWithFields(cv);
        muqc.getFieldsFromCustomMetadata();
        fileWrapper.generateValueForMultiSelectUpdate('dd;dd2;dd3');
        fileWrapper.generateValueForMultiSelectUpdate(null);
        fileWrapper.generateDate(Date.today());
        fileWrapper.generateDate(null);
        Test.stopTest();
      //  System.assertEquals(1, mapControlledDocs.size(), 'The method should return a controlledDoc');
      //  System.assertEquals(200, muqc.getMetadata(cv).getStatusCode());


    }

    @isTest
    static void testQueueableRunAndUpdateMetadataGD(){
        ContentVersion cv2 = TestUtils.mockDataForFileUploadGeneralDocuments();
        Simploud__General_Document__c generalDocs = TestUtils.mockDataForMetadataUpdateGeneralDocuments();
        Test.startTest();
        MetadataUpdateQueuebale muqg = new MetadataUpdateQueuebale(generalDocs);
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        muqg.setCustomMetadata();
        muqg.defineDocType(cv2);
        muqg.setFolder();
        muqg.getMetadata(cv2);
        muqg.getMetadataURI(cv2);
        muqg.fileCheckOut(cv2);
        muqg.metadataPOSTGeneralDocument();
        muqg.fileCheckIn(cv2);
        muqg.metadataRenameFile('Test');
        Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        muqg.getMetadataWithFields(cv2);
        muqg.getFieldsFromCustomMetadata();
        fileWrapper.generateValueForMultiSelectUpdate('dd;dd2;dd3');
        fileWrapper.generateValueForMultiSelectUpdate(null);
        fileWrapper.generateDate(Date.today());
        fileWrapper.generateDate(null);
        Test.stopTest();
       // System.assertEquals(200, muqg.getMetadata(cv2).getStatusCode());
    }
    
     @isTest
     static void runQueueuable(){
        Map<Id, Simploud__Controlled_Document__c> mapControlledDocs = TestUtils.mockMapControlledDocumentsForMetadataUpdate();
        System.debug('mapControlledDocs>>> -  ' + mapControlledDocs);
        Map<Id,Simploud__Controlled_Document__c> mapControlledDocs2 = TestUtils.mockMapControlledDocumentsForMetadataUpdate();
        Test.startTest();
        MetadataUpdateQueuebale muqc = new MetadataUpdateQueuebale(mapControlledDocs, mapControlledDocs2);
        System.enqueueJob(muqc);
        Test.stopTest();
    }
    
   


}