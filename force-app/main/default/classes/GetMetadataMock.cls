@isTest
global class GetMetadataMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;odata=verbose');
        res.setBody(
            '{'+
            '"d": {'+
            '"__metadata": {'+
            '"uri": "https://medtoxdataline.sharepoint.com/sites/edmsclientdocs/_api/Web/Lists(guid\'TEST-GUID\')/Items(246)",'+
            '"type": "TestType"'+

            ' },'+
            '"ServerRedirectedEmbedUri": "https://medtoxdataline.sharepoint.com/sites/edmsclientdocs/_layouts/15/Doc.aspx?sourcedoc={c5698aa6-29a1-48e8-93d4-b537939c0d42}&action=interactivepreview",'+
            '"ID": 555,'+
            ' "GUID": "TEST-GUID",'+
            '"Title": "TestType",'+
            '"FileLeafRef": "TestType",'+
            ' "Url":"sharepoint.com/testurl"}}'
            );

        res.setStatusCode(200);
        return res;
    }
}