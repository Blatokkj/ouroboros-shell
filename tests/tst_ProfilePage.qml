import QtQuick
import QtTest
import ".."

TestCase {
    name: "ProfilePage"
    visible: true
    when: windowShown
    width: 456; height: 354
    Theme { id: theme }
    QtObject {
        id: profile
        property string displayName: "blato"
        property string computerName: "White"
        property string avatar: ""
        property string userName: "blato"
        property string hostName: "archbtw"
        property bool ready: true
        property bool saving: false
        property string message: ""
        property bool error: false
        property int saves: 0
        signal saved()
        function save(name,computer,photo) {
            displayName=name;computerName=computer;avatar=photo;saves++;
            Qt.callLater(function(){profile.saved();});return true;
        }
    }
    ProfilePage { id: page; anchors.fill: parent; theme: theme; profile: profile; active: true }
    function cleanup() {
        page.active=false;
        profile.displayName="blato";profile.computerName="White";profile.avatar="";profile.saves=0;
        page.resetDraft();page.active=true;
    }
    function test_cancelDoesNotWrite() {
        findChild(page,"profileName").text="Rascunho";
        verify(page.dirty);
        mouseClick(findChild(page,"profileCancel"));
        compare(findChild(page,"profileName").text,"blato");
        compare(profile.saves,0);verify(!page.dirty);
    }
    function test_saveCommitsBothEditableNames() {
        findChild(page,"profileName").text="Blato";
        findChild(page,"profileComputer").text="White pessoal";
        mouseClick(findChild(page,"profileSave"));
        compare(profile.saves,1);
        compare(profile.displayName,"Blato");compare(profile.computerName,"White pessoal");
        tryCompare(page,"dirty",false);
    }
    function test_closingPanelClosesPhotoDialog() {
        page.pickPhoto();
        verify(page.choosingPhoto);
        tryCompare(findChild(page,"profilePhotoDialog"),"visible",true);
        page.active=false;
        verify(!page.choosingPhoto);
        verify(!findChild(page,"profilePhotoDialog").visible);
    }
}
