export const attempt2str = ( attempt ) => {
  let res = "";
  if ( attempt === 1 ) {
    res = "1-st";
  }
  else if ( attempt === 2 ) {
    res = "2-nd";
  }
  else if ( attempt > 0 ) {
    res = "" + attempt + "-th";
  }
  return res;
} 

export const attemptPopClasses = ( isShow ) => {
  return (isShow) ?
  "slds-popover slds-popover_tooltip slds-nubbin_top slds-rise-from-ground"
  : "slds-popover slds-popover_tooltip slds-nubbin_top slds-fall-into-ground";
}