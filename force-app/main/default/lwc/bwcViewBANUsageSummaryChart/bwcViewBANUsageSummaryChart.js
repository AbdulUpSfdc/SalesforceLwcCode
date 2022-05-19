import { LightningElement, api } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Labels
import label_usageSummaryDisclaimer from '@salesforce/label/c.BWC_Customer_Usage_Summary_Chart_Disclaimer';

// Colors for chart
const backgroundColors = [
    'rgb(179,226,244,1)','rgb(153,216,241,1)','rgb(128,207,237,1)','rgb(102,197,233,1)','rgb(77,187,230,1)',
    'rgb(51,177,226,1)','rgb(26,168,223,1)','rgb(0,158,219,1)','rgb(0,142,197,1)','rgb(0,126,175,1)','rgb(0,111,153,1)',
    'rgb(0,95,131,1)','rgb(0,79,110,1)','rgb(0,63,88,1)','rgb(0,32,44,1)'
];

export default class BwcViewBANUsageSummaryChart extends LightningElement {
    
    @api usageSummary;
    @api planTypeSelected = 'data';

    labels = {
        usageSummaryDisclaimer: label_usageSummaryDisclaimer
    };

    get showLegends() {
        return this.chartLegends.length > 0;
    }

    isRendered = false;
    renderedCallback() {
        if (this.isRendered) {
            return;
        }
        this.isRendered = true;
        this.Init();
    }

    Init() {
        Promise.all([
            loadScript(this, chartjs)
        ])
        .then(() => {
            this.initializeChart();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading chartJs',
                    message: error.message,
                    variant: 'error'
                })
            );
        });
    }

    usageSummaryChart;
    chartData = {};
    dataChartData = {};
    textChartData = {};
    talkChartData = {};
    dataChartColors = [];
    textChartColors = [];
    talkChartColors = [];
    chartLegends = [];
    dataChartLegends = [];
    textChartLegends = [];
    talkChartLegends = [];
    planTotalUsage = 0;
    planUom = '';

    @api async initializeChart() {

        this.chartData = {};
        this.chartLegends = [];
        this.dataChartLegends = [];
        this.textChartLegends = [];
        this.talkChartLegends = [];
        this.planTotalUsage = 0;
        this.planUom = '';

        await this.initializeData();

        //Get the context of the canvas element we want to select
        var ctx = this.template.querySelector(".data-usage-chart");
        if (this.usageSummaryChart) {
            this.usageSummaryChart.destroy();
        }
        this.usageSummaryChart = new Chart(ctx, {
            type: 'doughnut',
            data: this.chartData,
            options: {
                responsive: false,
                maintainAspectRation: false,
                legend: {
                    display: false,
                    position: 'bottom',
                    labels: {
                        padding: 15
                    }
                },
                title: {
                    display: false,
                    text: 'Lines',
                    position: 'bottom',
                    align: 'start'
                },
                cutoutPercentage: 70,
                layout: {
                    padding: {
                        top: 10,
                        bottom: 10
                    }
                }
            }
        });
    }

    async initializeData() {

        let dataPlanUsage = this.usageSummary.dataPlanUsage;
        let dataLabels = [];
        let dataDatasetData = [];
        let dataBackgroundColors = backgroundColors.slice();
        if (dataPlanUsage.usageByCtn) {
            dataPlanUsage.usageByCtn.forEach((individualUsage, index) => {
                dataLabels.push(individualUsage.subscriberName);
                dataDatasetData.push(individualUsage.used);

                this.dataChartColors.push(dataBackgroundColors[index]);
                
                this.dataChartLegends.push({
                    'name' : individualUsage.subscriberName,
                    'color' : `background-color: ${dataBackgroundColors[index]};`,
                    'elementKey' : individualUsage.subscriberId + '-data'
                });

                // Remove color from array, if no more colors left, start again
                dataBackgroundColors.splice(index, 1);
                if (dataBackgroundColors.length == 0) dataBackgroundColors = backgroundColors.slice();
            });
            this.dataChartData = {
                labels: dataLabels,
                datasets: [
                    {
                        label: 'Lines',
                        data: dataDatasetData,
                        backgroundColor: this.dataChartColors
                    }
                ]
            };
        }

        // Process Text Plan Usage
        let textPlanUsage = this.usageSummary.textPlanUsage;
        let textLabels = [];
        let textDatasetData = [];
        let textBackgroundColors = backgroundColors.slice();
        if (textPlanUsage.usageByCtn) {
            textPlanUsage.usageByCtn.forEach((individualUsage, index) => {
                textLabels.push(individualUsage.subscriberName);
                textDatasetData.push(individualUsage.used);
    
                this.textChartColors.push(textBackgroundColors[index]);
    
                this.textChartLegends.push({
                    'name' : individualUsage.subscriberName,
                    'color' : `background-color: ${textBackgroundColors[index]};`,
                    'elementKey' : individualUsage.subscriberId + '-text'
                });
    
                // Remove color from array, if no more colors left, start again
                textBackgroundColors.splice(index, 1);
                if (textBackgroundColors.length == 0) textBackgroundColors = backgroundColors.slice();
            });
            this.textChartData = {
                labels: textLabels,
                datasets: [
                    {
                        label: 'Lines',
                        data: textDatasetData,
                        backgroundColor: this.textChartColors
                    }
                ]
            };
        }

        // Process Talk Plan Usage
        let talkPlanUsage = this.usageSummary.talkPlanUsage;
        let talkLabels = [];
        let talkDatasetData = [];
        let talkBackgroundColors = backgroundColors.slice();
        if (talkPlanUsage.usageByCtn) {
            talkPlanUsage.usageByCtn.forEach((individualUsage, index) => {
                talkLabels.push(individualUsage.subscriberName);
                talkDatasetData.push(individualUsage.used);
    
                this.talkChartColors.push(talkBackgroundColors[index]);
    
                this.talkChartLegends.push({
                    'name' : individualUsage.subscriberName,
                    'color' : `background-color: ${talkBackgroundColors[index]};`,
                    'elementKey' : individualUsage.subscriberId + '-talk'
                });
    
                // Remove color from array, if no more colors left, start again
                talkBackgroundColors.splice(index, 1);
                if (talkBackgroundColors.length == 0) talkBackgroundColors = backgroundColors.slice();
            });
            this.talkChartData = {
                labels: talkLabels,
                datasets: [
                    {
                        label: 'Lines',
                        data: talkDatasetData,
                        backgroundColor: this.talkChartColors
                    }
                ]
            };
        }

        // Set data for chart depending on the type selected
        // Set legends for chart depending on the type selected
        if (this.planTypeSelected === 'data') {
            this.chartData = this.dataChartData;
            this.chartLegends = this.dataChartLegends;
            this.planTotalUsage = this.usageSummary.dataPlanUsage.totalUsed;
            this.planUom = this.usageSummary.dataPlanUsage.uom;
        } else if (this.planTypeSelected === 'text') {
            this.chartData = this.textChartData;
            this.chartLegends = this.textChartLegends;
            this.planTotalUsage = this.usageSummary.textPlanUsage.totalUsed;
            this.planUom = this.usageSummary.textPlanUsage.uom;
        } else if (this.planTypeSelected === 'talk') {
            this.chartData = this.talkChartData;
            this.chartLegends = this.talkChartLegends;
            this.planTotalUsage = this.usageSummary.talkPlanUsage.totalUsed;
            this.planUom = this.usageSummary.talkPlanUsage.uom;
        } else {
            this.chartData = null;
            this.chartLegends = null;
            this.planTotalUsage = 0;
            this.planUom = '';
        }
    }
}