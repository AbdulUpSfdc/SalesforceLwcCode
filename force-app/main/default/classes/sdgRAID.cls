/*
Status Indicator - Sortable Data Grid
*/


global with sharing class sdgRAID implements sortablegrid.sdgIDataProvider 
{
   global static Boolean isUserSelectable()
   {
       return true;
   } 

   //Method to retrieve data:

   //SDG object - which is usually irrelevant in the case of custom Apex data providers

   //SDGRequest - provides the details of what's being requested:

   //  String ParentRecordID: recordId of the page

   //  Integer Pagesize: how many records the client is requesting

   //  Integer PageId: Number of the page of data (note this is 1 based)

   //  String SortColumn:  Id of column that's being searched for (Id from the SDGField created in LoadSDG)

   //  String SortOrder: A or D

   //  List<sortablegrid.SDGFilter> Filters: list of filters

   //  String FilterValue: value provided in UI for filtering

   //  String FilterOperator: value provided as operator ie GT greater than, = equals, etc

   //  Note there are other fields available in the request, but they're for routing to other data providers - in this case, you can ignore them.

   //

   global static sortablegrid.SDGResult getData(sortablegrid.SDG coreSDG,  sortablegrid.SDGRequest request)
   {
       string recId = request.ParentRecordId;
       sortablegrid.SDGResult result = new sortablegrid.SDGResult();
       try
       {
           integer dataoffset = (request.pageid-1) * request.pagesize;
           integer datalimit = request.PageSize;         
           List<String> filters = new List<String>();
           //Filter Options        
           system.debug(request.Filters);
           if (request.Filters!=null)
           {
               for(sortablegrid.SDGFilter filter: request.filters)
               {
                   String  fo = filter.FilterOperator;
                   String fv = String.escapeSingleQuotes(filter.FilterValue.trim());
                   String fid = filter.SDGFieldID;
                   if (fid == '1') //this maps to the SDGField with ID=1 => field is 'Log Number'
                   {
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('Name = \'' + fv + '\'');
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('Name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('Name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(Not Name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('Name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('Name like \'%' + fv + '\'');
                           }
                       }
                   }
                   if (fid == '2') //this maps to the SDGField with ID=2 => field is 'Type'
                   {
                       system.debug(fo);
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('RecordType.Name = \'' + fv + '\'');
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('RecordType.Name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('RecordType.Name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(Not RecordType.Name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('RecordType.Name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('RecordType.Name like \'%' + fv + '\'');
                           }
                       }
                   }
                   if (fid == '3') //this maps to the SDGField with ID=3 => field is 'Primary Owner'
                   {
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('bw_primary_owner__r.Name = \'' + fv + '\'');
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('bw_primary_owner__r.Name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('bw_primary_owner__r.Name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(Not bw_primary_owner__r.Name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('bw_primary_owner__r.Name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('bw_primary_owner__r.Name like \'%' + fv + '\'');
                           }
                       }
                   }
                   if (fid == '4') //this maps to the SDGField with ID=4 => field is 'Status'
                   {
                            system.debug(fo);
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('bw_status__c = \'' + fv + '\'');
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('bw_status__c != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('bw_status__c like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(not bw_status__c like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('bw_status__c like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('bw_status__c like \'%' + fv + '\'');
                           }
                       }
                    }
                    if (fid == '5') //this maps to the SDGField with ID=5 => field is 'Due Date'
                    {          
                        system.debug(fo);
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('BW_due_date__c = ' + fv);
                           }
                           if (fo == 'GT')
                           {
                               filters.add('BW_due_date__c > ' + fv);
                           }
                           if (fo == 'LT')
                           {
                               filters.add('BW_due_date__c < ' + fv);
                           }
                       } 
                       else
                       {
                           if (fo == 'TOMORROW')
                           {
                               filters.add('BW_due_date__c = TOMORROW');
                           }
                           if (fo == 'TODAY')
                           {
                               filters.add('BW_due_date__c = TODAY');
                           }
                           if (fo == 'YESTERDAY')
                           {
                               filters.add('BW_due_date__c = YESTERDAY');
                           }
                           if (fo == 'NEXT_WEEK')
                           {
                               filters.add('BW_due_date__c = NEXT_WEEK');
                           }
                           if (fo == 'THIS_WEEK')
                           {
                               filters.add('BW_due_date__c = THIS_WEEK');
                           }
                           if (fo == 'LAST_WEEK')
                           {
                               filters.add('BW_due_date__c = LAST_WEEK');
                           }
                           if (fo == 'NEXT_MONTH')
                           {
                               filters.add('BW_due_date__c = NEXT_MONTH');
                           }
                           if (fo == 'THIS_MONTH')
                           {
                               filters.add('BW_due_date__c = THIS_MONTH');
                           }
                           if (fo == 'LAST_MONTH')
                           {
                               filters.add('BW_due_date__c = LAST_MONTH');
                           }
                           if (fo == 'NEXT_QUARTER')
                           {
                               filters.add('BW_due_date__c = NEXT_QUARTER');
                           }
                           if (fo == 'THIS_QUARTER')
                           {
                               filters.add('BW_due_date__c = THIS_QUARTER');
                           }
                           if (fo == 'LAST_QUARTER')
                           {
                               filters.add('BW_due_date__c = LAST_QUARTER');
                           }
                           if (fo == 'NEXT_YEAR')
                           {
                               filters.add('BW_due_date__c = NEXT_YEAR');
                           }
                           if (fo == 'THIS_YEAR')
                           {
                               filters.add('BW_due_date__c = THIS_YEAR');
                           }
                           if (fo == 'LAST_YEAR')
                           {
                               filters.add('BW_due_date__c = LAST_YEAR');
                           }
                       }
                    }
                    if (fid == '6') //this maps to the SDGField with ID=6 => field is 'Workstream'
                    {
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('BW_Workstream_Parent__r.Name = ' + fv);
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('BW_Workstream_Parent__r.Name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('BW_Workstream_Parent__r.Name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(not BW_Workstream_Parent__r.Name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('BW_Workstream_Parent__r.Name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('BW_Workstream_Parent__r.Name like \'%' + fv + '\'');
                           }
                       }
                    }
               }
           }
           String filterstring = String.join(filters, ' AND ');
           if (!String.isblank(filterstring))
           {
               filterstring = 'WHERE ' + filterstring + ' AND bw_leadership_visibility__c = true';
           }
           String sSortClause = 'ORDER BY bw_workstream_parent__r.name ASC, bw_status__c ASC NULLS FIRST';
           if (String.isNotBlank(request.SortColumn))
           {
               if (request.sortOrder == 'A')
                   sSortClause = ' ORDER BY bw_workstream_parent__r.name ASC, bw_status__c ASC NULLS FIRST';
               else
                   sSortClause = ' ORDER BY bw_workstream_parent__r.name DESC, bw_status__c ASC NULLS LAST';
           }
           if (String.isblank(filterstring))
           {
               string defaultIssue = 'Issue';
               string defaultRisk = 'Risk';
               string defaultDecision = 'Decision';
               string defaultOpen = 'Open';
               string defaultNotStarted = 'Not Started';
               string defaultInProgress = 'In Progress';
               string defaultOverdue = 'Overdue';
               string defaultEscalated = 'Escalated';
               string filterDefault = 'bw_leadership_visibility__c = true and ((bw_status__c = :defaultNotStarted or bw_status__c = :defaultInProgress or bw_status__c = :defaultOpen or bw_status__c = :defaultOverdue or bw_status__c = :defaultEscalated) or recordtype.name = :defaultDecision)';
               filterstring = 'where ' + filterDefault;
           }
           string query = 'Select name, bw_description__c, bw_primary_owner__r.name, recordtype.name, bw_status__c, bw_due_date__c, bw_workstream_Parent__r.name from bw_raid_log__c ' + filterstring + ' ' + sSortClause + ' limit :datalimit offset :dataoffset';
           result.data = database.query(query);
           result.query=query; //Only used for the debug log
           result.FullQueryCount = 0;
           if (result.data!=null)
           {
               result.FullQueryCount = result.data.size();
           }
           result.pagecount = 1;
           result.isError = false;
           result.ErrorMessage = '';
       }
       catch (Exception ex)
       {
           result.isError = true;
           result.ErrorMessage = ex.getMessage();
       }
       return result;
   }

   //Entry point to get the configuration.

   //Implement this to return a full SDG of fields and actions

   global sortablegrid.SDG LoadSDG(String SDGTag, String ParentRecordId)
   {
       system.debug('CustomDataProviderExample:LoadSDG');
       sortablegrid.SDG CoreSDG = new sortablegrid.SDG( 'CustomDataProviderExample' );
       CoreSDG.SDGFields = getFields();
       return CoreSDG;
   }

   //Specify the behaviour of the grid - ie which fields to display on the page:

   //String ID - used to key filters back to the request

   //String Label: Column Header text

   //String ColumnName: Name within the SOQL - used by the LC to retrieve the value from the query results

   //String FieldType: STRING, NUMBER, DATE etc - determines rendering

   //String FieldStyle: Custom Renderer options:  Summarize:Total, Age etc

   //Boolean canSort: Make the columns click to sort (does not actually perform sorting)

   //Boolean canFilter: Renders a filter component (does not actually perform filtering)

   //Boolean isHTMLFormatted: Do you want to render the output as raw unescaped html.  Usually false.

   //List<sortablegrid.AuraSelectOption> options: List of piclist options for dropdowns for filters

   //Integer FieldOrder: order on the page

   private List<sortablegrid.SDGField> GetFields()
   {
       List<sortablegrid.SDGField> fields = new List<sortablegrid.SDGField>();
       fields.add( new sortablegrid.SDGField('1', 'Log Number', 'name', 'STRING', '', true, true, false, null, 1));
       fields.add( new sortablegrid.SDGField('2', 'Type', 'RecordType.Name', 'STRING', '', true, true, false, null, 2));
       fields.add( new sortablegrid.SDGField('3', 'Primary Owner', 'BW_Primary_Owner__r.name', 'STRING', '', true, true, false, null, 3));
       fields.add( new sortablegrid.SDGField('4', 'Status', 'BW_Status__c', 'STRING', '', true, true, false, null, 4));
       fields.add( new sortablegrid.SDGField('5', 'Due Date', 'BW_Due_Date__c', 'DATE', '', true, true, false, null, 5));
       fields.add( new sortablegrid.SDGField('6', 'Workstream', 'BW_Workstream_Parent__r.Name', 'STRING', '', true, true, false, null, 6));      
       fields.add( new sortablegrid.SDGField('7', 'Description', 'bw_Description__c', 'STRING', '', false, false, false, null, 7));
       return fields;
   }
}