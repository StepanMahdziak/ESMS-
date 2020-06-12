/*
    Created by RedTag129 on 12.08.2019
    Updated by RedTag129 on 11.12.2019
 */
public with sharing class MetadataUpdateQueuebale implements Queueable, Database.AllowsCallouts {
    FileMetadataWrapper fileWrapper = new FileMetadataWrapper();
    SharePointFileQueueable sp = new SharePointFileQueueable();
    CustomMetadataWrapper metWrapper;
    String folder;
    String path;
    String id;
    String guid;
    String serverRedirectedEmbedUri;
    String uri;
    String type;
    ContentVersion cv;
    String docType;
    Id recordId;
    public Boolean isProgress = false;
    Map<Id,Simploud__Controlled_Document__c> cdObjs;
    Map<Id,Simploud__Controlled_Document__c> cdOld;
    Simploud__General_Document__c gdObj;
    String versionNum;
    String fields;
    Map<String,String> fieldsMap;
    Map<String, String> mapFieldsWithType = new Map<String,String>();
    Map<String,String> mapFieldsFromSharePoint = new Map <String, String>();
    Set<String> setTypes = new Set<String>();
    String newStatus;
    String externalFilePath;


    public MetadataUpdateQueuebale(Map<Id,Simploud__Controlled_Document__c> conDocObjs, Map<Id,Simploud__Controlled_Document__c> oldMap ) {
        cdObjs = conDocObjs;
        cdOld = oldMap;
    }

    public MetadataUpdateQueuebale(Simploud__General_Document__c genDocObj) {
        gdObj = new Simploud__General_Document__c();
        gdObj = genDocObj;
        recordId = gdObj.Id;
        Id cdId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId].ContentDocumentId;
        cv = [SELECT Title, FileExtension,ExternalDocumentInfo1, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :cdId];
    }



    public void execute(QueueableContext context) {
        for(Simploud__Controlled_Document__c cdObj:cdObjs.values()) {
            recordId = cdObj.Id;
        }
        Id cdId = [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId].ContentDocumentId;
        cv = [SELECT Title, FileExtension,ExternalDocumentInfo1, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId = :cdId];
        for(Simploud__Controlled_Document__c cdObj:cdObjs.values()) {
            setCustomMetadata();
            defineDocType(cv);
            if(cdObj.Simploud__Status__c == 'Effective' ||  cdObj.Simploud__Status__c == 'Obsolete') {
                docType = 'Locked%20Documents';
            }
            if (cdObj.Simploud__Status__c == 'Cancelled') {
                if (
                    versionNum != null &&
                    (Decimal.valueOf(versionNum) == cdObj.Simploud__Version__c ||
                     Decimal.valueOf(versionNum) + 1.0 == cdObj.Simploud__Version__c)
                    ) {
                    docType = 'Locked%20Documents';
                } else {
                    defineDocType(cv);
                }
            }
            setFolder();
            if(!Test.isRunningTest()) {
                getMetadata(cv);
                getMetadataURI(cv);
                getMetadataWithFields(cv);
                cv.Title=cdObj.Name+' v'+Integer.valueof(cdObj.Record_Version__c)+' '+cdObj.Simploud__Status__c;

                fileCheckOut(cv);
                if (docType == 'Locked%20Documents') {
                    metadataPOSTLockedDocument();
                    fileCheckIn(cv);
                    String newTitle = cdObj.Name+' v'+Integer.valueof(cdObj.Record_Version__c)+' '+cdObj.Simploud__Status__c;
                    metadataRenameFile(newTitle);

                } if (docType == 'Controlled%20Documents') {
                    metadataPOSTControlledDocument();
                    fileCheckIn(cv);
                    String newTitle = cdObj.Name+' v'+Integer.valueof(cdObj.Record_Version__c)+' '+cdObj.Simploud__Status__c;
                    metadataRenameFile(newTitle);
                } if (docType == 'General%20Documents') {
                    metadataPOSTGeneralDocument();
                    fileCheckIn(cv);
                }
                cv.Title=cdObj.Name+' v'+Integer.valueof(cdObj.Record_Version__c)+' '+cdObj.Simploud__Status__c;
                if(cv.FileExtension == 'pdf') {
                    if(docType == 'Controlled%20Documents') {
                        if(metWrapper.sitePath == '/sites/edmsclientdocs/') {
                            String encodedFolderName = EncodingUtil.urlEncode(metWrapper.controlledDocsFolder,'UTF-8').replace('+','%20');
                            String encodedTitle = EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20');
                            String sitePath = EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' );
                            cv.ExternalDocumentInfo1 ='https://medtoxdataline.sharepoint.com/'+sitePath+encodedFolderName+'/Forms/AllItems.aspx?id='+sitePath+encodedFolderName+'%2F'+encodedTitle+'.pdf&parent='+encodedFolderName;
                            update cv;
                        }else{
                            String folderName = 'DrafttoDraftApprovalDocuments';
                            String encodedUrl = EncodingUtil.urlEncode(externalFilePath,'UTF-8').replace('+','%20');
                            cv.ExternalDocumentInfo1 = 'https://medtoxdataline.sharepoint.com'+metWrapper.sitePath+folderName+'/Forms/AllItems.aspx?viewpath='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'&id='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'%2F'+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.pdf&parent='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName;
                            update cv;
                        }
                    }
                    if(docType == 'Locked%20Documents') {
                        if(metWrapper.sitePath == '/sites/edmsclientdocs/') {
                            String encodedFolderName2 = EncodingUtil.urlEncode(metWrapper.lockedDocsFolder,'UTF-8').replace('+','%20');
                            String encodedTitle2 = EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20');
                            String sitePath = EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' ).replace('+','%20');
                            cv.ExternalDocumentInfo1 ='https://medtoxdataline.sharepoint.com/'+sitePath+encodedFolderName2+'/Forms/AllItems.aspx?id='+sitePath+encodedFolderName2+'%2F'+encodedTitle2+'.pdf&parent='+encodedFolderName2;
                            update cv;
                        }else{
                            String folderName = 'ApprovedtoObsoleteDocuments';
                            String encodedUrl = EncodingUtil.urlEncode(externalFilePath,'UTF-8').replace('+','%20');
                            cv.ExternalDocumentInfo1 = 'https://medtoxdataline.sharepoint.com'+metWrapper.sitePath+folderName+'/Forms/AllItems.aspx?viewpath='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'&id='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName+'%2F'+EncodingUtil.urlEncode(cv.Title,'UTF-8').replace('+','%20')+'.pdf&parent='+EncodingUtil.urlEncode(metWrapper.sitePath,'UTF-8' )+folderName;
                            update cv;
                        }
                    }
                }

                if(cdObj.Simploud__Status__c == 'Approved' && cv.FileExtension != 'pdf' ) {
                    cv.ExternalDocumentInfo1 = cv.ExternalDocumentInfo1.replace('edit', 'view');
                    update cv;
                }
                else
                    update cv;
                //   }
                if(cdObj.Simploud__Status__c =='Approved') {
                    System.enqueueJob(new SharePointLockedFolderControlQueueable(cdObj));
                }
            }
        }

    }

    public void defineDocType(ContentVersion cv) {
        list<ContentDocumentLink> cdlList = [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
        ];
        for (ContentDocumentLink cdl : cdlList) {
            String entityType = cdl.LinkedEntityId.getSobjectType().getDescribe().getLabelPlural();
            if (entityType != 'Users') {
                docType = entityType.replace(' ', '%20');
            }
        }
    }
    public void getMetadataWithFields(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept','application/json;odata=verbose');
        request.setHeader('Content-Type','application/json;odata=verbose');
        String url = metWrapper.sitePath+'_api/web/lists/GetByTitle('+'\''+folder+'\''+')/fields';
        request.setEndpoint('callout:'+metWrapper.authProvider+url);
        Http http = new Http();
        HttpResponse response = http.send(request);
        FieldsMetadataWrapper wrapper;
        wrapper = FieldsMetadataWrapper.parse(response.getBody());
        for(FieldsMetadataWrapper.Results item : wrapper.d.results) {
            mapFieldsFromSharePoint.put(item.Title, item.StaticName);
            mapFieldsWithType.put(item.Title, item.TypeAsString);
            setTypes.add(item.TypeAsString);
        }
    }

    public HttpResponse  getMetadata(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        String url =
            metWrapper.sitePath +
            '_api/web/lists/GetByTitle(' +
            '\'' +
            folder +
            '\'' +
            ')/Files(\'' +
            EncodingUtil.urlEncode(cv.Title, 'UTF-8').replace('+', '%20') +
            '.' +
            cv.FileExtension +
            '\')';
        request.setEndpoint('callout:' + metWrapper.authProvider + url);
        Http http = new Http();
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            path = fileWrapper.getURL(response.getBody());
        }
        return response;
    }



    public void getMetadataURI(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String encodedUrl = EncodingUtil.urlEncode(relative, 'UTF-8').replace('+', '%20');
        String relativeURL =
            metWrapper.sitePath +
            '_api/web/GetFileByServerRelativeUrl(' +
            '\'' +
            encodedUrl +
            '\')/ListItemAllFields';
        request.setEndpoint('callout:' + metWrapper.authProvider + relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
        id = fileWrapper.getID(response.getBody());
        guid = fileWrapper.getGUID(response.getBody());
        serverRedirectedEmbedUri = fileWrapper.getServerRedirectedEmbedUri(response.getBody());
        uri = fileWrapper.getURI(response.getBody());
        type = fileWrapper.getType(response.getBody());

    }

    public void fileCheckOut(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Length', '0');
        request.setHeader('Accept', 'application/json;odata=verbose');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String goodRelative = relative.replace('+', '%20');
        String encodedUrl = EncodingUtil.urlEncode(goodRelative, 'UTF-8').replace('+', '%20');
        String relativeURL =
            metWrapper.sitePath +
            '_api/web/GetFileByServerRelativeUrl(' +
            '\'' +
            encodedUrl +
            '\')/CheckOut()';
        request.setEndpoint('callout:' + metWrapper.authProvider + relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
    }

    public void fileCheckIn(ContentVersion cv) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Length', '0');
        String relative = path.substring(path.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        externalFilePath = relative;
        String encodedUrl = EncodingUtil.urlEncode(relative, 'UTF-8').replace('+', '%20');
        String relativeURL =
            metWrapper.sitePath +
            '_api/web/GetFileByServerRelativeUrl(' +
            '\'' +
            encodedUrl +
            '\')/CheckIn()';
        request.setEndpoint('callout:' + metWrapper.authProvider + relativeURL);
        Http http = new Http();
        HttpResponse response = http.send(request);
    }


    public String getFieldsFromCustomMetadata(){
        String fieldSP;
        String fieldSF;
        fieldsMap = new Map<String,String>();
        String json='{"__metadata":{"type":'+type+'},';
        List<String> rows = fields.split(';');


        for(String item:rows) {
            if(item.split(':').size()>0) {
                fieldSP = item.split(':')[0];
                fieldSF = item.split(':')[1];
                fieldsMap.put(fieldSP, fieldSF);
            }
        }

        String query='SELECT ';
        String query2='SELECT ';
        for(String field:fieldsMap.values()) {
            query+=field+', ';
            query2+=field+', ';
        }
        SObject ob;
        if(docType =='General%20Documents') {
            query2+='Id FROM Simploud__General_Document__c WHERE Id=:recordId';
            ob =(Simploud__General_Document__c) Database.query(query2);

        }
        if (docType =='Controlled%20Documents' || docType =='Locked%20Documents') {
            query+='Id FROM Simploud__Controlled_Document__c WHERE Id=:recordId';
            ob =(Simploud__Controlled_Document__c) Database.query(query);

        }

        for(String key : mapFieldsWithType.keyset()) {
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'DateTime') {
                json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+String.valueOf(fileWrapper.generateDate(date.valueOf(ob.get(fieldsMap.get(key)))))+'",';
            }
            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'MultiChoice') {
                json+= '"'+mapFieldsFromSharePoint.get(key)+'" : {"__metadata":{"type":"Collection(Edm.String)"},"results":'+fileWrapper.generateValueForMultiSelectUpdate(''+ob.get(fieldsMap.get(key) )+'')+'},';
            }

            if(fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Choice'||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Number'||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Text' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Boolean' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'URL' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'File' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Guid' ||
               fieldsMap.get(key) != null && mapFieldsWithType.get(key) == 'Note') {

                if(!fieldsMap.get(key).contains('__r')) {
                    if(fieldsMap.get(key).contains('.')) {
                        if(fieldsMap.get(key).split('\\.').size() == 3) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).get(fieldsMap.get(key).split('\\.')[2])+'",';
                        }else {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject('Owner').get('Name')+'",';
                        }
                    }
                }

                if(fieldsMap.get(key).contains('__r')) {
                    try{
                        if(fieldsMap.get(key).split('\\.').size() == 5) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).getSObject(fieldsMap.get(key).split('\\.')[2]).getSObject(fieldsMap.get(key).split('\\.')[3]).get(fieldsMap.get(key).split('\\.')[4])+'",';

                        }
                        if(fieldsMap.get(key).split('\\.')[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).getSObject(fieldsMap.get(key).split('\\.')[1]).get(fieldsMap.get(key).split('\\.')[2])+'",';

                        } if(!fieldsMap.get(key).split('\\.')[1].contains('__r')) {
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.getSObject(fieldsMap.get(key).split('\\.')[0]).get(fieldsMap.get(key).split('\\.')[1])+'",';
                        }
                    }
                    catch(Exception e) {
                        if(e.getMessage().contains('Attempt to '))
                            json+='"'+mapFieldsFromSharePoint.get(key)+'":"Not specified",';
                    }

                } if(!fieldsMap.get(key).contains('.')) {
                    json+='"'+mapFieldsFromSharePoint.get(key)+'":"'+ob.get(fieldsMap.get(key))+'",';
                }

            }

        }

        json+= +'}';
        Integer index=json.lastIndexOf(',');
        json=json.left(index)+json.right(json.length()-index-1);
        return json;

    }

    public void metadataPOSTControlledDocument() {
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String uri = EncodingUtil.urlEncode(relative, 'UTF-8');
        request.setEndpoint('callout:' + metWrapper.authProvider + relative);
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        request.setHeader('X-Http-Method', 'MERGE');
        request.setHeader('If-Match', '*');
        request.setBody(
            getFieldsFromCustomMetadata());
        Http http = new Http();
        HttpResponse response = http.send(request);
    }

    public void metadataPOSTGeneralDocument() {
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String URI = EncodingUtil.urlEncode(relative, 'UTF-8');
        request.setEndpoint('callout:' + metWrapper.authProvider + relative);
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        request.setHeader('X-Http-Method', 'MERGE');
        request.setHeader('If-Match', '*');
        request.setBody(
            getFieldsFromCustomMetadata());
        Http http = new Http();
        HttpResponse response = http.send(request);

    }

    public void metadataPOSTLockedDocument() {
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String uri = EncodingUtil.urlEncode(relative, 'UTF-8');
        request.setEndpoint('callout:' + metWrapper.authProvider + relative);
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        request.setHeader('X-Http-Method', 'MERGE');
        request.setHeader('If-Match', '*');
        request.setBody(
            getFieldsFromCustomMetadata());
        Http http = new Http();
        HttpResponse response = http.send(request);
    }

    public void metadataRenameFile(String newTitle){
        HttpRequest request = new HttpRequest();
        String relative = uri.substring(uri.lastIndexOf('.sharepoint.com') + 15).replace('"', '');
        String uri = EncodingUtil.urlEncode(relative, 'UTF-8');
        request.setEndpoint('callout:' + metWrapper.authProvider + relative);
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json;odata=verbose');
        request.setHeader('Content-Type', 'application/json;odata=verbose');
        request.setHeader('X-Http-Method', 'MERGE');
        request.setHeader('If-Match', '*');
        request.setBody(' {"__metadata":{"type":'+type+'},'+
                        '"Title":"'+newTitle+'",'+
                        '"FileLeafRef":"'+newTitle+'"}');
        Http http = new Http();
        HttpResponse response = http.send(request);

    }

    public void setCustomMetadata() {
        String lockedFolder, controlledFolder, generalFolder;
        String controlledField, generalField, lockedField;
        SharePoint_API_Info__mdt info = [
            SELECT Auth_Provider__c, Site_Path__c
            FROM SharePoint_API_Info__mdt
            WHERE DeveloperName = 'Integration_settings'
                                  LIMIT 1
        ];
        List<SharePointSettings__mdt> sett = [
            SELECT DeveloperName, Folder_Title__c,Fields__c
            FROM SharePointSettings__mdt
            LIMIT 4
        ];
        for (SharePointSettings__mdt item : sett) {
            if (item.DeveloperName == 'Controlled_Documents') {
                controlledFolder = item.Folder_Title__c;
                controlledField = item.Fields__c;
            }
            if (item.DeveloperName == 'General_Documents') {
                generalFolder = item.Folder_Title__c;
                generalField = item.Fields__c;
            }
            if (item.DeveloperName == 'Locked_Documents') {
                lockedFolder = item.Folder_Title__c;
                lockedField = item.Fields__c;

            }
        }
        metWrapper = new CustomMetadataWrapper(
            info.Auth_Provider__c,
            info.Site_Path__c,
            controlledFolder,
            generalFolder,
            lockedFolder,
            controlledField,
            generalField,
            lockedField
            );
    }
    public void setFolder() {
        system.debug('Set folder doctype:->>'+docType);
        if (docType == 'General%20Documents') {
            folder = EncodingUtil.urlEncode(metWrapper.generalDocsFolder,'UTF-8').replace('+','%20');
            fields = metWrapper.generalDocField;
        } else if (docType == 'Controlled%20Documents') {
            folder = EncodingUtil.urlEncode(metWrapper.controlledDocsFolder,'UTF-8').replace('+','%20');
            fields = metWrapper.controlledDocField;
        } else if (docType == 'Locked%20Documents') {
            folder = EncodingUtil.urlEncode(metWrapper.lockedDocsFolder,'UTF-8').replace('+','%20');
            fields = metWrapper.lockedDocField;
        }
    }

    public MetadataUpdateQueuebale(){
        System.debug('Empty constructor');
    }


    //Method for test class
    public void setRecordId(Id recordId){
        this.recordId = recordId;
    }



}