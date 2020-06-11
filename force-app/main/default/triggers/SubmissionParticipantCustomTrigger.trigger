trigger SubmissionParticipantCustomTrigger on Simploud__Submission_Participant__c (after insert, after update) {
	List<Simploud__Submission__Share> shareList = new List<Simploud__Submission__Share>();
    for (Simploud__Submission_Participant__c part : Trigger.new)
    {
        Simploud__Submission__Share shareObject = new Simploud__Submission__Share();
        shareObject.ParentId = part.Simploud__Submission__c;
        shareObject.RowCause = Schema.Simploud__Submission__Share.RowCause.Manual;        
        shareObject.AccessLevel = 'Edit';
        shareObject.UserOrGroupId = part.Simploud__Participant__c;
        IF (Trigger.IsUpdate)
        {
            String oldParticipant = Trigger.oldMap.get(part.Id).Simploud__Participant__c;
            String newParticipant = part.Simploud__Participant__c;
            if (oldParticipant != newParticipant)
            {
                shareList.add(shareObject);
            }

        }
        ELSE 
        {
            shareList.add(shareObject);
        }
    }
    
    IF (shareList.size() > 0)
    {
        Insert shareList;
    }
    
}