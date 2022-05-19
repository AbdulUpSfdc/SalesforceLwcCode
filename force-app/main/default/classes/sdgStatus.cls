/*
Status Indicator - Sortable Data Grid
*/
global with sharing class sdgStatus implements sortablegrid.sdgIDataProvider 
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
               filterMonth = 'calendar_month(bw_week_ending__c) = :varMonth and calendar_year(bw_week_ending__c) = :varYear';
           }         
           if (request.Filters!=null)
           {
               for(sortablegrid.SDGFilter filter: request.filters)
               {
                   String  fo = filter.FilterOperator;
                   String fv = String.escapeSingleQuotes(filter.FilterValue.trim());
                   String fid = filter.SDGFieldID;
                   if (fid == '1') //this maps to the SDGField with ID=1 => field is 'Status Indicator Name'
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
                   if (fid == '2') //this maps to the SDGField with ID=2 => field is 'Workstream'
                   {
                       system.debug(fo);
                       if  (String.isNotBlank(fv))
                       {
                           if (fo == '=')
                           {
                               filters.add('bw_workstream__r.name = \'' + fv + '\'');
                           }
                           if (fo == 'NOT=')
                           {
                               filters.add('bw_workstream__r.name != \'' + fv + '\'');
                           }
                           if(fo=='CONTAINS')
                           {
                               filters.add('bw_workstream__r.name like \'%' + fv + '%\'');
                           }
                           if(fo=='NOTCONTAINS')
                           {
                               filters.add('(Not bw_workstream__r.name like \'%' + fv + '%\')');
                           }
                           if (fo=='STARTS')
                           {
                               filters.add('bw_workstream__r.name like \'' + fv + '%\'');
                           }
                           if (fo=='ENDS')
                           {
                               filters.add('bw_workstream__r.name like \'%' + fv + '\'');
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

           String sSortClause = 'ORDER BY BW_Week_Ending__c DESC, name ASC NULLS LAST';
           if (String.isNotBlank(request.SortColumn))
           {
               if (request.sortOrder == 'A')
                   sSortClause = ' ORDER BY BW_Week_Ending__c ASC, name ASC NULLS FIRST';
               else
                   sSortClause = ' ORDER BY BW_Week_Ending__c DESC, name ASC NULLS LAST';
           }

           if (String.isblank(filterstring))
           {
               string defaultWorkstream = 'Program';
               string filterWorkstream = 'bw_workstream__r.name = :defaultWorkstream';
               filterstring = 'where ' + filterMonth + ' and ' + filterWorkstream;
           }
           
           string query = 'Select name, bw_workstream__r.name, bw_report_status__c, BW_Week_Ending__c, BW_Schedule_Indicator__c, BW_Budget_Indicator__c, BW_Scope_Indicator__c, BW_Resources_Indicator__c, BW_Trending_Indicator__c from bw_status_indicator__c ' + filterstring + ' ' + sSortClause + ' limit :datalimit offset :dataoffset';
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
       fields.add( new sortablegrid.SDGField('1', 'Status Indicator Name', 'name', 'STRING', '', false, true, false, null, 1));
       fields.add( new sortablegrid.SDGField('2', 'Workstream', 'bw_workstream__r.name', 'STRING', '', false, true, false, null, 2));
       fields.add( new sortablegrid.SDGField('3', 'Report Status', 'BW_Report_Status__c', 'STRING', '', true, false, false, null, 3));
       fields.add( new sortablegrid.SDGField('4', 'Week Ending', 'BW_Week_Ending__c', 'DATE', '', true, false, false, null, 4));
       fields.add( new sortablegrid.SDGField('5', 'Schedule', 'BW_Schedule_Indicator__c', 'STRING', '', false, false, true, null, 5));
       fields.add( new sortablegrid.SDGField('6', 'Scope', 'BW_Scope_Indicator__c', 'STRING', '', false, false, true, null, 6));
       fields.add( new sortablegrid.SDGField('7', 'Resources', 'BW_Resources_Indicator__c', 'STRING', '', false, false, true, null, 7));
       fields.add( new sortablegrid.SDGField('8', 'Trending', 'BW_Trending_Indicator__c', 'STRING', '', false, false, true, null, 8));
       return fields;
   }
}