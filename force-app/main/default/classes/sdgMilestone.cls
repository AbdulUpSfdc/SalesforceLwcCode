/*
Status Indicator - Sortable Data Grid
*/


global with sharing class sdgMilestone implements sortablegrid.sdgIDataProvider 
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
           
           string filterMonth = '';
           if(recId != null)
           {
               string queryMonth = 'Select bw_month_ending__c from bw_status_summary__c where Id = :recId';
               bw_status_summary__c resultMonth = database.query(queryMonth);
               integer varMonth = resultMonth.BW_Month_Ending__c.month();
               integer varYear = resultMonth.BW_Month_Ending__c.year();
               filterMonth = 'calendar_month(bw_planned_date__c) = :varMonth and calendar_year(bw_planned_date__c) = :varYear';
           }

           
           system.debug(request.Filters);
           if (request.Filters!=null)
           {
               for(sortablegrid.SDGFilter filter: request.filters)
               {
                   String  fo = filter.FilterOperator;
                   String fv = String.escapeSingleQuotes(filter.FilterValue.trim());
                   String fid = filter.SDGFieldID;
                   System.debug(fid);
                   if (fid == '1') //this maps to the SDGField with ID=1 => field is 'Milestone Name'
                   {
                       system.debug(fo); 
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
                   if (fid == '2') //this maps to the SDGField with ID=2 => field is 'Workstream'
                    {
                        system.debug(fo); 
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('BW_Workstream__r.Name = ' + fv);
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('BW_Workstream__r.Name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('BW_Workstream__r.Name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(not BW_Workstream__r.Name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('BW_Workstream__r.Name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('BW_Workstream__r.Name like \'%' + fv + '\'');
                           }
                       }
                    }
                    if (fid == '3') //this maps to the SDGField with ID=3 => field is 'Planned Date'
                    {        
                        system.debug(fo); 
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('BW_planned_date__c = ' + fv);
                           }
                           if (fo == 'GT')
                           {
                               filters.add('BW_planned_date__c > ' + fv);
                           }
                           if (fo == 'LT')
                           {
                               filters.add('BW_planned_date__c < ' + fv);
                           }
                       } 
                       else
                       {
                           if (fo == 'TOMORROW')
                           {
                               filters.add('BW_planned_date__c = TOMORROW');
                           }
                           if (fo == 'TODAY')
                           {
                               filters.add('BW_planned_date__c = TODAY');
                           }
                           if (fo == 'YESTERDAY')
                           {
                               filters.add('BW_planned_date__c = YESTERDAY');
                           }
                           if (fo == 'NEXT_WEEK')
                           {
                               filters.add('BW_planned_date__c = NEXT_WEEK');
                           }
                           if (fo == 'THIS_WEEK')
                           {
                               filters.add('BW_planned_date__c = THIS_WEEK');
                           }
                           if (fo == 'LAST_WEEK')
                           {
                               filters.add('BW_planned_date__c = LAST_WEEK');
                           }
                           if (fo == 'NEXT_MONTH')
                           {
                               filters.add('BW_planned_date__c = NEXT_MONTH');
                           }
                           if (fo == 'THIS_MONTH')
                           {
                               filters.add('BW_planned_date__c = THIS_MONTH');
                           }
                           if (fo == 'LAST_MONTH')
                           {
                               filters.add('BW_planned_date__c = LAST_MONTH');
                           }
                           if (fo == 'NEXT_QUARTER')
                           {
                               filters.add('BW_planned_date__c = NEXT_QUARTER');
                           }
                           if (fo == 'THIS_QUARTER')
                           {
                               filters.add('BW_planned_date__c = THIS_QUARTER');
                           }
                           if (fo == 'LAST_QUARTER')
                           {
                               filters.add('BW_planned_date__c = LAST_QUARTER');
                           }
                           if (fo == 'NEXT_YEAR')
                           {
                               filters.add('BW_planned_date__c = NEXT_YEAR');
                           }
                           if (fo == 'THIS_YEAR')
                           {
                               filters.add('BW_planned_date__c = THIS_YEAR');
                           }
                           if (fo == 'LAST_YEAR')
                           {
                               filters.add('BW_planned_date__c = LAST_YEAR');
                           }
                       }
                    }
                    if (fid == '4') //this maps to the SDGField with ID=4 => field is 'Actual Date'
                    {        
                 system.debug(fo);       
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('BW_actual_date__c = ' + fv);
                           }
                           if (fo == 'GT')
                           {
                               filters.add('BW_actual_date__c > ' + fv);
                           }
                           if (fo == 'LT')
                           {
                               filters.add('BW_actual_date__c < ' + fv);
                           }
                       } 
                       else
                       {
                           if (fo == 'TOMORROW')
                           {
                               filters.add('BW_actual_date__c = TOMORROW');
                           }
                           if (fo == 'TODAY')
                           {
                               filters.add('BW_actual_date__c = TODAY');
                           }
                           if (fo == 'YESTERDAY')
                           {
                               filters.add('BW_actual_date__c = YESTERDAY');
                           }
                           if (fo == 'NEXT_WEEK')
                           {
                               filters.add('BW_actual_date__c = NEXT_WEEK');
                           }
                           if (fo == 'THIS_WEEK')
                           {
                               filters.add('BW_actual_date__c = THIS_WEEK');
                           }
                           if (fo == 'LAST_WEEK')
                           {
                               filters.add('BW_actual_date__c = LAST_WEEK');
                           }
                           if (fo == 'NEXT_MONTH')
                           {
                               filters.add('BW_actual_date__c = NEXT_MONTH');
                           }
                           if (fo == 'THIS_MONTH')
                           {
                               filters.add('BW_actual_date__c = THIS_MONTH');
                           }
                           if (fo == 'LAST_MONTH')
                           {
                               filters.add('BW_actual_date__c = LAST_MONTH');
                           }
                           if (fo == 'NEXT_QUARTER')
                           {
                               filters.add('BW_actual_date__c = NEXT_QUARTER');
                           }
                           if (fo == 'THIS_QUARTER')
                           {
                               filters.add('BW_actual_date__c = THIS_QUARTER');
                           }
                           if (fo == 'LAST_QUARTER')
                           {
                               filters.add('BW_actual_date__c = LAST_QUARTER');
                           }
                           if (fo == 'NEXT_YEAR')
                           {
                               filters.add('BW_actual_date__c = NEXT_YEAR');
                           }
                           if (fo == 'THIS_YEAR')
                           {
                               filters.add('BW_actual_date__c = THIS_YEAR');
                           }
                           if (fo == 'LAST_YEAR')
                           {
                               filters.add('BW_actual_date__c = LAST_YEAR');
                           }
                       }
                    }
                    if (fid == '5') //this maps to the SDGField with ID=5 => field is 'Status'
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
               }
           }

           String filterstring = String.join(filters, ' AND ');
           if (!String.isblank(filterstring))
           {
               filterstring = 'WHERE ' + filterstring + ' AND ' + filterMonth;
           }
           String sSortClause = 'ORDER BY bw_workstream__r.name ASC, bw_status__c ASC NULLS FIRST';
           if (String.isNotBlank(request.SortColumn))
           {
               if (request.sortOrder == 'A')
                   sSortClause = ' ORDER BY bw_workstream__r.name ASC, bw_status__c ASC NULLS FIRST';
               else
                   sSortClause = ' ORDER BY bw_workstream__r.name DESC, bw_status__c ASC NULLS LAST';
           }
           
           if (String.isblank(filterstring))
           {
               filterstring = 'where ' + filterMonth;
           }

           string query = 'Select name, bw_planned_date__c, bw_actual_date__c, bw_status__c, bw_workstream__r.name from bw_milestone__c ' + filterstring + ' ' + sSortClause + ' limit :datalimit offset :dataoffset';
    system.debug(query);    
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

//       CoreSDG.SDGActions = getActions();

       CoreSDG.SDGFields = getFields();

       return CoreSDG;
   }

   //Specify the actions available on the grid:

   //String Id: unique identifier

   //String Label: for the link

   //String Event: Lightning Event to raise

   //String Type: Render as a 'List Button', 'Row Button', 'Row', 'List', 'Multi List'

   //String Payload: payload for the event - can be parameterised with #delimited# values

   //String Icon: Icon to render

   //Integer actionorder: Order of buttons/menuitems

   private List<sortablegrid.SDGAction> GetActions()
   {
       List<sortablegrid.SDGAction> actions = new List<sortablegrid.SDGAction>();

       actions.add(new sortablegrid.SDGAction('1', 'New', 'e.force:createRecord', 'List Button', '{"entityApiName": "Contact"}', 'utility:new', 1));

       actions.add(new sortablegrid.SDGAction('2', 'Edit', 'e.force:editRecord', 'Row Button', '{"recordId": "#Id#"}', 'utility:edit', 2));

       actions.add(new sortablegrid.SDGAction('3', 'Edit Creator', 'e.force:editRecord', 'Row Button', '{"recordId": "#CreatedBy.Id#"}', 'utility:edit',3 ));

       return actions;
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

       fields.add( new sortablegrid.SDGField('1', 'Milestone Name', 'name', 'STRING', '', true, true, false, null, 1));

       fields.add( new sortablegrid.SDGField('2', 'Workstream', 'bw_workstream__r.name', 'STRING', '', true, true, false, null, 2));

       fields.add( new sortablegrid.SDGField('3', 'Planned Date', 'BW_Planned_Date__c', 'DATE', '', true, true, false, null, 3));

       fields.add( new sortablegrid.SDGField('4', 'Actual Date', 'BW_Actual_Date__c', 'DATE', '', true, true, false, null, 4));

       fields.add( new sortablegrid.SDGField('5', 'Status', 'BW_Status__c', 'STRING', '', true, true, false, null, 5));

       return fields;
   }
}