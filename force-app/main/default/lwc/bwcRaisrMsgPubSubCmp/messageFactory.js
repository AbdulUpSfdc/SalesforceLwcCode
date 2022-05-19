export const MSG_SORCE = Object.freeze({
  RAISR_DROP_DOWN_CONTROL: "RAISR_DROP_DOWN_CONTROL",
  RAISR_UTIL_BAR_CONTROL: "RAISR_UTIL_BAR_CONTROL",
  RAISR_FIELD: "RAISR_FIELD",
});

// Requests/Responses
export const MSG_TYPE = Object.freeze({
  RAISR_DISABLED_REQ: "RAISR_DISABLED_REQ",
  RAISR_MANAGER_STARTED: "RAISR_MANAGER_STARTED",
  RAISR_CONTROL_FORM_STARTED: "RAISR_CONTROL_FORM_STARTED",
  RAISR_CONTROL_FORM_STARTED_INTERNAL: "RAISR_CONTROL_FORM_STARTED_INTERNAL",
  RAISR_STATUS: "RAISR_STATUS",
  RAISR_STATUS_INTERNAL: "RAISR_STATUS_INTERNAL",
  FIELD_REGISTER_REQ: "FIELD_REGISTER_REQ",
  FIELD_UNREGISTER_REQ: "FIELD_UNREGISTER_REQ",
  FIELD_FOCUS: "FIELD_FOCUS",
  FIELD_CHANGE: "FIELD_CHANGE",  // Change text in the Smart Field
  RAISR_DIGITS: "RAISR_DIGITS",
  RAISR_COMPLETE: "RAISR_COMPLETE",
  RAISR_ERROR: "RAISR_ERROR",
  RAISR_PROMPT: "RAISR_PROMPT",
  RIASR_REQ_ERROR: "RAISR_REQ_ERROR", // ERROR send by SC-SPI about wrong command
});

export const raisrCtrlFormButtonRegistration = () => {
  return {
    messageSource: MSG_SORCE.RAISR_DROP_DOWN_CONTROL,
    messageType: MSG_TYPE.RAISR_CONTROL_FORM_STARTED_INTERNAL,
    messageBody: {}    
  };
}

export const smartFieldRegistrationReq = ( context, raisrFieldType, fieldIdOrName ) => {
  return {
    messageSource: MSG_SORCE.RAISR_FIELD,
    messageType: MSG_TYPE.FIELD_REGISTER_REQ,
    messageBody: {
      fieldIdOrName: fieldIdOrName,
      context: context,
      raisrFieldType: raisrFieldType
    }    
  };
}

export const smartFieldUnregistrationReq = ( context, raisrFieldType, fieldIdOrName ) => {
  return {
    messageSource: MSG_SORCE.RAISR_FIELD,
    messageType: MSG_TYPE.FIELD_UNREGISTER_REQ,
    messageBody: {
      fieldIdOrName: fieldIdOrName,
      context: context,
      raisrFieldType: raisrFieldType
    }    
  };
}

export const raisrManagerRegistered = ( isRaisrActive ) => {
  return {
    messageSource: MSG_SORCE.RAISR_UTIL_BAR_CONTROL,
    messageType: MSG_TYPE.RAISR_MANAGER_STARTED,
    messageBody: {
      isRaisrActive: isRaisrActive
    }
  }
}

export const raisrStatus = ( isRaisrActive, reason ) => {
  return {
    messageSource: MSG_SORCE.RAISR_DROP_DOWN_CONTROL,
    messageType: MSG_TYPE.RAISR_STATUS,
    messageBody: {
      isRaisrActive: isRaisrActive,
      reason: reason
    }
  };
}

// RaisrStatus only for BROWSER, not SC-SPI/RAISR
export const raisrStatusInternal = ( isRaisrActive, reason ) => {
  return {
    messageSource: MSG_SORCE.RAISR_DROP_DOWN_CONTROL,
    messageType: MSG_TYPE.RAISR_STATUS_INTERNAL,
    messageBody: {
      isRaisrActive: isRaisrActive,
      reason: reason
    }
  };
}

export const fieldFocus = ( context, name, type ) => {
  const req = {
    messageSource: MSG_SORCE.RAISR_FIELD,
    messageType: MSG_TYPE.FIELD_FOCUS,
    messageBody: {
      fieldIdOrName: name,
      context: context,
      raisrFieldType: type
    }
  };
  console.debug( "fieldFocus() res: " + JSON.stringify( req ) );
  return req;
}

export const raisrPrompt = ( context, name, type ) => {
  return {
    messageSource: MSG_SORCE.RAISR_UTIL_BAR_CONTROL,
    messageType: MSG_TYPE.RAISR_PROMPT,
    messageBody: {
      context: context,
      fieldIdOrName: name,
      raisrFieldType: type
    }
  };
}

export const raisrDigits = ( context, name, type, value ) => {
  return {
    messageSource: MSG_SORCE.RAISR_UTIL_BAR_CONTROL,
    messageType: MSG_TYPE.RAISR_DIGITS,
    messageBody: {
      context: context,
      fieldIdOrName: name,
      raisrFieldType: type,
      fieldValue: value
    }
  };
}

export const raisrComplete = ( context, name, type, value, token ) => {
  return {
    messageSource: MSG_SORCE.RAISR_UTIL_BAR_CONTROL,
    messageType: MSG_TYPE.RAISR_COMPLETE,
    messageBody: {
      context: context,
      fieldIdOrName: name,
      raisrFieldType: type,
      fieldValue: value,
      token: token
    }
  };
}

export const raisrError = ( context, name, type, errorCode, errDescr ) => {
  return {
    messageSource: MSG_SORCE.RAISR_UTIL_BAR_CONTROL,
    messageType: MSG_TYPE.RAISR_ERROR,
    messageBody: {
      context: context,
      fieldIdOrName: name,
      raisrFieldType: type,
      errorCode: errorCode,
      errorDescr: errDescr
    }
  };
}

/***
 
  
    SF RAISR channel messages:
    =====================================================================
    
    const msg = {
      messageSource: MSG_SRC,
      messageType: MSG_TYPE_DISABLE_RAISR,
      messageBody: {
        reason: this.value
      }
    };


    Messages FROM RAISR
    ====================================================================

{"name":"SUCCESS","message":"REGISTER","callReferenceNumber":"1111222233334444"}

{"name":"DIGIT","fieldName":"creditCardNumber","fieldValue":"*************"}
{"name":"DIGIT","fieldName":"zipCode","fieldValue":"07748"}

{"name":"COMPLETE","fieldName":"creditCardNumber","fieldValue":"************1100","success":true,"token":"c8e048dc-22b4-426c-97de-01f5f62df6ac"}
{"name":"COMPLETE","fieldName":"zipCode","fieldValue":"07748","success":true}

{"name":"PROMPT","fieldName":"creditCardNumber"}

{"name":"DISCONNECT","reason":"callTermination"}

 */