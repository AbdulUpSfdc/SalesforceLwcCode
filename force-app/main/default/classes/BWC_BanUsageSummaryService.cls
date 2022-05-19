public with sharing class BWC_BanUsageSummaryService {

    public static BWC_BanUsageSummary.UsageSummaryResponse getCustomerUsageSummary(BWC_BanUsageSummary.UsageSummaryRequest request) {
        return BWC_BanUsageSummaryCallout.getCustomerUsageSummary(request);
    }

    public static BWC_BanUsageSummary.CustomerUsageSummary generateUsageSummary(String billingAccountId, List<BWC_BanUsageSummary.UsageResponse> usageSummaryResponse) {

        // Initialize object that will be returned to UI
        BWC_BanUsageSummary.CustomerUsageSummary customerUsageSummary = new BWC_BanUsageSummary.CustomerUsageSummary();

        // If no usage summary was retrieved, return null to show notification to agent to try again.
        if (usageSummaryResponse.size() == 0) {
            return null;
        }

        // Get Billing Account
        Billing_Account__c bAccount = BWC_AccountService.getBillingAccountForId(billingAccountId);

        // Get all plans related to billing account
        List<Plan__c> planList = BWC_Plan_Selector.getPlansForBillingAccounts(new Set<Id>{billingAccountId});
        Map<String, Plan__c> planMap = new Map<String, Plan__c>();
        for (Plan__c plan : planList) {
            planMap.put(plan.Plan_Code__c, plan);
        }
        
        // Get all assets related to billing account
        List<Asset> assetsInBan = BWC_Asset_Selector.getAssetsForBillingAccounts(new Set<Id>{billingAccountId});
        Map<String, Asset> assetMap = new Map<String, Asset>();
        for (Asset asset : assetsInBan) {
            assetMap.put(asset.Phone_Number__c, asset);
        }

        // Get the usage summary. There is only one usage summary on the response for now
        BWC_BanUsageSummary.UsageResponse usageResponse = usageSummaryResponse[0];
        
        // Set usage summary general information 
        customerUsageSummary.accountNumber = usageResponse.accountNumber;
        customerUsageSummary.usageType = usageResponse.resultType;
        customerUsageSummary.billingCycleEndDate = usageResponse.billCycleInfo.endDate;
        customerUsageSummary.billingCycleStartDate = usageResponse.billCycleInfo.startDate;

        // Get data and text usage object and voice object
        List<BWC_BanUsageSummary.DataAndText> dataAndTextUsage = usageResponse.usage.DataAndText;
        List<BWC_BanUsageSummary.Voice> voiceUsage = usageResponse.usage.Voice;

        // Initialize list of plan usage to add to response
        List<BWC_BanUsageSummary.UsageSummary> usageSummaryList = new List<BWC_BanUsageSummary.UsageSummary>();

        // Get usage per plan
        for (Plan__c plan : planList) {

            // Init plan usage object 
            BWC_BanUsageSummary.UsageSummary usageSummary = new BWC_BanUsageSummary.UsageSummary();

            usageSummary.planName = plan.Plan_Name__c;
            usageSummary.planSocCode = plan.Plan_Code__c;
            usageSummary.showChart = true;

            // Init 
            BWC_BanUsageSummary.PlanUsage dataPlanUsage = new BWC_BanUsageSummary.PlanUsage();
            BWC_BanUsageSummary.PlanUsage textPlanUsage = new BWC_BanUsageSummary.PlanUsage();
            BWC_BanUsageSummary.PlanUsage talkPlanUsage = new BWC_BanUsageSummary.PlanUsage();

            dataPlanUsage.totalUsed = 0;
            dataPlanUsage.uom = BWC_Constants.USAGE_DATA_DEFAULT_UOM;
            textPlanUsage.totalUsed = 0;
            textPlanUsage.uom = BWC_Constants.USAGE_TEXT_UOM;
            talkPlanUsage.totalUsed = 0;
            talkPlanUsage.uom = BWC_Constants.USAGE_VOICE_UOM;

            // Check if we have DataTextUsage
            if (dataAndTextUsage[0].DataTextUsage.size() > 0) {

                BWC_BanUsageSummary.DataTextUsage dataTextUsage = dataAndTextUsage[0].DataTextUsage[0];

                // Get shared usage for Data & Text
                if (dataTextUsage.GroupUsageInfo != null) {
                    BWC_BanUsageSummary.DTUGroupUsageInfo groupUsageInfo = dataTextUsage.GroupUsageInfo;

                    List<BWC_BanUsageSummary.UsageByCtn> dataUsageByCtnList = new List<BWC_BanUsageSummary.UsageByCtn>();
                    List<BWC_BanUsageSummary.UsageByCtn> textUsageByCtnList = new List<BWC_BanUsageSummary.UsageByCtn>();

                    // Check if it's Mix & Match
                    if (groupUsageInfo.Active.type == BWC_Constants.USAGE_MIX_MATCH_TYPE) {

                        // Check if there is line level data usage
                        if (groupUsageInfo.Active.LineLevelUsage != null) {

                            usageSummary.showChart = false;

                            for (BWC_BanUsageSummary.DTUGUIALineLevelUsage lineLevelUsage : groupUsageInfo.Active.LineLevelUsage) {
                                Asset subscriber = assetMap.get(lineLevelUsage.subscriberId);
                                if (subscriber != null && subscriber.Plan__c == plan.Id) {
                                    BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                    usageByCtn.uniqueKey = lineLevelUsage.subscriberId + '-Data';
                                    usageByCtn.ctn = lineLevelUsage.subscriberId;
                                    if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                        usageByCtn.name = 'N/A';
                                    } else {
                                        usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                    }
                                    usageByCtn.device = subscriber.Device_Type__c;
                                    usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                    usageByCtn.used = lineLevelUsage.Plan.TotalUsage.Data.used;
                                    usageByCtn.isUnlimited = lineLevelUsage.Plan.TotalUsage.Data.isUnlimited;
                                    if (lineLevelUsage.Plan.TotalUsage.Data.alloted != null) {
                                        usageByCtn.alloted = lineLevelUsage.Plan.TotalUsage.Data.alloted;
                                    }
                                    usageByCtn.uom = lineLevelUsage.Plan.TotalUsage.Data.uom;
                                    if (subscriber.User__c == null) {
                                        usageByCtn.subscriberName = lineLevelUsage.subscriberId;
                                    } else {
                                        usageByCtn.subscriberName = subscriber.User__c;
                                    }
                                    if (usageByCtn.isUnlimited) {
                                        usageByCtn.isNearLimit = false;
                                        usageByCtn.isOverLimit = false;
                                    } else {
                                        usageByCtn.isNearLimit = isNearOrOverLimit(lineLevelUsage.Plan.TotalUsage.Data.used, lineLevelUsage.Plan.TotalUsage.Data.alloted, 'near');
                                        usageByCtn.isOverLimit = isNearOrOverLimit(lineLevelUsage.Plan.TotalUsage.Data.used, lineLevelUsage.Plan.TotalUsage.Data.alloted, 'over');
                                    }
                                    usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                    dataUsageByCtnList.add(usageByCtn);

                                    // Set plan's total data usage
                                    dataPlanUsage.totalUsed += lineLevelUsage.Plan.TotalUsage.Data.used;
                                    dataPlanUsage.uom = lineLevelUsage.Plan.TotalUsage.Data.uom;
                                }
                            }

                            if (dataUsageByCtnList.size() > 0) {
                                dataPlanUsage.usageByCtn = dataUsageByCtnList;
                            }

                        }
                    }

                    // Check if there is shared data usage
                    if (groupUsageInfo.Active.Plan != null) {
                        // Get individual usage from shared data
                        for (BWC_BanUsageSummary.DTUGUIASplitUsage splitUsage : groupUsageInfo.Active.SplitUsage) {
                            Asset subscriber = assetMap.get(splitUsage.subscriberId);
                            if (subscriber != null && subscriber.Plan__c == plan.Id) {
                                BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                usageByCtn.uniqueKey = splitUsage.subscriberId + '-Data';
                                usageByCtn.ctn = splitUsage.subscriberId;
                                if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                    usageByCtn.name = 'N/A';
                                } else {
                                    usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                }
                                usageByCtn.device = subscriber.Device_Type__c;
                                usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                usageByCtn.used = splitUsage.TotalUsage.used;
                                usageByCtn.isUnlimited = groupUsageInfo.Active.Plan.Usage.isUnlimited;
                                if (groupUsageInfo.Active.Plan.Usage.alloted != null) {
                                    usageByCtn.alloted = groupUsageInfo.Active.Plan.Usage.alloted;
                                }
                                usageByCtn.uom = splitUsage.TotalUsage.uom;
                                if (subscriber.User__c == null) {
                                    usageByCtn.subscriberName = splitUsage.subscriberId;
                                } else {
                                    usageByCtn.subscriberName = subscriber.User__c;
                                }
                                if (usageByCtn.isUnlimited) {
                                    usageByCtn.isNearLimit = false;
                                    usageByCtn.isOverLimit = false;
                                } else {
                                    usageByCtn.isNearLimit = isNearOrOverLimit(splitUsage.TotalUsage.used, groupUsageInfo.Active.Plan.Usage.alloted, 'near');
                                    usageByCtn.isOverLimit = isNearOrOverLimit(splitUsage.TotalUsage.used, groupUsageInfo.Active.Plan.Usage.alloted, 'over');
                                }
                                usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                dataUsageByCtnList.add(usageByCtn);

                                // Set plan's total data usage
                                dataPlanUsage.totalUsed += splitUsage.TotalUsage.used;
                                dataPlanUsage.uom = splitUsage.TotalUsage.uom;
                            }
                        }

                        if (dataUsageByCtnList.size() > 0) {
                            dataPlanUsage.usageByCtn = dataUsageByCtnList;
                        }
                    }

                    // Check if there is shared text usage 
                    if (groupUsageInfo.Active.TextPlan != null) {
                        // Get individual usage from shared data
                        for (BWC_BanUsageSummary.DTUGUIASplitUsage splitUsage : groupUsageInfo.Active.SplitUsage) {
                            Asset subscriber = assetMap.get(splitUsage.subscriberId);
                            if (subscriber != null && subscriber.Plan__c == plan.Id) {
                                BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                usageByCtn.uniqueKey = splitUsage.subscriberId + '-Text';
                                usageByCtn.ctn = splitUsage.subscriberId;
                                if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                    usageByCtn.name = 'N/A';
                                } else {
                                    usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                }
                                usageByCtn.device = subscriber.Device_Type__c;
                                usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                usageByCtn.used = splitUsage.PlanUsage.used;
                                usageByCtn.isUnlimited = groupUsageInfo.Active.TextPlan.Usage.isUnlimited;
                                if (groupUsageInfo.Active.TextPlan.Usage.alloted != null) {
                                    usageByCtn.alloted = groupUsageInfo.Active.TextPlan.Usage.alloted;
                                }
                                usageByCtn.uom = BWC_Constants.USAGE_TEXT_UOM;
                                if (subscriber.User__c == null) {
                                    usageByCtn.subscriberName = splitUsage.subscriberId;
                                } else {
                                    usageByCtn.subscriberName = subscriber.User__c;
                                }
                                if (usageByCtn.isUnlimited) {
                                    usageByCtn.isNearLimit = false;
                                    usageByCtn.isOverLimit = false;
                                } else {
                                    usageByCtn.isNearLimit = isNearOrOverLimit(splitUsage.PlanUsage.used, groupUsageInfo.Active.TextPlan.Usage.alloted, 'near');
                                    usageByCtn.isOverLimit = isNearOrOverLimit(splitUsage.PlanUsage.used, groupUsageInfo.Active.TextPlan.Usage.alloted, 'over');
                                }
                                usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                textUsageByCtnList.add(usageByCtn);

                                // Set plan's total data usage
                                textPlanUsage.totalUsed += splitUsage.PlanUsage.used;
                            }
                        }

                        if (textUsageByCtnList.size() > 0) {
                            textPlanUsage.usageByCtn = textUsageByCtnList;
                        }
                    }

                }

                // Get individual usage (by subscriber)
                if (dataTextUsage.SubscriberUsageInfo != null) {
                    List<BWC_BanUsageSummary.DTUSubscriberUsageInfo> subscriberUsageList = dataTextUsage.SubscriberUsageInfo;

                    List<BWC_BanUsageSummary.UsageByCtn> dataUsageByCtnList = new List<BWC_BanUsageSummary.UsageByCtn>();
                    List<BWC_BanUsageSummary.UsageByCtn> textUsageByCtnList = new List<BWC_BanUsageSummary.UsageByCtn>();

                    for (BWC_BanUsageSummary.DTUSubscriberUsageInfo subscriberUsage : subscriberUsageList) {
                        // Set subscriber usage
                        Asset subscriber = assetMap.get(subscriberUsage.subscriberId);
                        if (subscriber != null && subscriber.Plan__c == plan.Id) {

                            if (subscriberUsage.TotalUsage.Data != null) {
                                BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                usageByCtn.uniqueKey = subscriberUsage.subscriberId + '-Data';
                                usageByCtn.used = subscriberUsage.TotalUsage.Data.used;
                                usageByCtn.isUnlimited = subscriberUsage.TotalUsage.Data.isUnlimited;
                                if (subscriberUsage.TotalUsage.Data.alloted != null) {
                                    usageByCtn.alloted = subscriberUsage.TotalUsage.Data.alloted;
                                }
                                usageByCtn.uom = subscriberUsage.TotalUsage.Data.uom;
                                usageByCtn.ctn = subscriberUsage.subscriberId;
                                if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                    usageByCtn.name = 'N/A';
                                } else {
                                    usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                }
                                usageByCtn.device = subscriber.Device_Type__c;
                                usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                usageByCtn.subscriberName = subscriber.User__c;

                                if (usageByCtn.isUnlimited) {
                                    usageByCtn.isNearLimit = false;
                                    usageByCtn.isOverLimit = false;
                                } else {
                                    usageByCtn.isNearLimit = isNearOrOverLimit(subscriberUsage.TotalUsage.Data.used, subscriberUsage.TotalUsage.Data.alloted, 'near');
                                    usageByCtn.isOverLimit = isNearOrOverLimit(subscriberUsage.TotalUsage.Data.used, subscriberUsage.TotalUsage.Data.alloted, 'over');
                                }
                                usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                dataUsageByCtnList.add(usageByCtn);

                                // Set plan's total text usage
                                dataPlanUsage.totalUsed += subscriberUsage.TotalUsage.Data.used;
                                dataPlanUsage.uom = subscriberUsage.TotalUsage.Data.uom;
                            }

                            if (subscriberUsage.TotalUsage.Text != null) {
                                BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                usageByCtn.uniqueKey = subscriberUsage.subscriberId + '-Text';
                                usageByCtn.used = subscriberUsage.TotalUsage.Text.used;
                                usageByCtn.isUnlimited = subscriberUsage.TotalUsage.Text.isUnlimited;
                                if (subscriberUsage.TotalUsage.Text.alloted != null) {
                                    usageByCtn.alloted = subscriberUsage.TotalUsage.Text.alloted;
                                }
                                usageByCtn.uom = BWC_Constants.USAGE_TEXT_UOM;
                                usageByCtn.ctn = subscriberUsage.subscriberId;
                                if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                    usageByCtn.name = 'N/A';
                                } else {
                                    usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                }
                                usageByCtn.device = subscriber.Device_Type__c;
                                usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                usageByCtn.subscriberName = subscriber.User__c;

                                if (usageByCtn.isUnlimited) {
                                    usageByCtn.isNearLimit = false;
                                    usageByCtn.isOverLimit = false;
                                } else {
                                    usageByCtn.isNearLimit = isNearOrOverLimit(subscriberUsage.TotalUsage.Text.used, subscriberUsage.TotalUsage.Text.alloted, 'near');
                                    usageByCtn.isOverLimit = isNearOrOverLimit(subscriberUsage.TotalUsage.Text.used, subscriberUsage.TotalUsage.Text.alloted, 'over');
                                }
                                usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                textUsageByCtnList.add(usageByCtn);

                                // Set plan's total text usage
                                textPlanUsage.totalUsed += subscriberUsage.TotalUsage.Text.used;
                            }
                        }
                    }

                    if (dataUsageByCtnList.size() > 0) {
                        dataPlanUsage.usageByCtn = dataUsageByCtnList;
                    }
    
                    if (textUsageByCtnList.size() > 0) {
                        textPlanUsage.usageByCtn = textUsageByCtnList;
                    }
                }
            }

            // Check if we have Voice Usage
            if (voiceUsage.size() > 0) {
                List<BWC_BanUsageSummary.UsageByCtn> talkUsageByCtnList = new List<BWC_BanUsageSummary.UsageByCtn>();
                for (BWC_BanUsageSummary.Voice subscriberUsage : voiceUsage) {

                    // check if there is individual voice data
                    if (subscriberUsage.VoiceUsage.SubscriberUsageInfo != null) {
                        // Add usage only if subscriber is part of plan
                        Asset subscriber = assetMap.get(subscriberUsage.subscriberId);
                        if (subscriber != null && subscriber.Plan__c == plan.Id) {
                            BWC_BanUsageSummary.VUUsageInfo subscriberUsageInfo = subscriberUsage.VoiceUsage.SubscriberUsageInfo;
                            // Check if there is total usage
                            if (subscriberUsageInfo.TotalUsage != null) {
                                BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                usageByCtn.uniqueKey = subscriberUsage.subscriberId + '-Voice';
                                usageByCtn.used = subscriberUsageInfo.TotalUsage.used;
                                usageByCtn.isUnlimited = subscriberUsageInfo.TotalUsage.isUnlimited;
                                if (subscriberUsageInfo.TotalUsage.alloted != null) {
                                    usageByCtn.alloted = subscriberUsageInfo.TotalUsage.alloted;
                                }
                                usageByCtn.uom = BWC_Constants.USAGE_VOICE_UOM;
                                usageByCtn.ctn = subscriberUsage.subscriberId;
                                if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                    usageByCtn.name = 'N/A';
                                } else {
                                    usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                }
                                usageByCtn.device = subscriber.Device_Type__c;
                                usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                usageByCtn.subscriberName = subscriber.User__c;

                                if (usageByCtn.isUnlimited) {
                                    usageByCtn.isNearLimit = false;
                                    usageByCtn.isOverLimit = false;
                                } else {
                                    usageByCtn.isNearLimit = isNearOrOverLimit(subscriberUsageInfo.TotalUsage.used, subscriberUsageInfo.TotalUsage.alloted, 'near');
                                    usageByCtn.isOverLimit = isNearOrOverLimit(subscriberUsageInfo.TotalUsage.used, subscriberUsageInfo.TotalUsage.alloted, 'over');
                                }
                                usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;

                                talkUsageByCtnList.add(usageByCtn);

                                // Set plan's total text usage
                                talkPlanUsage.totalUsed += subscriberUsageInfo.TotalUsage.used;
                            }
                        }
                    }

                    // check if there is shared voice usage
                    if (subscriberUsage.VoiceUsage.GroupUsageInfo != null) {
                        BWC_BanUsageSummary.VUUsageInfo voiceGroupUsage = subscriberUsage.VoiceUsage.GroupUsageInfo;

                        if (voiceGroupUsage.Active.SplitUsage != null) {
                            List<BWC_BanUsageSummary.VVGUIASplitUsage> sharedVoiceSplitUsage = voiceGroupUsage.Active.SplitUsage;
                            for (BWC_BanUsageSummary.VVGUIASplitUsage splitUsage : sharedVoiceSplitUsage) {
                                // Check split usage for each subscriber
                                Asset subscriber = assetMap.get(splitUsage.subscriberId);
                                if (subscriber != null && subscriber.Plan__c == plan.Id) {
                                    BWC_BanUsageSummary.UsageByCtn usageByCtn = new BWC_BanUsageSummary.UsageByCtn();
                                    usageByCtn.uniqueKey = splitUsage.subscriberId + '-Voice';
                                    usageByCtn.ctn = splitUsage.subscriberId;
                                    if (subscriber.Manufacturer__c == null && subscriber.Make_And_Model__c == null) {
                                        usageByCtn.name = 'N/A';
                                    } else {
                                        usageByCtn.name = subscriber.Manufacturer__c + ' ' + subscriber.Make_And_Model__c;
                                    }
                                    usageByCtn.device = subscriber.Device_Type__c;
                                    usageByCtn.displayPhone = subscriber.Phone_Number_Display__c;
                                    usageByCtn.subscriberName = subscriber.User__c;
                                    usageByCtn.soc = subscriber.Subscriber_Plan_Name__c;
                                    usageByCtn.uom = BWC_Constants.USAGE_VOICE_UOM;

                                    List<BWC_BanUsageSummary.VVGUIASUVoiceUsage> subscriberVoiceUsageList = splitUsage.planUsage;
                                    for (BWC_BanUsageSummary.VVGUIASUVoiceUsage subscriberVoiceUsage : subscriberVoiceUsageList) {
                                        if (subscriberVoiceUsage.usageType == 'TOTAL') {
                                            usageByCtn.used = subscriberVoiceUsage.used;
                                            usageByCtn.isUnlimited = subscriberVoiceUsage.isUnlimited;
                                            if (subscriberVoiceUsage.alloted != null) {
                                                usageByCtn.alloted = subscriberVoiceUsage.alloted;
                                            }
                                            break;
                                        }
                                    }

                                    talkUsageByCtnList.add(usageByCtn);

                                    // Set plan's total text usage
                                    talkPlanUsage.totalUsed += usageByCtn.used;
                                }
                            }   
                        }
                    }

                }

                if (talkUsageByCtnList.size() > 0) {
                    talkPlanUsage.usageByCtn = talkUsageByCtnList;
                }

            }

            usageSummary.dataPlanUsage = dataPlanUsage;
            usageSummary.textPlanUsage = textPlanUsage;
            usageSummary.talkPlanUsage = talkPlanUsage;

            usageSummaryList.add(usageSummary);

        }

        customerUsageSummary.planUsage = usageSummaryList;

        return customerUsageSummary;

    }

    // Calculate if is near or over limit
    public static Boolean isNearOrOverLimit(Decimal used, Decimal alloted, String nearOver) {
        // If there's no alloted and used is more than 0 -> it is over limit
        if (alloted == 0 & used > 0) {
            if (nearOver == 'near') {
                return false;
            } else {
                return true;
            }
        } 
        // If there's alloted usage, calculate near and over limits
        else if (alloted > 0) {
            if (nearOver == 'near') {
                return ((used / alloted) >= 0.9) && ((used / alloted) < 1.0);
            } else {
                return used / alloted >= 1.0;
            }
        } 
        // both allocation and usage are 0
        else {
            return false;
        }
    }
}