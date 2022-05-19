// import audioIcon from '@salesforce/resourceUrl/audio_wave';

// export const RAISR_INPUT_STATUS = Object.freeze({
//   WAITING: "WAITING",
//   DISABLED: "DISABLED",
//   FOCUSED: "FOCUSED",
//   RETRY: "RETRY",
//   MANUAL_INPUT: "MANUAL",
//   RAISR_INPUT: "RAISR",
//   RECIEVING_DATA: "RECIEVING_DATA",
//   DONE: "DONE",
//   ERROR: "ERROR",
// });

// const defaultIconClasses = "slds-icon slds-input__icon slds-input__icon_right slds-icon-text-default slds-icon_xx-small ";
// export const STATUS_2_ICON = Object.freeze({
//   [RAISR_INPUT_STATUS.WAITING]:  { icon: `${audioIcon}#audio-wave`, classes: defaultIconClasses + " raisr-active", },
//   [RAISR_INPUT_STATUS.DISABLED]: { icon: `${audioIcon}#audio-wave`, classes: defaultIconClasses + " raisr-disabled", },
//   [RAISR_INPUT_STATUS.FOCUSED]: { icon: `${audioIcon}#audio-wave`, classes: defaultIconClasses + " raisr-active", },
//   [RAISR_INPUT_STATUS.RAISR_INPUT]: { icon: `${audioIcon}#audio-wave`, classes: defaultIconClasses + " raisr-active", },
//   [RAISR_INPUT_STATUS.RECIEVING_DATA]: { icon: `${audioIcon}#audio-wave`, classes: defaultIconClasses + " raisr-recieving", },
//   [RAISR_INPUT_STATUS.DONE]: { icon: `${audioIcon}#audio-wave`, class: defaultIconClasses + " raisr-complete", },
//   [RAISR_INPUT_STATUS.ERROR]: { icon: `${audioIcon}#audio-wave`, class: defaultIconClasses + " raisr-error", },
//   [RAISR_INPUT_STATUS.RETRY]: { icon: "utility:refresh", class: defaultIconClasses + " black", },
//   [RAISR_INPUT_STATUS.MANUAL_INPUT]: { icon: "utility:close", class: defaultIconClasses + " black", },
// });