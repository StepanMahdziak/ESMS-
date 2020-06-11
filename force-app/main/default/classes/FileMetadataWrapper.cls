/*
    Created by RedTag129 on 27.11.2019.
 */
public with sharing class FileMetadataWrapper {

    public String getURL(String body){
        Map<String,Object> deserialized =(Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString=(String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 =(Map<String,Object>)JSON.deserializeUntyped(nextString);
        String url = (String)JSON.serialize(deserialized2.get('Url'));
        return url;
    }

    public String getType(string body){
        Map<String,Object> deserialized =(Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString=(String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 =(Map<String,Object>)JSON.deserializeUntyped(nextString);
        String nextString2 = (String)JSON.serialize(deserialized2.get('__metadata'));
        Map<String,Object> deserialized3 =(Map<String,Object>)JSON.deserializeUntyped(nextString2);
        String type = (String)JSON.serialize(deserialized3.get('type'));
        return type;

    }

    public String getID(String body){
        Map<String,Object> deserialized = (Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString = (String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 = (Map<String,Object>)JSON.deserializeUntyped(nextString);
        String stringID = (String)JSON.serialize(deserialized2.get('ID'));
        return stringID;
    }


    public String getGUID(String body){
        Map<String,Object> deserialized = (Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString =(String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 = (Map<String,Object>)JSON.deserializeUntyped(nextString);
        String stringGUID =(String)JSON.serialize(deserialized2.get('GUID'));
        return stringGUID;
    }


    public String getServerRedirectedEmbedUri(String body){
        Map<String,Object> deserialized = (Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString =(String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 = (Map<String,Object>)JSON.deserializeUntyped(nextString);
        String stringServerRedirectedEmbedUri =(String)JSON.serialize(deserialized2.get('ServerRedirectedEmbedUri'));
        return stringServerRedirectedEmbedUri;
    }


    public String getURI(String body){
        Map<String,Object> deserialized =(Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString=(String)JSON.serialize(deserialized.get('d'));
        Map<String,Object> deserialized2 =(Map<String,Object>)JSON.deserializeUntyped(nextString);
        String nextString2 = (String)JSON.serialize(deserialized2.get('__metadata'));
        Map<String,Object> deserialized3 =(Map<String,Object>)JSON.deserializeUntyped(nextString2);
        String uri = (String)JSON.serialize(deserialized3.get('uri'));
        return uri;
    }
    public String getLockedURL(String body){
        Map<String,Object> deserialized =(Map<String,Object>)JSON.deserializeUntyped(body);
        String nextString = (String)JSON.serialize(deserialized.get('d'));
        system.debug(nextString);
        Map<String,Object> deserialized2 =(Map<String,Object>)JSON.deserializeUntyped(nextString);
        String lockedUrl = (String)JSON.serialize(deserialized2.get('Url'));
        system.debug(lockedUrl);
        return lockedUrl;
    }


    public String generateValueForMultiSelectUpdate(String input) {
        if(input != null) {
            List<String> elemArray = input.split(';');
            String jsonArray = (String)JSON.serialize(elemArray);
            return jsonArray;
        }
        else return '["Not specified"]';
    }

    public Date generateDate(Date datetoreturn){
        if(datetoreturn == null)
            return Date.today();
        else
            return datetoreturn;
    }


    public FileMetadataWrapper(){
        System.debug('Empty constructor');
    }

}