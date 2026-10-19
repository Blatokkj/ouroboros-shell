import QtQuick

// UI mirror only: never writes to the native lock or decides authentication.
// QS 0.3.2 can finish unlock without notifying the locked property's binding.
QtObject {
    id: root
    required property var backend
    property bool sampledLocked: true
    property bool sampledSecure: false
    readonly property bool locked: sampledLocked
    readonly property bool secure: sampledSecure
    function refresh() {
        sampledLocked = backend.locked;
        sampledSecure = backend.secure;
    }
    function resample() {
        refresh();
        // secureStateChanged can precede completion of the native transition.
        Qt.callLater(refresh);
    }
    Component.onCompleted: resample()
    property Connections events: Connections {
        target: root.backend
        function onLockStateChanged() { root.resample(); }
        function onSecureStateChanged() { root.resample(); }
    }
}
