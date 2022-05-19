({
    setPageReferenceValues : function(cmp, evt, helper) {
        cmp.set("v.timeZone",$A.get("$Locale.timezone"));
        var myPageRef = cmp.get("v.pageReference");
        console.log('****** myPageRef '+myPageRef)
        if(myPageRef != null){
            console.log('****** myPageRef.state.c__strListFilterOptions '+myPageRef.state.c__strListFilterOptions);
            var strListFilterOptions = myPageRef.state.c__strListFilterOptions;
            console.log('****** strListFilterOptions*** '+strListFilterOptions);
            //set strListFilterOptions
            cmp.set("v.strListFilterOptions", strListFilterOptions);
            //set SelectedLeadListName
            cmp.set("v.SelectedLeadListName", myPageRef.state.c__SelectedLeadListName);
            console.log('****** LeadListName '+myPageRef.state.c__LeadListName);
            // set LeadListNames
            if(myPageRef.state.c__LeadListName != null)
                cmp.set("v.LeadListName",Object.values(myPageRef.state.c__LeadListName));
            //set DefaultOperators
                cmp.set("v.strFilterOperatorDisplay", myPageRef.state.c__strFilterOperatorDisplay);
            // set lstLead
            if(myPageRef.state.c__lstLead != null)
                cmp.set("v.lstLead",Object.values(myPageRef.state.c__lstLead));//convert to array as pageref returns object
            console.log('****** v.lstLead after pageref '+cmp.get("v.lstLead"));
            console.log('****** strListFilterOptions '+cmp.get("v.strListFilterOptions"));
            //get query results to display
            helper.getQueryResultsFromController(cmp, evt, helper);
        }
    },

    getQueryResultsFromController:function(cmp, evt, helper){
        //Pass filter json string
        var action = cmp.get("c.getLeadsByFilterNew");
        console.log('******* action --->filteroptoins******  '+cmp.get("v.strListFilterOptions"));
        action.setParams({strListFilterOptions : cmp.get("v.strListFilterOptions")});
        action.setCallback(this,function(response){
            var state=response.getState();
            console.log('******** state ****** '+state);
            if(state=="SUCCESS"){
                console.log('******** getLeadsByFilter ****** '+response.getReturnValue());
               //************* Lazy Load Starts *************** */
               var leadWrapper = response.getReturnValue();
               cmp.set("v.totalRows",leadWrapper.totalRecords);  
               var leadList = leadWrapper.lstLead;
               cmp.set("v.lstLead",leadList);
               cmp.set("v.renderCmp","true");
               cmp.set("v.isDisabled", false);
            } else {
                cmp.set("v.totalRows",0);
                cmp.set("v.lstLead",null);
                cmp.set("v.isDisabled", true);
                cmp.set("v.renderCmp","true");
                helper.handleActionError(response, helper);
            }
        });
        $A.enqueueAction(action);
    },
    
    goToFilterComp:function(component,event,helper){
        //check for profile for store filter visibility
        helper.checkIfProfileIsNotARepOrMGR(component,event,helper);
        console.log('******* filter comp ******');
        
    },

    navigateToFilterComp:function(component,event,helper){
        //Navigate to filter component
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__ProspectLeadFilter'
            },
            state: {
                "c__SelectedLeadListName": component.get("v.SelectedLeadListName"),
                "c__strListFilterOptions" :component.get("v.strListFilterOptions"),//filter json string
                "c__renderCmp" : true,
                "c__gotoResults": false,
                "c__renderStoreFilter" : component.get("v.renderStoreFilter")
            } 
        };
        var navigation = component.find("navigation");
        navigation.navigate(pageReference,false);
    },

    gotoProspectPage:function(component,evt,helper){
        //back button logic
        var pageReference = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Prospect_Leads'
            }
        };
        component.set("v.pageReference",pageReference);
        var navigation = component.find("navigation");
        var pageReference = component.get("v.pageReference");
        evt.preventDefault();
        navigation.navigate(pageReference,true);
    },
    
    loadData : function(component){
        //Lazy load 
        var limit = component.get("v.initialRows");
        var offset = component.get("v.currentCount");
        var totalRows = component.get("v.totalRows");
        if(limit + offset > totalRows){
            limit = totalRows - offset;
        }
        var action = component.get("c.lazyLoadLeads");
        action.setParams({
            "rowLimit" :  limit,
            "rowOffset" : offset,
            "strListFilterOptions" : component.get("v.strListFilterOptions")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                var newData = response.getReturnValue();
                console.log('**************** newData ****** '+newData );
                var currentCount = component.get("v.currentCount");
                currentCount += component.get("v.initialRows");
                // set the current count with number of records loaded 
                console.log('**************** currentCount ****** '+currentCount );
                component.set("v.currentCount",currentCount);
                var currentData = component.get("v.lstLead");
                console.log('**************** currentData ****** '+currentData );
                var newData = currentData.concat(newData);
                console.log('**************** newData ****** '+newData );
                component.set("v.lstLead", newData);
                //To stop the spinner
                component.set("v.isLoading", false); 
            }
            else{
                //To stop spinner
                component.set("v.isLoading", false); 
                helper.handleActionError(response, helper);
            }
        });
        $A.enqueueAction(action);
    },

    checkIfProfileIsNotARepOrMGR: function(cmp,evt,helper){
        var action  = cmp.get("c.isProfileForStoreSelect");
        console.log('&&&&&&&&&&& action &&&&&&&&'+action);
        action.setCallback(this,function(response){
            console.log('&&&&&&&&&&& staresponsete &&&&&&&&'+response);
            var state = response.getState();
            console.log('&&&&&&&&&&& state &&&&&&&&'+state);
            if(state="SUCCESS"){
                var respObj = response.getReturnValue();
                console.log('&&&&&&&&&&& respObj &&&&&&&&'+respObj);
                if(respObj){
                    cmp.set("v.renderStoreFilter",respObj);
                }
                helper.navigateToFilterComp(cmp,evt,helper);
            } else {
                helper.handleActionError(response, helper);
            }
        });
        $A.enqueueAction(action);
    }
})