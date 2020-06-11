/*
    Created by RedTag129
 */
@isTest
private class Test_SharePointVersion{
    @isTest
    static void runSharePointVersionQueueable(){
        ContentVersion cv = TestUtils.mockDataForFileUploadControlledDocuments();
        Simploud__Controlled_Document__c cd = TestUtils.mockDataForSharepointVersion();
        SharePointVersionControlQueueable spvcq = new SharePointVersionControlQueueable(cd);
        FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GetMetadataMock());
        spvcq.setCustomMetadata();
        spvcq.checkTypeFolder();
        spvcq.getMetadata(cv);
        spvcq.downloadCurrentFile(cv);
        spvcq.UploadFileToSharePoint(cv);
        spvcq.getMetadataLockedDocument(cv);
        spvcq.getMetadataURI(cv);
        spvcq.getMetadataURIFromCD(cv);
        spvcq.metadataPOSTLockedDocument();
        Test.setMock(HttpCalloutMock.class, new GetFieldsMock());
        spvcq.getMetadataWithFields(cv);
        spvcq.getFieldsFromCustomMetadata();
        spvcq.metadataRenameFile('Test');
        spvcq.createLinkOnPrevVersion();
        fileWrapper.generateValueForMultiSelectUpdate('dd;dd2;dd3');
        fileWrapper.generateValueForMultiSelectUpdate(null);
        fileWrapper.generateDate(Date.today());
        fileWrapper.generateDate(null);
   		Test.stopTest();
       
    }
    
   

}