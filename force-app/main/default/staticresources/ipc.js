"use strict";
function hasIPC() {
  var name = "apex__ipc=";
  var ca = document.cookie.split(";");
  for (var i = 0; i < ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) == " ") {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return true;
    }
  }
  return false;
}

var probe = setInterval(function() {
  if (hasIPC()) {
    Lock();
    doLoginAF();
  }
}, 1000);

function clearProbe() {
  window.clearInterval(probe);
}

function loadAppLauncher(target) {
  probe = setInterval(function() {
    if (hasIPC()) {
      var parser = document.createElement("a");
      parser.href = target;
      parser.pathname = "";
      parser.search = "";
      parser.hash = "";
      location.replace(parser.href);
    }
  }, 1000);
}
