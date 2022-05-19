public with sharing class BWC_Notification {

    /*
        Corresponds to a notification that can be presented using the LWC bwcNotification.
    */
    public class Notification {
        public String type;
        public String variant;
        public String theme;
        public String texture;
        public Boolean closeButton;
        public Action action;
        public String message;
        public List<NotificationItem> items;
    }

    /*
        One message plus optional action to display within the same notification.
    */
    public class NotificationItem {
        public String message;
        public Action action;

        public NotificationItem() {}

        public NotificationItem(String message) {
            this.message = message;
        }
    }

    /*
        An action to show as a hyperlink after the message.
    */
    public virtual class Action {
        public String name;
        public String message;
        public String href;
        public Icon icon;

        public Action() {}

        public Action(String name, String message) {
            this.name = name;
            this.message = message;
        }
    }

    /*
        Allows icon to be displayed with an item.
    */
    public virtual class Icon {
        public String name;
    }

}