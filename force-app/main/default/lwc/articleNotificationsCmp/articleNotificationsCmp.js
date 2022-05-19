import {
  LightningElement,
  wire,
  api,
  track
} from "lwc";
import {
  ShowToastEvent
} from "lightning/platformShowToastEvent";
//import getRelatedTask from "@salesforce/apex/ArticleNotificationController.getRelatedTask";
//import markTaskCompleted from "@salesforce/apex/ArticleNotificationController.markTaskCompleted";
import {
  refreshApex
} from "@salesforce/apex";
import {
  subscribe,
  unsubscribe,
  onError,
  setDebugFlag,
  isEmpEnabled
} from "lightning/empApi";

const actions = [{
  label: "Mark Completed",
  name: "markCompleted"
}];
const columns = [{
    label: "Article Number",
    fieldName: "articleLink",
    type: "url",
    sortable: true,
    cellAttributes: {
      alignment: "left",
      title: "articleNumber"
    },
    title: "articleNumber",
    typeAttributes: {
      label: {
        fieldName: "articleNumber"
      },
      target: "_blank",
      title: "articleNumber"
    }
  },
  {
    label: "Subject",
    fieldName: "notificationSubject",
    sortable: true,
    cellAttributes: {
      alignment: "left"
    }
  },
  {
    label: "Status",
    fieldName: "notificationStatus",
    sortable: true,
    cellAttributes: {
      alignment: "left"
    }
  },
  {
    type: "action",
    typeAttributes: {
      rowActions: actions
    }
  }
];
export default class ArticleNotificationsCmp extends LightningElement {
  @api recordId;
  @track data = [];
  channelName = "/event/UrgentArticleNotification__e";
  columns = columns;
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;
  allTaskResponse;
  showTable = false;
  errorMessage = "";
  @track progress = 1000 * 5 * 60;

  /*@wire(getRelatedTask, {})
  wiredTasks(result) {
    this.allTaskResponse = result;
    console.log("result", result);
    if (result.data) {
      if (result.data.isSuccess) {
        this.showTable = true;
        this.data = result.data.notifications;
      } else {
        this.errorMessage = result.data.errorMessage;
        //this.showToast("Error", result.data.errorMessage, "error");
      }
    }
  }*/

  // Initializes the component
  connectedCallback() {
    var self = this;
    self._interval = setInterval(() => {
      console.log("Refresh");
      self.refreshAllRelatedTask();
    }, self.progress);

    self.handleSubscribe();
    self.registerErrorListener();
  }

  // Used to sort the 'Subject' column
  sortBy(field, reverse, primer) {
    const key = primer ?
      function (x) {
        return primer(x[field]);
      } :
      function (x) {
        return x[field];
      };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }

  onHandleSort(event) {
    const {
      fieldName: sortedBy,
      sortDirection
    } = event.detail;
    const cloneData = [...this.data];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.data = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    console.log("actionName", actionName);
    switch (actionName) {
      case "markCompleted":
        this.handleMarkCompleted(row);
        break;
      default:
    }
  }

  handleMarkCompleted(row) {
    const {
      notificationId
    } = row;
    const {
      notificationStatus
    } = row;
    const index = this.findRowIndexById(notificationId);

    console.log(
      "row",
      notificationId,
      notificationStatus,
      JSON.stringify(row),
      index
    );
    //check status is not completed.
    if (notificationStatus != "Completed") {
      this.markNotificationCompleted(notificationId);
    } else {
      this.showToast("Info", "Notification alredy Completed.", "info");
    }
  }

  refreshAllRelatedTask() {
    getRelatedTask()
      .then(result => {
        console.log("refreshAllRelatedTask", result);
        if (result.isSuccess) {
          this.data = result.notifications;
        } else {
          this.showToast("Error", result.errorMessage, "error");
        }
      })
      .catch(error => {
        console.log("result", error);
        this.showToast("Error", error + "", "error");
      });
  }
  /*markNotificationCompleted(notificationId) {
    markTaskCompleted({
        notificationId: notificationId
      })
      .then(result => {
        console.log("result", result);
        if (result.isSuccess) {
          this.handAfterTaskComplete();
          this.showToast(
            "Success",
            "Notification marked Completed.",
            "success"
          );
        } else {
          this.showToast("Error", result.errorMessage, "error");
        }
      })
      .catch(error => {
        console.log("result", error);
        this.showToast("Error", error, "error");
      });
  }*/

  findRowIndexById(id) {
    let ret = -1;
    this.data.some((row, index) => {
      if (row.notificationId === id) {
        ret = index;
        return true;
      }
      return false;
    });
    return ret;
  }
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  handAfterTaskComplete() {
    return refreshApex(this.allTaskResponse);
  }

  // Handles subscribe button click
  handleSubscribe() {
    let self = this;
    // Callback invoked whenever a new event message is received
    const messageCallback = function (response) {
      console.log("New Task: ", JSON.stringify(response));
      self.handAfterTaskComplete();
    };

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(self.channelName, -1, messageCallback).then(response => {
      // Response contains the subscription information on subscribe call
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      self.subscription = response;
    });
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError(error => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }
}