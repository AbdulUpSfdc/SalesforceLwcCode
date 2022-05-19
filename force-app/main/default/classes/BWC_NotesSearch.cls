public with sharing class BWC_NotesSearch {

    public class NotesSearchRequest{
        public String noteSortTypeEnum;
        public NoteFilterParams noteFilterParams;
        public NotePaginationParams notePaginationParams;
    }

    public class NoteFilterParams {
        public List<Ban> bans;
        public String callingApp;
        String[] appIds;
        String createdTimeStart;
        String createdTimeEnd;
    }

    public class NotePaginationParams {
        public Integer pageSize;
        public Integer pageNumber;
    }

    public class Ban {

        public String accountNumber;
        public String accountType;

        public Ban(String accountNumber, String accountType) {
            this.accountNumber = accountNumber;
            this.accountType = accountType;
        }

    }

    public class NotesSearchResponse extends BWC_Callout.CalloutResponse{
       public List<Note> notes;
       public Integer totalCount;
       public List<AdditionalInfo> additionalInfoArray;
    }

    public class Note {
        public String ban;
        public String id;
        public String createdByUserType;
        public String createdByUserId;
        public String createdTime;
        public String updatedByUserType;
        public String updatedByUserId;
        public String updatedTime;
        public String category;
        public String secondaryCategory;
        public String tertiaryCategory;
        public String accountType;
        public String appId;
        public String noteTitle;
        public String noteBody;
        public String noteType;
        public String callIntent;
        public String contactType;
        public String deviceType;
        public String deviceErrorCode;
        public String problemCode;
        public String action;
        public String resolution;
        public String channel;
        public String subChannel;
        public String store;
        public String customerId;
        public String subscriberId;
        public String customerSessionId;
        public AdditionalAttributes additionalAttributes;
    }

    public class AdditionalAttributes {
        public String expiryDate;
        public String insertedBy;
        public String insertedTime;
        public String ttl;
    }

    public class AdditionalInfo {
        public String key;
        public String value;
    }

}