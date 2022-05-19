/*
 * At&t OPUS - Salesforce communication library
 * 
 * Version: 1.0
 * Date: 9/23/2020
 */

(function (window, exportName) {
    'use strict';    

    var opussfcommDef = function () {
        var destination = "*";
        var executeCallback;
        var executeCallbackGlobal;
        var destinationWindow;
        var domainListArr = ["att.com","att.net"];
        var opuslogger;
        var findFrame;

        this.registerDestination = function (dst) {
            destination = dst;
            debug("Registered destination: "+destination);
            return this;
        };

        this.registerReceiverEventListener = function (callback, callbackGlobal) {
            if(callbackGlobal) {
                executeCallbackGlobal = callback;
            } else {
            executeCallback = callback;
            }

            if (window.addEventListener) {
                addEventListener("message", receive, false);
            } else {
                attachEvent("onmessage", receive);
            }
            debug("Registered Receiver Callback");
            return this;
        };

        this.registerWindow = function (dstWindow) {
            destinationWindow = dstWindow;
            debug("Registered Destination Window");
            return this;
        };

        this.findFrameCallback = function(findFrameCall) {
            findFrame = findFrameCall;
            return this;
        };

        this.addDomainList = function(domainLists) {
            if(Array.isArray(domainLists)) {
                Array.prototype.push.apply(domainListArr,domainLists);
            }
            return this;
        };

        this.registerLogger = function(logger) {
            opuslogger = logger;
        };

        this.send = sendMessage;
        
        function sendMessage(task, data) {
            var msg = {
                "task": task,
                "data": data
            };
            var message = {"msg": msg};
            if(!destinationWindow && findFrame) {
                findFrame(function(dstWindow) {
                    destinationWindow = dstWindow;
                });
            }
           
            if (destinationWindow)
            {
                destinationWindow.postMessage(message, destination);
                debug("Message Sent Successfully:: "+JSON.stringify(message));
            }
            else{
                debug("Distination Window is undefined");
            }
        };

        function receive(event) {
            if(destination==="*") {
                var hostname = getHostname(event.origin);
                var domain = getOurDomain(hostname);
                var currentHost = window.location.origin;
                if(currentHost!==event.origin && domainListArr.indexOf(domain) >= 0){
                    destination = event.origin;
                }
            }

            if (event.origin === destination)
            {
                if (isDataValid(event.data['msg']))
                {
                    if(event.data['msg'].task==="beginHandshake") { //reply 
                        sendMessage("readyHandshake",null);
                    } else if(event.data['msg'].task==="readyHandshake") { 
                            debug("Ready to receive Messages from ::"+event.origin);
                        
                    } else
                    {
                        if(executeCallbackGlobal) {
                            executeCallbackGlobal(event.data['msg']);
                        }
                        if(executeCallback) {
                        executeCallback(event.data['msg']);
                    }
                            debug("Message recived is "+JSON.stringify(event.data['msg']));
                    }
                }
            } else {
                debug("Message recived from Unregistered Host::"+event.origin);
                debug("Current registered host is ::"+destination);
            }
            return;
        };
        
        var validateInputJson = function (text) {
           return text;
           // return text.replace(/[\$\&\#\*\<\>\=]/g, "\\$&");
        };

        function isDataValid(msg) { //data validation callback can also be provided
            if (msg.task) {
                if (msg.data == null)
                    return true;
                else if (!isValidJson(msg)) //rule 1
                    return false;
            } else
                return false;
            return true;
        };
        function isValidJson(msg) {
            var json;
            try {
                if (typeof msg.data === "object") {
                    json = JSON.stringify(msg.data);
                } else {
                    json = msg.data;
                }
                json = validateInputJson(json);
                msg.data = JSON.parse(json);
                return true;
            } catch (e) {
                //invalid JSON, inform parent
                var task = "error";
                var message = {
                    "errorCode": "1",
                    "description": "Invalid JSON"
                };
                sendMessage(task, message);
                err(e);
                
                return false;
            }
        };

        function getHostname(url) {
            var match = url.match(/:\/\/(www[0-9]?\.)?(.[^/:]+)/i);
            if (match != null && match.length > 2 && typeof match[2] === 'string' && match[2].length > 0) return match[2];
        };   

        function getOurDomain(val) {
            var url = val;
            if (url.indexOf('\.') > 0) {
                var values = url.split('.');
                return (values.length >= 2) ? values[values.length - 2] + '.' + values[values.length - 1] : url;
            }
            return url;
        };

        function debug(str){
           if(opuslogger){
               opuslogger.debug(str);
           }else{
                window.console.debug(str);
           }
        }

        function err(e){
          if(opuslogger){
              opuslogger.error(e);
          }else{
            window.console.error(e);
         }
        }
    };

    var opussfcomm = new opussfcommDef();

    if (typeof define === 'function' && define.amd) {
        define(function () {
            return opussfcomm;
        });
    } else if (typeof module != 'undefined' && module.exports) {
        module.exports = opussfcomm;
    } else {
        window[exportName] = opussfcomm;
    }
})(window, 'opussfcomm');
