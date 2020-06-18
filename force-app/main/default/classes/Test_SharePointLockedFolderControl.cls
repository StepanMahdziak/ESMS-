@isTest
public with sharing class Test_SharePointLockedFolderControl {
    @isTest
    static void runSharePointLockedFolderControl(){
        ContentVersion cv = TestUtils.mockDataForFileUploadControlledDocuments();
        Simploud__Controlled_Document__c cd = TestUtils.createControlledDocumentForLockedFolder();
        Test.startTest();
        SharePointLockedFolderControlQueueable splfq = new SharePointLockedFolderControlQueueable(cd);
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        splfq.setCustomMetadata();
        splfq.checkTypeFolder();
        splfq.getMetadata(cv);
        splfq.downloadCurrentFile(cv);
        splfq.UploadFileToSharePoint(cv);
        splfq.getMetadataLockedDocument(cv);
        splfq.getMetadataURI(cv);
        splfq.metadataPOSTLockedDocument();
        Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        splfq.getMetadataWithFields(cv);
        splfq.getFieldsFromCustomMetadata();
        splfq.createLinkOnPrevVersion();
        fileWrapper.generateValueForMultiSelectUpdate('dd;dd2;dd3');
        fileWrapper.generateValueForMultiSelectUpdate(null);
        fileWrapper.generateDate(Date.today());
        fileWrapper.generateDate(null);
        Test.stopTest();

    }
    @isTest
    static void runQueueuable(){
        Simploud__Controlled_Document__c cd = TestUtils.createControlledDocumentForLockedFolder();
        Test.startTest();
        SharePointLockedFolderControlQueueable splfq = new SharePointLockedFolderControlQueueable(cd);
        System.enqueueJob(splfq);
        Test.stopTest();
    }
}