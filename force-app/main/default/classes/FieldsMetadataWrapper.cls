/*
    Created by RedTag129 on 12.06.2019
*/
public class FieldsMetadataWrapper {

	public class metadata {
		public String typeZ {get;set;}

		public metadata(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'type') {
							typeZ = parser.getText();
						} else {
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	
	public d d {get;set;} 

	public FieldsMetadataWrapper(JSONParser parser) {
		while (parser.nextToken() != System.JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
					if (text == 'd') {
						d = new d(parser);
					} else {
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	
	
	public class d {
		public List<Results> results {get;set;} 

		public d(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'results') {
							results = arrayOfResults(parser);
						} else {
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Results {
		public metadataMain metadata {get;set;} 
		public String EntityPropertyName {get;set;} 
		public String Title {get;set;}
    public String InternalName {get;set;} 
		public String StaticName {get;set;} 
    public String TypeAsString{get;set;}


		public Results(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == '__metadata') {
							metadata = new metadataMain(parser);
						}
                         else if (text == 'EntityPropertyName') {
							EntityPropertyName = parser.getText();
						}
                          else if (text == 'InternalName') {
							InternalName = parser.getText();
						}
                        
                        else if (text == 'StaticName') {
							StaticName = parser.getText();
						} 
                         else if (text == 'TypeAsString') {
							TypeAsString = parser.getText();
						} 
                         else if (text == 'Title') {
							Title = parser.getText();
						} 

                         else {
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class metadataMain {
		public String id {get;set;} 
		public String uri {get;set;} 
		public String typeZ {get;set;} 
		public metadataMain(JSONParser parser) {
			while (parser.nextToken() != System.JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
						if (text == 'id') {
							id = parser.getText();
						} else if (text == 'uri') {
							uri = parser.getText();
						} else if (text == 'type') {
							typeZ = parser.getText();
						} else {
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	

	
	
	
	
	public static FieldsMetadataWrapper parse(String json) {
		System.JSONParser parser = System.JSON.createParser(json);
		return new FieldsMetadataWrapper(parser);
	}
	
	public static void consumeObject(System.JSONParser parser) {
		Integer depth = 0;
		do {
			System.JSONToken curr = parser.getCurrentToken();
			if (curr == System.JSONToken.START_OBJECT || 
				curr == System.JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == System.JSONToken.END_OBJECT ||
				curr == System.JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}
	

    private static List<String> arrayOfString(System.JSONParser p) {
        List<String> res = new List<String>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(p.getText());
        }
        return res;
    }


    private static List<Results> arrayOfResults(System.JSONParser p) {
        List<Results> res = new List<Results>();
        if (p.getCurrentToken() == null) p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Results(p));
        }
        return res;
    }

    public FieldsMetadataWrapper(){
        System.debug('Empty constructor');
    }

}