/*
    Created by RedTag129 30.04.2020
 */
@isTest
public class TriggerUploadFileToSPTest {
    @isTest
    public static void runUploadFileToSPTest() {
        Test.startTest();
        ContentVersion cv = TestUtils.mockContentVersion();
        Database.SaveResult result = Database.insert(cv, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }
}
    