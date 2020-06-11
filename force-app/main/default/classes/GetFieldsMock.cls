@isTest
global class GetFieldsMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;odata=verbose');
        res.setBody( 
             '{'+
                           ' "d": {'+
                                '"results": ['+
                                '{'+
                                   ' "__metadata": {'+
                                   ' "id": "https://medtoxdataline.sharepoint.com/sites/edmsclientdocs/_api/Web/Lists(guid\'TEST-GUID\')/Fields(guid\'TEST-GUID\')",'+
                                   ' "uri": "https://medtoxdataline.sharepoint.com/sites/edmsclientdocs/_api/Web/Lists(guid\'TEST-GUID\')/Fields(guid\'TEST-GUID\')",'+
                                   ' "type": "SP.Field"'+
                                   ' },'+
                                    
                                   ' "Id": "03e45e84-1992-4d42-9116-26f756012634",'+
                                    '"StaticName": "ContentTypeId",'+
                                    '"Title": "Content Type ID",'+
                                    '"TypeAsString": "ContentTypeId"'+
                                
                               ' }'+
                                
                               ' ]'+
                           ' }'+
                    '}'
        );
           
        res.setStatusCode(200);
        return res;
    }
}