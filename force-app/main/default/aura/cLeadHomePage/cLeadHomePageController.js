({
    doinIt: function (component, event, helper) {
        const pageReference = component.get("v.pageReference");


        var action = component.get("c.getLeadCountDetails");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var ListviewCountMap = response.getReturnValue();
                component.set('v.DueTodayLst', ListviewCountMap.DueTodayCount);
                component.set('v.PastDueLst', ListviewCountMap.PastDueCount);
                component.set('v.DueNextLst', ListviewCountMap.DueNextCount);
                component.set('v.NotificationsLst', ListviewCountMap.NotificationsCount);
                console.log(component.get("v.CurrentUser.Profile.Name"));
                console.log('due today count==' + ListviewCountMap.DueTodayCount.length);
                // alert(ListviewCountMap.NotificationsCount.length);
                console.log('v.DueTodayLst3==', component.get("v.DueTodayLst"));
                component.set('v.showList', false);
                var listViewName = 'Due_Today';
                component.set('v.listViewName', listViewName);
                component.set('v.showList', true);
                console.log('listViewName==', component.get("v.listViewName"));
                console.log('showList==', component.get("v.showList"));

                var action2 = component.get("c.getLeadOverviewData");
                action2.setCallback(this, function (response2) {
                    var state2 = response2.getState();
                    if (state2 === "SUCCESS") {
                        var leadoverviewMap = response2.getReturnValue();
                        component.set('v.profileName', leadoverviewMap.ProfileName);

                        if (pageReference && pageReference.state) {
                            component.set('v.listViewName', pageReference.state.c__listviewname);
                            component.set('v.showList', true);
                        }
                        //  alert(leadoverviewMap.ProfileName);
                    }
                });
                $A.enqueueAction(action2);


            } else {
                console.log(state);
            }
        });
        $A.enqueueAction(action);
    },

    handleSelection: function (component, event, helper) {
        component.set('v.showList', false);
        var listViewName = event.currentTarget.id;
        console.log('listViewName@@', listViewName);
        if (component.get('v.hideRecordTablePanel') == true ) {
            if (component.get("v.profileName").includes("ARSM")) {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/lightning/n/Lead_Overview_ARSM"
                });
                urlEvent.fire();
            }
            else {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/lightning/n/Lead_Overview"
                });
                urlEvent.fire();
            }
         
        }
        else {
            if (listViewName) {
                component.set('v.listViewName', listViewName);
                component.set('v.showList', true);
            }
        }
    },
    handleRecordUpdated: function (component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
            // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log(component.get("v.CurrentUser.Profile.Name"));
        } else if (eventParams.changeType === "CHANGED") {
            // record is changed
        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if (eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }
})