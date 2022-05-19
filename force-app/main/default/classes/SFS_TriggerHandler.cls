public virtual inherited sharing class SFS_TriggerHandler {

    /**
     *  Master method run from every trigger. Looks up metadata to determine handlers to run.
     */
    public static void run() {

        // Discover SObject type -- cannot do this directly, have to inspect first object in one of the lists
        String objectType = String.valueOf(Trigger.isDelete ? Trigger.old[0].getSObjectType() : Trigger.new[0].getSObjectType());

        System.debug(format('Starting trigger run for {0} on SObject {1}', Trigger.operationType, objectType));

        // Get handlers along with any trigger control
        List<SFS_Trigger_Mapping__mdt> mappings = [
            SELECT Id, DeveloperName, Object_API_Name__c, Apex_Handler_Class__c, Disabled__c, Order__c,
                (SELECT
                    Id, Disable_All__c, Disable_All_After__c, Disable_All_Before__c, Disable_All_Calculate__c, Disable_All_Validate__c, Disable_Calculate__c,
                    Disable_Initialize__c, Disable_PostDelete__c, Disable_PostInsert__c, Disable_PostInsertUpdateDelete__c, Disable_PostUpdate__c, Disable_PostUpsert__c,
                    Disable_PreValidate__c, Disable_PreValidateDelete__c, Disable_Validate__c, Expires__c, User_Name__c
                FROM Trigger_Controls__r)
            FROM SFS_Trigger_Mapping__mdt 
            WHERE Object_API_Name__c = :objectType 
            ORDER BY Order__c, Apex_Handler_Class__c];
        System.debug(format('{0} handlers found for SObject {1}', mappings.size(), objectType));

        // Run any handlers
        for (SFS_Trigger_Mapping__mdt mapping : mappings) {

            String handlerIdentifier = format('handler class {0} for {1} on SObject {2}', mapping.Apex_Handler_Class__c, Trigger.operationType, objectType);

            try {

                if (mapping.Disabled__c == true) {
                    System.debug(format('DISABLE IN TRIGGER MAPPING: {0}', handlerIdentifier));
                    continue;
                }

                // Attempt handler class type type
                Type handlerClassType = Type.forName(mapping.Apex_Handler_Class__c);
                if (handlerClassType == null) {
                    throw new TriggerException('Type for Apex class not found: ' + handlerIdentifier);
                }

                // Attempt to get handler instances
                SFS_TriggerHandler handlerInstance;
                try {
                    handlerInstance = (SFS_TriggerHandler)handlerClassType.newInstance();
                }
                catch (System.TypeException e) {
                    throw new TriggerException(format('Does not extend class SFS_TriggerHandler: {0}: {1}', handlerIdentifier, e.getMessage()), e);
                }

                System.debug(format('STARTING {0}', handlerIdentifier));

                handlerInstance.onTrigger(mapping, handlerIdentifier);

                System.debug(format('FINISHED {0}', handlerIdentifier));

            }
            catch (System.Exception e) {
                // Wrap exception in context explanation and throw
                throw new TriggerException(format('Exception in {0}: ', handlerIdentifier) + e.getMessage(), e);
            }

        }

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Trigger control

    //Trigger control instances mapped by Object API Name
    private static Map<String, SFS_Trigger_Control__mdt> triggerControlMap = new Map<String, SFS_Trigger_Control__mdt>();

    // Developer name of SFS_Trigger_Mapping__mdt record, used as unique identifier for the trigger handler.
    private String triggerMappingName;

    // Identifying text uses in messages.
    private String handlerIdentifier;

    // Trigger control for current instance.
    private SFS_Trigger_Control__mdt triggerControl;

    /**
     * Returns trigger control record for the object associated with this trigger instance.
     * @return
     */
    protected SFS_Trigger_Control__mdt getTriggerControl() {

        SFS_Trigger_Control__mdt triggerControl = getTriggerControl(this.triggerMappingName);
        if (triggerControl == null) {
            // Use new record as default, which defaults to everything enabled.
            triggerControl = new SFS_Trigger_Control__mdt();
        }
    
        return triggerControl;

    }

    /*
        Returns trigger control record for the object specified by sObjectApiName.
    */
    private static SFS_Trigger_Control__mdt getTriggerControl(String triggerMappingName) {

        // Find already mapped instance
        SFS_Trigger_Control__mdt triggerControl = triggerControlMap.get(triggerMappingName);
        return triggerControl;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Trigger methods

    /*
        Entry method called from the trigger itself
    */
    public void onTrigger(SFS_Trigger_Mapping__mdt mapping, String handlerIdentifier) {

        this.triggerMappingName = mapping.DeveloperName;
        this.handlerIdentifier = handlerIdentifier;

        // Find any valid trigger control record
        for (SFS_Trigger_Control__mdt triggerControl : mapping.Trigger_Controls__r) {
            if ((triggerControl.Expires__c == null || triggerControl.Expires__c > Datetime.now()) &&
                (String.isBlank(triggerControl.User_Name__c) || triggerControl.User_Name__c == UserInfo.getUserName())) {

                // Found a valid one
                triggerControlMap.put(this.triggerMappingName, mapping.Trigger_Controls__r[0]);
                break;

            }
        }

        this.triggerControl = getTriggerControl();

        if (this.triggerControl.Disable_All__c) {
            System.debug(format('ALL triggers DISABLED: {0}', handlerIdentifier));
            return;
        }

        runHandlers();

    }

    /*
        Run all trigger handlers.
    */
    protected virtual void runHandlers() {

        if (this.isBefore) {

            if (this.triggerControl.Disable_All_Before__c) {
                System.debug(format('All BEFORE triggers DISABLED: {0}', this.handlerIdentifier));
                return;
            }

            if (this.isDelete) {

                if (!this.triggerControl.Disable_PreValidateDelete__c && !this.triggerControl.Disable_All_Validate__c) {
                    System.debug(format('+preValidateDelete: {0}', this.handlerIdentifier));
                    preValidateDelete(this.TriggerRecords);
                    System.debug(format('-preValidateDelete: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('preValidateDelete DISABLED: {0}', this.handlerIdentifier));
                }

            }
            else {

                beforeUpsert(this.TriggerRecords);

            }

        }
        else if (this.isAfter) {

            if (this.triggerControl.Disable_All_After__c) {

                System.debug(format('All AFTER triggers DISABLED: {0}', this.handlerIdentifier));
                return;
    
            }

            if (!this.triggerControl.Disable_PostInsertUpdateDelete__c) {
                System.debug(format('+postInsertUpdateDelete: {0}', this.handlerIdentifier));
                postInsertUpdateDelete(this.TriggerRecords);
                System.debug(format('-postInsertUpdateDelete: {0}', this.handlerIdentifier));
            }
            else {
                System.debug(format('postInsertUpdateDelete DISABLED: {0}', this.handlerIdentifier));
            }

            if (this.isInsert || this.isUndelete) {

                if (!this.triggerControl.Disable_PostInsert__c) {
                    System.debug(format('+postInsert: {0}', this.handlerIdentifier));
                    postInsert(this.TriggerRecords);
                    System.debug(format('-postInsert: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('postInsert DISABLED: {0}', this.handlerIdentifier));
                }

                if (!this.triggerControl.Disable_PostUpsert__c) {
                    System.debug(format('+postUpsert: {0}', this.handlerIdentifier));
                    postUpsert(this.TriggerRecords);
                    System.debug(format('-postUpsert: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('postUpsert DISABLED: {0}', this.handlerIdentifier));
                }

            }
            else if (this.isUpdate) {

                if (!this.triggerControl.Disable_PostUpdate__c) {
                    System.debug(format('+postUpdate: {0}', this.handlerIdentifier));
                    postUpdate(this.TriggerRecords);
                    System.debug(format('-postUpdate: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('postUpdate DISABLED: {0}', this.handlerIdentifier));
                }

                if (!this.triggerControl.Disable_PostUpsert__c) {
                    System.debug(format('+postUpsert: {0}', this.handlerIdentifier));
                    postUpsert(this.TriggerRecords);
                    System.debug(format('-postUpsert: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('postUpsert DISABLED: {0}', this.handlerIdentifier));
                }

            }
            else if (this.isDelete) {

                if (!this.triggerControl.Disable_PostDelete__c) {
                    System.debug(format('+postDelete: {0}', this.handlerIdentifier));
                    postDelete(this.TriggerRecords);
                    System.debug(format('-postDelete: {0}', this.handlerIdentifier));
                }
                else {
                    System.debug(format('postDelete DISABLED: {0}', this.handlerIdentifier));
                }

            }

        }        

    }

    /*
        Called before insert or update;
    */
    protected virtual void beforeUpsert(List<SObject> records) {

        SFS_Trigger_Control__mdt triggerControl = getTriggerControl();

        if (!triggerControl.Disable_PreValidate__c && !triggerControl.Disable_All_Validate__c) {
            System.debug(format('+preValidate: {0}', handlerIdentifier));
            preValidate(records);
            System.debug(format('-preValidate: {0}', handlerIdentifier));
        }
        else {
            System.debug(format('preValidate DISABLED: {0}', this.handlerIdentifier));
        }

        if (this.isInsert) {

            if (!triggerControl.Disable_Initialize__c && !triggerControl.Disable_All_Calculate__c) {
                System.debug(format('+initialize: {0}', handlerIdentifier));
                initialize(this.TriggerRecords);
                System.debug(format('-initialize: {0}', handlerIdentifier));
            }
            else {
                System.debug(format('initialize DISABLED: {0}', this.handlerIdentifier));
            }

        }

        if (!triggerControl.Disable_Calculate__c && !triggerControl.Disable_All_Calculate__c) {
            System.debug(format('+calculate: {0}', handlerIdentifier));
            calculate(this.TriggerRecords);
            System.debug(format('-calculate: {0}', handlerIdentifier));
        }
        else {
            System.debug(format('calculate DISABLED: {0}', this.handlerIdentifier));
        }

        if (!triggerControl.Disable_Validate__c && !triggerControl.Disable_All_Validate__c) {
            System.debug(format('+validate: {0}', handlerIdentifier));
            validate(this.TriggerRecords);
            System.debug(format('-validate: {0}', handlerIdentifier));
        }
        else {
            System.debug(format('validate DISABLED: {0}', this.handlerIdentifier));
        }

    }

    /*
        Validate before any calculation is done -- to validate any values that must be correct before any calculation
    */
    protected virtual void preValidate(List<SObject> records) {}

    /*
        Initialize values on a new record
    */
    protected virtual void initialize(List<SObject> records) {}

    /*
        Calculate values on a new or updated record
    */
    protected virtual void calculate(List<SObject> records) {}

    /*
        Validate all values after calculations have taken place
    */
    protected virtual void validate(List<SObject> records) {}

    /*
        Do any pre-delete validation to potentially prevent deletion
    */
    protected virtual void preValidateDelete(List<SObject> records) {}

    /*
        Do any processing that should happen after insert, update, or delete
    */
    protected virtual void postInsertUpdateDelete(List<SObject> records) {}

    /*
        Do any processing that should happen only after insert (but not after update or delete)
    */
    protected virtual void postInsert(List<SObject> records) {}

    /*
        Do any processing that should happen only after update (but not after insert or delete)
    */
    protected virtual void postUpdate(List<SObject> records) {}

    /*
        Do any processing that should happen after insert OR update (but not after delete)
    */
    protected virtual void postUpsert(List<SObject> records) {}

    /*
        Do any processing that should happen after delete
    */
    protected virtual void postDelete(List<SObject> records) {}


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Trigger Abstractions	

    //Handling of errors within this instance
    private Set<Id> erroredIds = new Set<Id>();
    private List<SObject> erroredRecords = new List<SObject>();
    private List<SObject> triggerRecordsOverride = null;

    /*    
        Returns relevant set of records for processing in the trigger
        This includes management of errored records within the same instantiation, so that
        error records aren't presented to methods for downstream processing.
    */
    protected List<SObject> TriggerRecords {

        get {

            List<SObject> baseRecords = this.isDelete ? this.old : this.newRecords;

            if (triggerRecordsOverride != null) {
                return triggerRecordsOverride;
            }
            else if (!erroredRecords.isEmpty()) {

                triggerRecordsOverride = new List<SObject>();
                for (SObject baseRecord : baseRecords) {

                    if (baseRecord.Id != null) {
                        if (!erroredIds.contains(baseRecord.Id)) {
                            triggerRecordsOverride.add(baseRecord);
                        }
                    }
                    else {

                        // New record without an ID, have to compare Objects using ===
                        // Cannot use Set<SObject> because it compares using ==
                        Boolean isError = false;
                        for (SObject erroredRecord : erroredRecords) {
                            if (baseRecord === erroredRecord) {
                                isError = true;
                                break;
                            }
                        }

                        if (!isError) {
                            triggerRecordsOverride.add(baseRecord);
                        }

                    }

                }

                erroredRecords.clear();

                return triggerRecordsOverride;

            }
            else {
                return baseRecords;
            }

        }

    }

    /*    
        Add error to a record
    */
    protected void addError(SObject record, String errorString) {
        record.addError(errorString);
        if (record.Id != null) {
            erroredIds.add(record.Id);
        }
        erroredRecords.add(record);
    }

    /*    
        Return old records
    */
    protected List<SObject> oldRecords() {
        if (this.isUpdate || this.isDelete) {
            return this.old;
        }
        else {
            return null;
        }
    }

    /*    
        Return old record
    */
    protected SObject oldRecord(SObject record) {
        if (this.isUpdate || this.isDelete) {
            return this.oldMap.get(record.Id);
        }
        else {
            return null;
        }
    }

    /*    
        Return old field value
    */
    protected Object oldValue(SObject record, SObjectField field) {

        if (this.isUpdate || this.isDelete) {
            return oldRecord(record).get(field);
        }
        else {
            return null;
        }

    }

    /*
        Straight-through implementations of Trigger variables.
    */
    protected Boolean isExecuting {get {return Trigger.isExecuting;}}
    protected Boolean isInsert {get {return Trigger.isInsert;}}
    protected Boolean isUpdate {get {return Trigger.isUpdate;}}
    protected Boolean isDelete {get {return Trigger.isDelete;}}
    protected Boolean isBefore {get {return Trigger.isBefore;}}
    protected Boolean isAfter {get {return Trigger.isAfter;}}
    protected Boolean isUndelete {get {return Trigger.isUndelete;}}
    protected List<SObject> newRecords {get {return Trigger.new;}}  // "new" is keyword, have to rename
    protected Map<Id, SObject> newMap {get {return Trigger.newMap;}}
    protected List<SObject> old {get {return Trigger.old;}}
    protected Map<Id, SObject> oldMap {get {return Trigger.oldMap;}}
    protected System.TriggerOperation operationType {get {return Trigger.operationType;}}
    protected Integer size {get {return Trigger.size;}}

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Change detection

    /*    
        Returns true if field is changed in this trigger context.
        For all field changes:
            Null and blank are considered the same for a string
            Null and false are considered the same for a checkobx
    */
    protected Boolean isChangedField(SObject record, SObjectField field) {

        Object newValue = record.get(field);
        Object oldValue = oldValue(record, field);

        // Normalize values to null
        if (newValue == '' || newValue == false) {
            newValue = null;
        }
        if (oldValue == '' || oldValue == false) {
            newValue = null;
        }

        if (this.isInsert || this.isUndelete) {
            // For new record, consider the field changed if it's non-null in the new record
            return newValue != null;
        }
        else if (this.isDelete) {
            // For delete, consider field changed if old value it's non-null in the old record
            return oldValue != null;
        }
        else if (this.isUpdate) {
            return newValue != oldValue;
        }
        else {
            return false;
        }

    }

    /*    
        Returns true if any specified field is changed in this trigger context
    */
    protected Boolean isChangedAnyField(SObject record, Set<SObjectField> fields) {

        for (SObjectField field : fields) {
            if (isChangedField(record, field)) {
                return true;
            }
        }

        return false;
    }

    /*
        Returns true if field changed from specified value to some other value
    */
    protected Boolean isChangedFieldFrom(SObject record, SObjectField field, Object fromValue) {
        return oldValue(record, field) == fromValue && isChangedField(record, field);
    }

    /*    
        Returns true if field changed to specified value from some other value
    */
    protected Boolean isChangedFieldTo(SObject record, SObjectField field, Object toValue) {
        return isChangedField(record, field) && record.get(field) == toValue;
    }

    /*    
        Returns true if field changed from some value not in toValues to a value that is in toValues
    */
    protected Boolean isChangedFieldFromAnyTo(SObject record, SObjectField field, Set<String> toValues) {
        String oldValue = (String)oldValue(record, field);
        return isChangedField(record, field) && (oldValue == null || !toValues.contains(oldValue)) && toValues.contains((String)record.get(field));
    }

    /*
        Returns true if field changed and to a non-null value
    */
    protected Boolean isChangedFieldToNonNull(SObject record, SObjectField field) {
        return isChangedField(record, field) && record.get(field) != null;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TriggerControl helpers
    // These are for use during unit test setup.

    /*
        Set specified SFS_Trigger_Control__mdt for sObjectApiName. 
    */
    public static void setTriggerControl(String triggerMappingName, SObjectField triggerControlField) {

        SFS_Trigger_Control__mdt triggerControl = getTriggerControl(triggerMappingName);
        if (triggerControl == null) {
            triggerControl = new SFS_Trigger_Control__mdt(
                DeveloperName = triggerMappingName
            );
            triggerControlMap.put(triggerMappingName, triggerControl);
        }
        triggerControl.put(triggerControlField, true);

    }

    /*
        Disable all trigger control.
    */
    public static void clearTriggerControl() {
        triggerControlMap.clear();
    }

    public static String format(String stringToFormat, Object arg1) {
        return String.format(stringToFormat, new List<Object>{arg1});
    }

    public static String format(String stringToFormat, Object arg1, Object arg2) {
        return String.format(stringToFormat, new List<Object>{arg1, arg2});
    }

    public static String format(String stringToFormat, Object arg1, Object arg2, Object arg3) {
        return String.format(stringToFormat, new List<Object>{arg1, arg2, arg3});
    }

    /*
        Used here to throw exceptions.
    */
    public class TriggerException extends System.Exception {
    }

}