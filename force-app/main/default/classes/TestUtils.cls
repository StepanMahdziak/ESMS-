/*
   Created by RedTag129
 */
@IsTest
public class TestUtils {


    static Account mockAccount(){
        Account acc = new Account(Name='TEST ACC');
        insert acc;
        return acc;
    }

    public static Simploud__Controlled_Document__c mockControlledDocuments(){
        Account acc = mockAccount();
        Simploud__Controlled_Document__c cd = new Simploud__Controlled_Document__c();
        cd.Name='TEST DOC';
        cd.Internal_External__c='Internal';
        cd.Document_Type_ID1__c='Policy';
        cd.ESMS_Client__c=acc.Id;
        cd.Simploud__Version__c = 0.1;
        cd.Simploud__Status__c='Review';
        cd.CheckDockType__c = true;
        cd.Record_Version__c = 1.1;
        insert cd;
        return cd;
    }

    public static Simploud__Controlled_Document__c mockControlledDocumentsWithPreviousVersion(){
        Account acc = mockAccount();
        Simploud__Controlled_Document__c cd = mockControlledDocuments();
        Simploud__Controlled_Document__c cd2 = new Simploud__Controlled_Document__c();
        cd2.Name='TEST DOC2';
        cd2.Internal_External__c='Internal';
        cd2.Document_Type_ID1__c='Policy';
        cd2.ESMS_Client__c=acc.Id;
        cd2.Simploud__Version__c = 1.1;
        cd2.Simploud__Status__c='Review';
        cd2.CheckDockType__c = true;
        cd2.Record_Version__c = 1.1;
        cd2.Simploud__Previous_Version__c = cd.Id;
        insert cd2;
        return cd2;
    }

    public static ContentVersion mockContentVersion(){
        ContentVersion cv = new ContentVersion();
        cv.Title='TEST CV DATA FACTORY';
        cv.PathOnClient ='TEST CV DATA FACTORY.docx';
        cv.Origin='H';
        cv.ContentLocation='E';
        cv.VersionData = EncodingUtil.base64Decode('TEST DATA');
        cv.ExternalDataSourceId = [SELECT Id FROM ExternalDataSource WHERE DeveloperName='ESMS_SharePoint_via_Azure' LIMIT 1].Id;
        cv.ExternalDocumentInfo1='xd1';
        cv.ExternalDocumentInfo2='xd2';
        insert cv;
        return cv=[SELECT Title,FileExtension,ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id];


    }

    public static Simploud__Training_Material__c mockTrainingMaterials(){
        Account acc = mockAccount();
        Simploud__Training_Material__c tm = new Simploud__Training_Material__c();
        tm.Name = 'test';
        tm.Syllabus__c = 'General';
        tm.Category__c = 'Course';
        tm.Stream__c = 'CT';
        tm.Simploud__Type__c = 'RUS';
        tm.ESMS_Client__c=acc.Id;
        insert tm;
        return tm;
    }

    public static Simploud__Controlled_Document__c mockDataForSharepointVersion(){
        Account acc = mockAccount();
        ContentVersion cv= mockContentVersion();
        Simploud__Controlled_Document__c cd2 = new Simploud__Controlled_Document__c();
        cd2.Name='TEST DOC2';
        cd2.Internal_External__c='Internal';
        cd2.Document_Type_ID1__c='Policy';
        cd2.ESMS_Client__c=acc.Id;
        cd2.Simploud__Version__c = 0.1;
        cd2.Simploud__Status__c='Review';
        //cd2.Simploud__Previous_Version__c = cd2.Id;
        insert cd2;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = cd2.Id;
        cdl.ShareType='I';
        insert cdl;

        Simploud__Controlled_Document__c cd = new Simploud__Controlled_Document__c();
        cd.Name='TEST DOC';
        cd.Internal_External__c='Internal';
        cd.Document_Type_ID1__c='Policy';
        cd.ESMS_Client__c=acc.Id;
        cd.Simploud__Version__c = 0.1;
        cd.Simploud__Status__c='Review';
        cd.CheckDockType__c = true;
        cd.Simploud__Previous_Version__c = cd2.Id;

        insert cd;
        return cd;
    }


    public static Simploud__General_Document__c mockGeneralDocuments(){
        Account acc = mockAccount();
        Simploud__General_Document__c gd = new Simploud__General_Document__c();
        gd.Name='New Testtrtr';
        gd.Customer__c=acc.Id;
        gd.Simploud__Document_Type__c='Site List';
        insert gd;
        return gd;

    }

    public static Task mockTaskForPreviewComponent(){
        Account acc = mockAccount();
        ContentVersion cv = mockContentVersion();
        Simploud__Controlled_Document__c cd = mockControlledDocuments();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = cd.Id;
        cdl.ShareType='I';
        insert cdl;
        Task task = new Task();
        task.WhatId =  cd.Id;
        task.Subject    = 'Call';
        task.Priority = 'High';
        task.Status = 'In Progress';
        insert task;
        return task;
    }

    public static Task mockDataForTrainingMaterials(){
        Account acc = mockAccount();
        ContentVersion cv = mockContentVersion();
        Simploud__Training_Material__c tm = mockTrainingMaterials();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = tm.Id;
        cdl.ShareType='I';
        insert cdl;
        Task task = new Task();
        task.WhatId =  tm.Id;
        task.Subject    = 'Call';
        task.Priority = 'High';
        task.Status = 'In Progress';
        insert task;
        return task;

    }

    //for SharepointLockedFolderControl
    public static Simploud__Controlled_Document__c createControlledDocumentForLockedFolder(){
        Account acc = mockAccount();
        ContentVersion cv = mockContentVersion();
        Simploud__Controlled_Document__c cd = mockControlledDocuments();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = cd.Id;
        cdl.ShareType='I';
        insert cdl;
        return cd;
    }




    public static Map<Id,Simploud__Controlled_Document__c> mockMapControlledDocumentsForMetadataUpdate(){
        Account acc = mockAccount();
        ContentVersion cv= mockContentVersion();
        Map<Id, Simploud__Controlled_Document__c> mapControlledDocs = new Map<Id, Simploud__Controlled_Document__c> ();
        Simploud__Controlled_Document__c cd2 = new Simploud__Controlled_Document__c();
        cd2.Name='TEST DOC2';
        cd2.Internal_External__c='Internal';
        cd2.Document_Type_ID1__c='Policy';
        cd2.ESMS_Client__c=acc.Id;
        cd2.Simploud__Version__c = 0.1;
        cd2.Simploud__Status__c='Review';
        //cd2.Simploud__Previous_Version__c = cd2.Id;
        insert cd2;

        Simploud__Controlled_Document__c cd = new Simploud__Controlled_Document__c();
        cd.Name='TEST DOC';
        cd.Internal_External__c='Internal';
        cd.Document_Type_ID1__c='Policy';
        cd.ESMS_Client__c=acc.Id;
        cd.Simploud__Version__c = 0.1;
        cd.Simploud__Status__c='Review';
        cd.CheckDockType__c = true;
        insert cd;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = cd.Id;
        cdl.ShareType='I';
        insert cdl;
        //Simploud__Controlled_Document__c cd2 = mockControlledDocuments();
        //Simploud__Controlled_Document__c cd = mockControlledDocuments();
        //ContentDocumentLink cdl = new ContentDocumentLink();
        //cdl.ContentDocumentId = cv.ContentDocumentId;
        //cdl.LinkedEntityId = cd2.Id;
        //cdl.ShareType='I';
        //insert cdl;
        mapControlledDocs.put(cd2.id, cd);
        return mapControlledDocs;
    }

    public static ContentVersion mockDataForFileUploadControlledDocuments(){
        Account acc = mockAccount();
        ContentVersion cv= mockContentVersion();
        Simploud__Controlled_Document__c cd = mockControlledDocuments();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = cd.Id;
        cdl.ShareType='I';
        insert cdl;
        return [SELECT Title,FileExtension,PathOnClient,ExternalDocumentInfo1,ExternalDocumentInfo2,VersionData,ContentDocumentId FROM ContentVersion];
    }

    public static ContentVersion mockDataForFileUploadGeneralDocuments(){
        Account acc = mockAccount();
        ContentVersion cv= mockContentVersion();
        Simploud__General_Document__c gd = mockGeneralDocuments();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = gd.Id;
        cdl.ShareType='I';
        insert cdl;
        return [SELECT Title,FileExtension,PathOnClient,ExternalDocumentInfo1,ExternalDocumentInfo2,VersionData,ContentDocumentId FROM ContentVersion];
    }

    public static Simploud__General_Document__c mockDataForMetadataUpdateGeneralDocuments(){
        ContentVersion cv= mockContentVersion();
        Account acc = mockAccount();
        Simploud__General_Document__c gd = new Simploud__General_Document__c();
        gd.Name='New Testgfgh';
        gd.Customer__c=acc.Id;
        gd.Simploud__Document_Type__c='Site List';
        insert gd;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = gd.Id;
        cdl.ShareType='I';
        insert cdl;
        return gd;
    }

}