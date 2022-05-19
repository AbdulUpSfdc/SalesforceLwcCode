import { api, LightningElement, track } from 'lwc';
import * as BwcUtils from 'c/bwcUtils';


const SDFS_KEY = 'Have one of the following wireless-sdfs';
const SDGS_KEY = 'Have one of the following wireless-sdgs';

const SKU_KEY = 'Have one of the following skus';
const ELIGIBLE_SKUs = 'Eligible SKUs';

const GROUP_KEY = "Group must have 3 lines that meet all the following criteria.";
const GROUP_LABEL = "Group Level Criteria";

const BOGO_LABEL = "BOGO Criteria";
const BOGO_QUALIFIER = "BOGO Qualifier";
const BOGO_BENEFICIARY = "BOGO Beneficiary";

export default class BwcPromotionDetail extends LightningElement 
{
    sdfsLabel = SDFS_KEY;
    sdgsLabel = SDGS_KEY;
    skuLabel = ELIGIBLE_SKUs;
    groupLabel= GROUP_LABEL;
    bogoLabel = BOGO_LABEL;
    bogoQualifierLabel = BOGO_QUALIFIER;
    bogoBenificiaryLabel = BOGO_BENEFICIARY;

    activeSections = ['A', 'B', 'C','D','E','F','G','H','I','J','K','Z','L','M'];
    @api promoDetails;
    @track complianceRules = [];

    hasRendered = false;
    @track wirelessSdfs = [];
    @track wirelessSdgs = [];
    @track ElligibleSKus = [];

    @track groupCompliance = [];
    @track groupSdfs = [];
    @track groupSdgs = [];
    @track groupSkus = [];

    @track bogoQualifiers = [];
    @track bogoQualifiersSkus = [];
    @track bogoBeneficiaries = [];
    @track bogoBeneficiariesSkus = [];

    isGroupDataExists = false;
    isBogoExists = false;

    connectedCallback()
    {
        this.initData();
    }

    initData()
    {
        this.isBogoExists = false;
        this.isGroupDataExists = false;
        console.log('Child' + JSON.stringify(this.promoDetails));
        let compRules = [];
        let sdgs = [];
        let skus = [];
        let sdfs = [];

        let groupCompliance = [];
        let groupSdgs = [];
        let groupSkus = [];
        let groupSdfs = [];

        let __bogoQualifiers = [];
        let __bogoQualifiersSkus = [];
        let __bogoBeneficiaries = [];
        let __bogoBeneficiariesSkus = [];

        if(this.promoDetails!=null && this.promoDetails.benefits != null && this.promoDetails.benefits.length > 0 && this.promoDetails.benefits[0].complianceMessage !=null && this.promoDetails.benefits[0].complianceMessage.length > 0)
        {
            BwcUtils.log('### Initializing PromoDetailsExpands: ');
            BwcUtils.log(JSON.parse(JSON.stringify(this.promoDetails)));

            let compMsg = this.promoDetails.benefits[0].complianceMessage;
            if(typeof compMsg === 'string' )
            {
                compRules.push({id:Math.floor(100000 + Math.random() * 900000), rule:compMsg });
            }else
            {
                console.log('CM' + JSON.stringify(compMsg));
                compMsg.forEach(comp=>
                    {
                        if(typeof comp === 'string')
                        {
                            compRules.push({id:Math.floor(100000 + Math.random() * 900000), rule:comp });
                        }else
                        {
                            let key  = Object.keys(comp)[0];
                            if(key === SDFS_KEY)
                            {
                                sdfs = comp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                            }else if (key === SDGS_KEY)
                            {
                                sdgs = comp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                            }else if(key === SKU_KEY)
                            {
                                skus = comp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                            }else if(key.includes("Group must have"))
                            {
                                this.isGroupDataExists = true;
                                let groupCopliance = comp[key];
                                groupCompliance.push({id:Math.floor(100000 + Math.random() * 900000), rule:GROUP_KEY });
                                groupCopliance.forEach(grComp=>
                                    {
                                        if(typeof grComp === 'string')
                                        {
                                            groupCompliance.push({id:Math.floor(100000 + Math.random() * 900000), rule:grComp });
                                        }else
                                        {
                                            let key  = Object.keys(grComp)[0];
                                            if(key === SDFS_KEY)
                                            {
                                                groupSdfs = grComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                            }else if (key === SDGS_KEY)
                                            {
                                                groupSdgs = grComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                            }else if(key === SKU_KEY)
                                            {
                                                groupSkus = grComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                            }
                                        }
                                    });
                            }else if(key.includes("BOGO"))
                            {
                                this.isBogoExists = true;
                                let bogos = comp[key];
                                // groupCompliance.push({id:Math.floor(100000 + Math.random() * 900000), rule:GROUP_KEY });
                                bogos.forEach(bogoComp=>
                                    {
                                        // if(typeof bogoComp === 'string')
                                        // {
                                        //     groupCompliance.push({id:Math.floor(100000 + Math.random() * 900000), rule:bogoComp });
                                        // }else
                                        // {
                                        let key  = Object.keys(bogoComp)[0];

                                        if(key.includes(BOGO_QUALIFIER))
                                        {
                                            let qualifiers = bogoComp[key];
                                            qualifiers.forEach((qualifier) => 
                                            {
                                                if(typeof qualifier === 'string')
                                                {
                                                    __bogoQualifiers.push({id:Math.floor(100000 + Math.random() * 900000), rule:qualifier });
                                                }else
                                                {
                                                    let key  = Object.keys(qualifier)[0];
                                                    if(key === SKU_KEY)
                                                    {
                                                        __bogoQualifiersSkus = qualifier[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                                    }
                                                }
                                            });
                                        }else if (key.includes(BOGO_BENEFICIARY))
                                        {
                                            let beneficiaries = bogoComp[key];
                                            beneficiaries.forEach((beneficiary) => 
                                            {
                                                if(typeof beneficiary === 'string')
                                                {
                                                    __bogoBeneficiaries.push({id:Math.floor(100000 + Math.random() * 900000), rule:beneficiary });
                                                }else
                                                {
                                                    let key  = Object.keys(beneficiary)[0];
                                                    if(key === SKU_KEY)
                                                    {
                                                        __bogoBeneficiariesSkus = beneficiary[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                                    }
                                                }
                                            });
                                        }
                                        
                                        // if(key.includes(BOGO_QUALIFIER))
                                        // {
                                        //     groupSdfs = bogoComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                        // }else if (key === SDGS_KEY)
                                        // {
                                        //     groupSdgs = bogoComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                        // }else if(key === SKU_KEY)
                                        // {
                                        //     groupSkus = bogoComp[key].map((rule)=>({id:Math.floor(100000 + Math.random() * 900000), rule:rule }));
                                        // }
                                       // }
                                    });
                            }
                            else {
                                // Generic recursive search function that captures arbitrary depth
                                // in case we cant anticipate the formatting of the response
                                const searchForComplianceRules = (item, isIndented) => {
                                    if (item === null){
                                        return;
                                    }
                                    else if(typeof item === 'string') {
                                        compRules.push({id:Math.floor(100000 + Math.random() * 900000), rule: item, indented: isIndented });
                                        return;  
                                    } 
                                    else if(Array.isArray(item)) {
                                        item.forEach(elem => searchForComplianceRules(elem, isIndented));
                                    }
                                    else if(typeof item === 'object') {
                                        Object.entries(item).forEach(entry => {
                                            const [key, value] = entry;

                                            // Nesting List
                                            if(key !== 'Broadband') {
                                                compRules.push({id:Math.floor(100000 + Math.random() * 900000), rule: key, indented: false });
                                                searchForComplianceRules(value, true);
                                            }
                                            // Non Nesting List
                                            else {
                                                searchForComplianceRules(value, false);
                                            }
                                        })
                                    }
                                    else {
                                        return;
                                    }
                                };

                                searchForComplianceRules(comp, false);
                            }
                        }
                    });
            }
            // setTimeout(()=>{
                this.complianceRules = this.cloneData(compRules);
                this.ElligibleSKus = this.cloneData(skus);
                this.wirelessSdfs = this.cloneData(sdfs);
                this.wirelessSdgs = this.cloneData(sdgs);

                this.groupCompliance = this.cloneData(groupCompliance);
                this.groupSkus = this.cloneData(groupSkus);
                this.groupSdfs = this.cloneData(groupSdfs);
                this.groupSdgs = this.cloneData(groupSdgs);

                this.bogoQualifiers = this.cloneData(__bogoQualifiers);
                this.bogoQualifiersSkus = this.cloneData(__bogoQualifiersSkus);
                this.bogoBeneficiaries = this.cloneData(__bogoBeneficiaries);
                this.bogoBeneficiariesSkus = this.cloneData(__bogoBeneficiariesSkus);

            // },300);

        }
        console.log('TOM_comp' + this.complianceRules);
    }

    get showSkus()
    {
        return this.ElligibleSKus.length > 0 && !this.isGroupDataExists;
    }

    get showSdfs()
    {
        return this.wirelessSdfs.length > 0 && !this.isGroupDataExists;
    }

    get showSdgs()
    {
        return this.wirelessSdgs.length > 0 && !this.isGroupDataExists;
    }

    get showGroupLevel()
    {
        return this.groupCompliance.length > 0 && this.isGroupDataExists;
    }

    get showGroupSkus()
    {
        return this.groupSkus.length > 0 && this.isGroupDataExists;
    }

    get showGroupSdfs()
    {
        return this.groupSdfs.length > 0 && this.isGroupDataExists;
    }

    get showGroupSdgs()
    {
        return this.groupSdgs.length > 0 && this.isGroupDataExists;
    }

    get showBogoQualifiers()
    {
        return this.bogoQualifiers.length > 0;
    }

    get showBogoBeneficiaries()
    {
        return this.bogoBeneficiaries.length > 0;
    }

    get showBogoQualifiersSkus()
    {
        return this.bogoQualifiersSkus.length > 0;
    }

    get showBogoBeneficiariesSkus()
    {
        return this.bogoBeneficiariesSkus.length > 0;
    }

    get showBogos()
    {
        return this.bogoBeneficiaries.length > 0 || this.bogoBeneficiariesSkus.length > 0 || this.bogoQualifiers.length > 0 || this.bogoQualifiersSkus.length > 0  ;
    }

    get isGroupLevel()
    {
        return this.promoDetails.wirelessPromotionLevel === "groupLevel";
    }

    get isWireless() {
        // there are two important locations where the Wireless tag can show
        return this.promoDetails.promotionLob === "Wireless" 
            || (this.promoDetails.benefits?.[0] && this.promoDetails.benefits[0].lineOfBusiness === 'wireless');
    }

    get endDate()
    {
        let endDate = this.promoDetails.promotionEndDate;
        if(endDate != null && endDate.indexOf('-')!=  -1)
        {
            return endDate;
        }
        if( endDate != null && endDate.length > 0)
        {
            let year = endDate.substring(0,4);
            let month = endDate.substring(4,6);
            let day = endDate.substring(6,8);
            return `${year}-${month}-${day}`
        }
        return "";
    }

    @api
    openModal()
    {
        this.initData();
        this.template.querySelector('c-bwc-promotion-details-modal').openModal();
    }

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
    
        const style = document.createElement('style');
        style.innerText = `
        .promotionDetailsClass .slds-accordion__summary {
            background: #f3f3f3 !important;
            padding: 3px !important;
            font-size: 0.85rem;
            font-weight: bold;
        }
        `;
        this.template.querySelector('.stylebox').appendChild(style);
    }

    cloneData(obj) 
    {
        return JSON.parse(JSON.stringify(obj));
    }
}