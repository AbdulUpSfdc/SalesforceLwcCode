public with sharing class BWC_BanUsageSummary {

    public class UsageSummaryRequest {
        public List<AccountData> AccountData;
    }

    public class AccountData {
        public String AccountNumber;
    }

    /**
     * Scenario 1: Shared Data, Individual Text and Individual Talk
     * Scenario 2: Individual Data, Shared Text and Shared Talk
     * Scenario 3: Individual Data, Individual Text and Shared Talk
     * Scenario 4: Individual Data Only
     * Scenario 5: Individual data, individual text and individual voice
     * Scenario 6: Line Level (Mix and Match) plan
     */

    public class UsageSummaryResponse {
        public List<UsageResponse> response;
    }

    public class UsageResponse {
        public String accountNumber;
        public String resultType;
        public BillCycleInfo billCycleInfo;
        public Usage usage;
    }
    
    public class BillCycleInfo {
        public String startDate;
        public String endDate;
    }

    public class Usage {
        public List<DataAndText> DataAndText;
        public List<Voice> Voice;
    }

    public class DataAndText {
        public List<DataTextUsage> DataTextUsage;
    }

    public class DataTextUsage {
        public DTUGroupUsageInfo GroupUsageInfo;
        public List<DTUSubscriberUsageInfo> SubscriberUsageInfo;
    }

    public class DTUGroupUsageInfo {
        public DTUGUIActive Active;
        public DTUGUITotalUsage TotalUsage;
        public DTUGUIExpectedUsage ExpectedUsage;
    }

    public class DTUGUIActive {
        public String type;
        public DTUGUIAPlan Plan;
        public DTUGUIATextPlan TextPlan;
        public List<DTUGUIASplitUsage> SplitUsage;
        public List<DTUGUIALineLevelUsage> LineLevelUsage;
    }

    public class DTUGUIAPlan {
        public DTUGUIAPUsage Usage;
        public String startDate;
        public DTUGUIAPTethered Tethered;
        public String status;
    }

    public class DTUGUIAPUsage {
        public String uom;
        public Decimal used;
        public Boolean isUnlimited;
        public Decimal alloted;
        public String soc;
    }

    public class DTUGUIAPTethered {
        public String uom;
        public Decimal used;
    }

    public class DTUGUIATextPlan {
        public DTUGUIATPUsage Usage;
        public String startDate;
        public String status;
    }

    public class DTUGUIATPUsage {
        public Decimal used;
        public Decimal alloted;
        public Boolean isUnlimited;
        public String soc;
    }

    public class DTUGUIASplitUsage {
        public DTUGUIASPlanUsage PlanUsage;
        public DTUGUIASTetheredUsage TetheredUsage;
        public DTUGUIASTotalUsage TotalUsage;
        public String subscriberId;
    }

    public class DTUGUIASPlanUsage {
        public String uom;
        public Decimal used;
    }

    public class DTUGUIASTetheredUsage {
        public String uom;
        public Decimal used;
        public Decimal alloted;
    }

    public class DTUGUIASTotalUsage {
        public String uom;
        public Decimal used;
    }

    public class DTUGUIALineLevelUsage {
        public String subscriberId;
        public DTUGUIASPlan Plan;
    }

    public class DTUGUIASPlan {
        public DTUGUIASPUsage Usage;
        public String startDate;
        public DTUGUIASPTetheredUsage TetheredUsage;
        public DTUGUIASPTotalUsage TotalUsage;
        public DTUGUIASPExpectedUsage ExpectedUsage;
    }
    
    public class DTUGUIASPUsage {
        public String uom;
        public Decimal used;
        public Boolean isUnlimited;
        public String soc;
    }

    public class DTUGUIASPTetheredUsage {
        public String uom;
        public Decimal used;
        public Decimal alloted;
    }

    public class DTUGUIASPTotalUsage {
        public DTUGUIASPTUData Data;
    }

    public class DTUGUIASPTUData {
        public Decimal used;
        public Boolean isUnlimited;
        public Decimal alloted;
        public Decimal overage;
        public String uom;
    }

    public class DTUGUIASPExpectedUsage {
        public DTUGUIASPEUData Data;
    }

    public class DTUGUIASPEUData {
        public String uom;
        public Decimal usage;
    }

    public class DTUGUITotalUsage {
        public DTUGUITData Data;
    }

    public class DTUGUITData {
        public Decimal used;
        public Boolean isUnlimited;
        public Decimal overage;
        public String uom;
    }

    public class DTUGUIExpectedUsage {
        public DTUGUIEData Data;
    }

    public class DTUGUIEData {
        public String uom;
        public Decimal usage;
    }

    public class DTUSubscriberUsageInfo {
        public String subscriberId;
        public DTUSActive Active;
        public DTUSTotalUsage TotalUsage;
        public DTUSExpectedUsage ExpectedUsage;
    }

    public class DTUSActive {
        public List<DTUSAPlan> Plan;
    }

    public class DTUSAPlan {
        public DTUSAPUsage Usage;
        public String startDate;
        public String category;
        public String usageType;
        public String Status;
    }

    public class DTUSAPUsage {
        public Decimal used;
        public Boolean isUnlimited;
        public String soc;
    }

    public class DTUSTotalUsage {
        public DTUSTText Text;
        public DTUSTData Data;
    }

    public class DTUSTText {
        public Decimal used;
        public Boolean isUnlimited;
        public Decimal overage;
        public Decimal alloted;
    }

    public class DTUSTData {
        public Decimal used;
        public Decimal alloted;
        public Boolean isUnlimited;
        public Decimal overage;
        public String uom;
    }

    public class DTUSExpectedUsage {
        public DTUSEUData Data;
    }

    public class DTUSEUData {
        public String uom;
        public Decimal usage;
    }

    public class Voice {
        public String subscriberId;
        public VVoiceUsage VoiceUsage;
    }

    public class VVoiceUsage {
        public VUUsageInfo SubscriberUsageInfo;
        public VUUsageInfo GroupUsageInfo;
    }

    public class VUUsageInfo {
        public VVSActive Active;
        public VVSTotalUsage TotalUsage;
    }

    public class VVSActive {
        public String planCode;
        public String planDescription;
        public String groupId;
        public String startDate;
        public String eventsThrough;
        public List<VVSAUsage> Usage;
        public List<VVGUIASplitUsage> SplitUsage;
    }

    public class VVSAUsage {
        public Decimal used;
        public Decimal alloted;
        public Boolean isUnlimited;
        public Decimal overage;
        public String uom;
        public String usageType;
    }

    public class VVGUIASplitUsage {
        public String subscriberId;
        public List<VVGUIASUVoiceUsage> voiceUsage;
        public List<VVGUIASUVoiceUsage> planUsage;
    }

    public class VVGUIASUVoiceUsage {
        public Decimal used;
        public Decimal alloted;
        public Boolean isUnlimited;
        public Decimal overage;
        public String uom;
        public String usageType;
        public Decimal rollOverExpiringMins;
        public String rollOverExpirationDate;
    }

    public class VVSTotalUsage {
        public Decimal used;
        public Decimal alloted;
        public Boolean isUnlimited;
        public Decimal overage;
        public String uom;
    }
    
    /**
     * Wrapper Class for Usage Summary to send to UI
     */

    public class CustomerUsageSummary {
        public String accountNumber;
        public String usageType;
        public String billingCycleStartDate;
        public String billingCycleEndDate;
        public List<UsageSummary> planUsage;
    }

    public class UsageSummary {
        public Boolean showChart;
        public String planSocCode;
        public String planName;
        public PlanUsage dataPlanUsage;
        public PlanUsage textPlanUsage;
        public PlanUsage talkPlanUsage;
    }

    public class PlanUsage {
        public Decimal totalUsed;
        public Boolean isUnlimited;
        public Decimal alloted;
        public String uom;
        public List<UsageByCtn> usageByCtn;
    }

    public class UsageByCtn {
        public String uniqueKey;
        public String ctn;
        public String name;
        public String device;
        public String displayPhone;
        public Decimal used;
        public Boolean isUnlimited;
        public Decimal alloted;
        public String uom;
        public String soc;
        public String planName;
        public String subscriberName;
        public Boolean isNearLimit;
        public Boolean isOverLimit;
    }
}