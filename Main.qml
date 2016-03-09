import QtQuick 2.0
import Ubuntu.Components 1.1
import QtQuick.LocalStorage 2.0

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    id: mainView
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "dynamictab.liu-xiao-guo"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    // Removes the old toolbar and enables new features of the new header.
    useDeprecatedToolbar: false

    width: units.gu(60)
    height: units.gu(85)

    Component.onCompleted: {
        mainView.initializeDB();
        mainView.saveFeed("BBC News","http://feeds.bbci.co.uk/news/rss.xml");
        mainView.saveFeed("Jono Bacon","http://www.jonobacon.org/?feed=rss2");
        mainView.saveFeed("The Register", "http://www.theregister.co.uk/headlines.atom");
        fillTabs();
    }

    Tabs {
        id: initialtabs
        anchors.fill: parent


//        // First tab begins here
//        Tab {
//            id: tabFrontPage
//            objectName: "tabFrontPage"

//            title: i18n.tr("Front Page")

//            // Tab content begins here
//            page: Page {
//                Column {
//                     anchors.centerIn: parent
//                    Label {
//                        id: labelFrontPage
//                        text: i18n.tr("This will be the front page \n An aggregation of the top stories from each feed")
//                    }
//                }
//            }
//        }
    }


    function fillTabs() {
        initialtabs.destroy();
        var objStr = "import QtQuick 2.0; import Ubuntu.Components 1.1; import QtQuick.XmlListModel 2.0; Tabs{ id:tabs; anchors.fill:parent;"
        var db = getDatabase();
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT * FROM feeds;');
            if (rs.rows.length > 0) {
                for(var i = 0; i < rs.rows.length; i++) {
                    objStr += "Tab { id:tab" + i + ";anchors.fill:parent;title:'" + rs.rows.item(i).feedName + "';
                               property string source: '" + rs.rows.item(i).feedURL + "';
                               page: Page { anchors.margins: units.gu(2);Column {anchors.centerIn: parent;
                               Label{text:tab" + i + ".source;}}}}";
                }
                objStr += "}";

                console.log("objStr: " + objStr );
                var cmpTabs = Qt.createQmlObject(objStr, mainView, "tabsfile");
            } else {
                res = "Unknown";
            }
        })
    }

    //Create tabs for each feed
    function createTabs() {
        var feeds = getFeeds();
        for (var i = 0; i < feeds.length; i++){
            //Add tab for each feed.
            // Cannot be done with existing API

        }
    }

    //Storage API
    function getDatabase() {
        return LocalStorage.openDatabaseSync("news-feed","1.0","StorageDatabase",10000)
    }

    //Initialise DB tables if not already existing
    function initializeDB() {
        var db = getDatabase();
        db.transaction(function(tx) {
            //Create settings table if not existing
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)');
            tx.executeSql('CREATE TABLE IF NOT EXISTS feeds(feedName TEXT UNIQUE, feedURL TEXT UNIQUE)')
        });
    }

    //Write setting to DB
    function setSetting(setting,value){
        //setting: string - setting name (key)
        //value: string - value
        var db = getDatabase();
        var res = "";
        db.transaction(function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?);',[setting,value]);
            //console.log(rs.rowsAffected)
            if(rs.rowsAffected > 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        })
        return res;
    }

    //Read setting from DB
    function getSetting(setting) {
        var db = getDatabase();
        var res="";
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM settings WHERE setting=?;', [setting]);
            if (rs.rows.length > 0) {
                res = rs.rows.item(0).value;
            } else {
                res = "Unknown";
            }
        })
        // The function returns “Unknown” if the setting was not found in the database
        // For more advanced projects, this should probably be handled through error codes
        return res;
    }

    function saveFeed(feedName, feedURL) {
        var db = getDatabase();
        var res = "";
        db.transaction(function(tx){
            var rs = tx.executeSql('INSERT OR REPLACE INTO feeds VALUES (?,?)',[feedName,feedURL]);
            //console.log(rs.rowsAffected)
            if (rs.rowsAffected > 0) {
                res = "OK";
            } else {
                res = "Error";
            }
        })
        return res;
    }

    //Return a single feed
    function getFeed(feedName) {
        var db = getDatabase();
        var res = "";
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT feedURL FROM feeds WHERE feedName=?;', [feedName]);
            if (rs.rows.length > 0) {
                res = rs.rows.item(0).feedURL;
            } else {
                res = "Unknown";
            }

        })
        return res;
    }

    //Return all feeds and urls
    function getFeeds() {
        var db = getDatabase();
        var res = "";
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT * FROM feeds;');
            if (rs.rows.length > 0) {
                return rs;
            } else {
                res = "Unknown";
            }
        })

        return res;
    }
}

