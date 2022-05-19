({
    getPicklistValuesFromController : function(component,event,helper){
        
        var action  = component.get("c.getInitValues");
        action.setParam("lstStrFieldNames",component.get("v.DefaultValueList"));
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state="SUCCESS"){
                var respObj = response.getReturnValue();
                //Set Default Values on filter form
                component.set("v.DefaultValueMap",respObj.mapDefaultValues);
                //Set Picklist values for dropdow/multiselects
                component.set("v.PicklistValueMap",respObj.mapFieldNameVSLstValues);
                var picklistMap = respObj.mapFieldNameVSLstValues;
                //Convert list of picklistvalues  to object type for multiselect picklists{name,value}
                for(var key in picklistMap){
                    if(component.find(key)!=null && picklistMap.hasOwnProperty(key)){
                        var lstArray = [] ;
                        lstArray = Object.values(picklistMap[key]);
                        var arrObj =[];
                        for(var i=0;i<lstArray.length;i++){
                            var options={value:lstArray[i],label:lstArray[i]};
                            arrObj.push(options);
                        }
                        if(key=='ProductsDiscussed__c')
                            component.set("v.opportunityTypeOptions",arrObj);
                        if(key=='CustomerType__c')
                            component.set("v.customerTypeOptions",arrObj);
                    }
               }
              
                //Convert list to object type for multiselect picklists{name,value} to specify default values
               var defaultArr = [];
                defaultArr.push(component.get("v.DefaultValueMap.ProductsDiscussed__c"));
                component.set("v.oppTypeDefault",defaultArr);
                var defaultCusTypeArr = [];
                var cusType = component.get("v.DefaultValueMap.CustomerType__c");
                if(cusType){
                    defaultCusTypeArr.push(cusType);
                    component.set("v.cusTypeDefault",defaultCusTypeArr);
                }
                helper.getDefaultValuesInJson(component,event,helper);
            }
        });
        $A.enqueueAction(action);
    },
    getTooltip : function(component, event, helper) {
        var storeTooltip = $A.get("$Label.c.ProspectStoreTooltipDesktop");
        var device = $A.get("$Browser.formFactor");
        if(device == 'PHONE') {
            storeTooltip = $A.get("$Label.c.ProspectStoreTooltipMobile");
        }
        component.set("v.storeTooltip", storeTooltip);
    },
    getLeadListNames : function(component,event,helper) {
        var action = component.get("c.getLeadListPickListValues");
        action.setCallback(this,function(response){
            var state=response.getState();
            if(state=="SUCCESS"){
                //component.set("v.LeadListName",response.getReturnValue());
                var lstArray = [];
                lstArray = response.getReturnValue();
                var arrObj = [];
                for(var i=0;i<lstArray.length;i++){
                    var options={'label':lstArray[i],'value':lstArray[i]};
                    arrObj.push(options);
                }
                // set LeadListName in the form of value and label
                component.set("v.LeadListName",arrObj);
            }
        });
        $A.enqueueAction(action);
    },

    getDefaultValuesInJson:function(component,event,helper){
        
        //Set the selected list name as the default filter 
        var mapDefaultValues = component.get("v.DefaultValueMap");
        console.log('****** mapDefaultValues ****** '+JSON.stringify(mapDefaultValues));
        var SelectedLeadListName = component.get("v.SelectedLeadListName");
        if(SelectedLeadListName != 'All Prospect Leads'){
            mapDefaultValues['LeadListName__c'] = component.get("v.SelectedLeadListName");
        }
        //Add all the filter defaults in the form of name and value pair
        for(var key in mapDefaultValues){
            if(mapDefaultValues.hasOwnProperty(key))
                helper.handleInput(component,key,mapDefaultValues[key]);
        }
        //Navigate to result page only in case of event invoke
        if( component.get("v.gotoResults")){
            //render component to get the values
            component.set("v.renderCmp",true);
            //Get default filter string 
            helper.createMapOfDefaultOperators(component,event,helper);
            component.set("v.renderCmp",false);
            //Set Filter options
			helper.setStrListFilterOptions(component,event,helper); 
            // insert default values in form of value and label
            helper.navigateToResultPage(component,event,helper);
        }
    },
   
    setPageReferenceValues:function(pageReference,component,event,helper){
        //set visibility
        component.set("v.renderCmp",pageReference.state.c__renderCmp);
        component.set("v.gotoResults",pageReference.state.c__gotoResults);
        component.set("v.strListFilterOptions",pageReference.state.c__strListFilterOptions);
        component.set("v.renderStoreFilter",pageReference.state.c__renderStoreFilter);
        //set SelectedLeadListName
        component.set("v.SelectedLeadListName",pageReference.state.c__SelectedLeadListName);
        
        var  strListFilterOptions = pageReference.state.c__strListFilterOptions;
        var defaultValueMap = component.get("v.DefaultValueMap");
        if(strListFilterOptions && defaultValueMap){
            var jsonObj = JSON.parse(strListFilterOptions, function (key, value) {
            if(defaultValueMap[key] )
                defaultValueMap[key] = value;
            });

            component.set("v.DefaultValueMap",defaultValueMap);
        }
    },

    handleInput : function(component,fieldName,fieldValue) {
        // Format string to match apex controller
       if(Array.isArray(fieldValue)){
            let temp = '';
            for(var i=0;i<fieldValue.length;i++){
               temp = temp + fieldValue[i] + ',';
            }
            temp = temp.replace(/,\s*$/, ""); //this regex removes the last , in the string.
            fieldValue = null;
            fieldValue = temp;
        }
        //To set blank value such that every item has name and value
        if(fieldValue==null || fieldValue=='undefined'){
            fieldValue="";
        }
        var objSelValue = {name : fieldName , value: fieldValue};
        var selectedValueObjectTemp = component.get("v.selectedValueObjectTemp");
        //Set a temporary list to hold all the objects 
        selectedValueObjectTemp.push(objSelValue);
        component.set("v.selectedValueObjectTemp",selectedValueObjectTemp);
    },

    setFilterOptions:function(component,event,helper){
        //put results in the format name ,value
        //Set the default values into the fields
        var arr = [];
        component.set("v.selectedValueObjectTemp",arr);
        var defaultValueMap = component.get("v.DefaultValueMap");
        if(defaultValueMap !=null){
            for(var key in defaultValueMap){
                if(component.find(key)!=null ){
                   if(component.find(key).get("v.value")!='All Prospect Leads'){
                       if(key=="Store__c")
                        helper.handleInput(component,key,component.find(key).get("v.value"));
                       else
                        helper.handleInput(component,component.find(key).get("v.name"),component.find(key).get("v.value"));
                   }
                    
                }
            }
       }
       //Add the list from temp to the attribute
        component.set("v.selectedValueObject",component.get("v.selectedValueObjectTemp"));
        //Store in form of a string to pass through pageref
        component.set("v.strListFilterOptions",JSON.stringify(component.get("v.selectedValueObjectTemp")));
    },

    setStrListFilterOptions:function(component,event,helper){
        
        //set filter options
        component.set("v.selectedValueObject",component.get("v.selectedValueObjectTemp"));
        var selectedValueObjectStr;
        selectedValueObjectStr = JSON.stringify(component.get("v.selectedValueObject"));
        component.set("v.strListFilterOptions",selectedValueObjectStr);
        
    },
    
    resetStrFilterOperatorDisplay:function(component,event,helper){
    	//reset filter operator display
        component.set("v.strFilterOperatorDisplay","");
    },
    navigateToResultPage:function(component,event,helper){
         //Result  page
         var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__ProspectLeadsListViewResult'
            },
            state: {
                "c__SelectedLeadListName" :component.get("v.SelectedLeadListName"),//selected campaign
                "c__LeadListName" : component.get("v.LeadListName"),//picklist values of campaign so that the result page can pass the values back without the round trip to controller
                "c__strListFilterOptions" :component.get("v.strListFilterOptions"),//filter json string
                "c__renderCmp" :"true",
                "c__strFilterOperatorDisplay" :component.get("v.strFilterOperatorDisplay")//String to display selected filters on the result header
            }
        };
        //Reset temporary string to reset filters
        var arr = [];
        component.set("v.selectedValueObjectTemp",arr);
        //navigate to result component
        component.find("navigation").navigate(pageReference,false); 
    },

    sendDefaultsToController : function(component, event,helper) {
        //function due to appevent being fired
        //Get parameters from event
        var selectedLeadListName = event.getParam("SelectedLeadListName");
        var leadListName =event.getParam("LeadListName");
        component.set("v.SelectedLeadListName",selectedLeadListName);
        component.set("v.LeadListName",leadListName);
        component.set("v.gotoResults",true);
        helper.getPicklistValuesFromController(component, event,helper); //generate default filters 
    },

    createMapOfDefaultOperators: function(component,event,helper){
        //to create  string to display on the result page which shows the values modified /defaulted
       var defaultOperatorMap = component.get("v.DefaultOperatorMap");
       var defaultValueMap = component.get("v.DefaultValueMap");
       var strFilterOperatorDisplay;
       var strDefaultFilters ='';
        for(var key in defaultValueMap){
            if(component.find(key)!=null ){
            if(key !== "Store__c" &&component.find(key)!=null && component.find(key).get("v.label")!='undefined'){
                defaultOperatorMap[component.find(key+'Format').get("v.value")] = component.find(key).get("v.label");
                if(key === "Store__c"){
                    defaultOperatorMap[key] = "equals";
                }
                if(key  != 'LeadListName__c' && defaultValueMap[key]!=''){// eliminate lead list as it is already displayed on te page
                    //create default filter string 
                    strDefaultFilters = strDefaultFilters+component.find(key+'Format').get("v.value")+' '+component.find(key).get("v.label")+' '+defaultValueMap[key]+',';
                    strFilterOperatorDisplay = strDefaultFilters;
                }
            }
        }
    }
        component.set("v.DefaultOperatorMap",defaultOperatorMap);
        if(strFilterOperatorDisplay!=null){
            strFilterOperatorDisplay = strFilterOperatorDisplay.replace("less than","<");
            component.set("v.strFilterOperatorDisplay",strFilterOperatorDisplay.substring(0, strFilterOperatorDisplay.length - 1));
        }
     },

    deserializeJSONFilters: function(component,event,helper){
       //Create a String of all the filters from JSON to display on result header
        var strFilterDisplay='';
        var strListFilterOptions;
        var strFilterOperatorDisplay = '';
        strListFilterOptions =component.get("v.strListFilterOptions");
        var defaultOperatorMap =component.get("v.DefaultOperatorMap");
        var jsonArray =[];
        if((strListFilterOptions != null || strListFilterOptions!=''|| strListFilterOptions != 'undefined' ) && defaultOperatorMap!=null){
            var obj =  JSON.parse(strListFilterOptions);
            jsonArray = Object.values(obj);
            var defaultValueMap = component.get("v.DefaultValueMap");
            for(var i=0;i<jsonArray.length;i++){
                var mapIndex =jsonArray[i].name+'Format' ;
                var mapValue;
                if(component.find(mapIndex) !=null && mapIndex  != 'LeadListName__cFormat' && mapIndex  != 'Store__cFormat' ){
                    mapValue = component.find(mapIndex).get("v.value");
                    if((jsonArray[i].value!=null && jsonArray[i].value!='' ) && mapValue!=null && defaultOperatorMap[mapValue]!=null ){
                        strFilterDisplay = strFilterDisplay+mapValue+' '+defaultOperatorMap[mapValue]+' '+jsonArray[i].value+',';
                        strFilterOperatorDisplay = strFilterDisplay;
                    }
                }
            }
        } 
        if(strFilterOperatorDisplay !== 'undefined'){
            strFilterOperatorDisplay =strFilterOperatorDisplay.replace(/"less than"/g,"<");
            if(component.get("v.storeName") != null && component.get("v.storeName") != ''){
                strFilterOperatorDisplay = strFilterOperatorDisplay +'Store = '+component.get("v.storeName")+'.';
            }
            component.set("v.strFilterOperatorDisplay",strFilterOperatorDisplay.substring(0, strFilterOperatorDisplay.length - 1));

        }
    },
    
    clearAllFilterValues:function(component,evt,helper){
        $A.get('e.force:refreshView').fire();
    },

    validateFilters:function(component,evt,helper){
        var renderStoreFilter = component.get("v.renderStoreFilter");
        var proximity = component.find("Proximity__c").get("v.value");
        if(proximity == null || proximity  == '') {
            helper.handleError($A.get("$Label.c.ProspectRequiredFilter").replace("{0}", "Proximity"));
            component.set("v.isError",true);
        } else {
            var maxProximity = component.get("v.maxProximity"); 
            if(maxProximity  != null && proximity > maxProximity) {
                helper.handleError($A.get("$Label.c.ProspectMaxProximityError").replace("{0}", maxProximity));
                component.set("v.isError",true);
            }  else if(renderStoreFilter) {
                var store = component.find("Store__c").get("v.value");
                if(store == null || store == ''  ){
                    helper.handleError($A.get("$Label.c.ProspectRequiredFilter").replace("{0}", "Employee Location"));
                    component.set("v.isError",true);
                }
                else{
                    component.set("v.storeId",store);
                    component.set("v.isError",false);
                }
            } else {
                component.set("v.isError",false);
            }
            
        }
    },

    getMaxProximity: function(component, event, helper) {
        var maxProximity = component.get("v.maxProximity");
        if(maxProximity == null) {
            var action = component.get("c.getMaxProximity");
            action.setCallback(this, function(response){
                var state=response.getState();
                if(state == "SUCCESS"){
                    component.set("v.maxProximity",response.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        }
    }
})