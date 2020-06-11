/**
 * @author Sagie Twig
 * The apex class for trial document object - a wrapper for each trial item
 */

// The class for the trial documnet previeww
global class TrialDocumnetWrapper {
	@AuraEnabled
	global String documentTitle { get; set; }
	@AuraEnabled
	global String documentType { get; set; }
    @AuraEnabled
	global String contentId { get; set; }
    @AuraEnabled
	global String fileTitle { get; set; }
    @AuraEnabled
	global String fileExt { get; set; }
    @AuraEnabled
	global String fileLink { get; set; }
}