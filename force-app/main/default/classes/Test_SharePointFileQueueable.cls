/*
    Created by RedTag129 
 */
@isTest
private class Test_SharePointFileQueueable {
    @isTest
    static void testQueueableRunAndFileUploadCD(){
        ContentVersion cv = TestUtils.mockDataForFileUploadControlledDocuments();
        Test.startTest();
        SharePointFileQueueable spfq = new SharePointFileQueueable();
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        FieldsMetadataWrapper wrapper = new FieldsMetadataWrapper();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        spfq.setCustomMetadata();
        spfq.defineDocType(cv);
        spfq.UploadFileToSharePoint(cv);  
        spfq.getMetadata(cv);
        spfq.getMetadataURI(cv);
        spfq.fileCheckOut(cv);
        spfq.fileCheckIn(cv);
        spfq.metadataPOSTControlledDocument();
        Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        spfq.getMetadataWithFields(cv);
        spfq.getFieldsFromCustomMetadata();
        spfq.CreateExternalCV(cv);
        fileWrapper.generateValueForMultiSelectUpdate('dd;dd2;dd3');
        fileWrapper.generateValueForMultiSelectUpdate(null);
        fileWrapper.generateDate(Date.today());
        fileWrapper.generateDate(null);
        Test.stopTest();
    }


    @isTest
    static void testQueueableRunAndFileUploadGD(){
        ContentVersion cv2 = TestUtils.mockDataForFileUploadGeneralDocuments();
        Test.startTest();
        SharePointFileQueueable spfq = new SharePointFileQueueable();
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        FieldsMetadataWrapper wrapper = new FieldsMetadataWrapper();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        spfq.setCustomMetadata();
        spfq.defineDocType(cv2);
        spfq.getMetadata(cv2);
        spfq.getMetadataURI(cv2);
        spfq.fileCheckOut(cv2);
        spfq.fileCheckIn(cv2);
        spfq.metadataPOSTGeneralDocument();
         Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        spfq.getMetadataWithFields(cv2);
        spfq.getFieldsFromCustomMetadata();
        spfq.CreateExternalCV(cv2);
        Test.stopTest();

    }

    @isTest
    static void runQueueuable(){
        Test.startTest();
        SharePointFileQueueable spfq = new SharePointFileQueueable();
        System.enqueueJob(spfq);
        Test.stopTest();
    }

}