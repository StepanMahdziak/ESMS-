@isTest
private class PreviewComponentControllerTest {
    @isTest
      static void runTestForPreviewComponent() {
        Task task = TestUtils.mockTaskForPreviewComponent();
        Task task2 = Testutils.mockDataForTrainingMaterials();
        Test.startTest();
        List<ContentVersion> cv = PreviewComponentController.retriveFilesFromControlledDocumentsById(task.Id);
        List<Simploud__Controlled_Document__c> cd = PreviewComponentController.getControlledDocumentsById(task.Id);
        List<ContentVersion> cv2 = PreviewComponentController.retriveFilesFromTrainingMtById(task2.Id);
        List<Simploud__Training_Material__c> tm = PreviewComponentController.getTrainingMaterialsById(task2.Id);
        Test.stopTest();
        System.assertEquals(1, cv.size(), 'The method should return a file');
        System.assertEquals(1, cv2.size(), 'The method should return a file');
    }

}
