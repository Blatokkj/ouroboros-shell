import QtQuick
import QtTest
import ".."

TestCase {
    name: "SessionLockState"
    QtObject {
        id: native
        // Only the explicit native signals are observed by the UI mirror.
        property var state: ({locked:false, secure:false})
        readonly property bool locked: state.locked
        readonly property bool secure: state.secure
        signal lockStateChanged()
        signal secureStateChanged()
    }
    SessionLockState { id: mirror; backend: native }
    function setNative(locked,secure) { native.state = {locked:locked,secure:secure}; }
    function cleanup() { setNative(false,false); mirror.refresh(); }
    function test_repeatedCyclesAndSecureNotification() {
        for(let i=0;i<3;i++) {
            setNative(true,false); native.lockStateChanged();
            verify(mirror.locked);
            setNative(true,true); native.secureStateChanged();
            verify(mirror.locked && mirror.secure);
            setNative(false,false); native.secureStateChanged();
            tryCompare(mirror,"locked",false);
            verify(!mirror.secure);
        }
    }
    function test_secureFalseDoesNotMeanUnlocked() {
        setNative(true,false); native.secureStateChanged();
        verify(mirror.locked);
    }
    function test_explicitResampleAfterPam() {
        setNative(true,true); mirror.refresh();
        setNative(false,false); // No native lockStateChanged at all.
        verify(mirror.locked);
        mirror.resample();
        verify(!mirror.locked);
    }
    function test_signalBeforeNativeTransitionCompletes() {
        setNative(true,true); mirror.refresh();
        native.secureStateChanged();
        setNative(false,false);
        verify(mirror.locked);
        tryCompare(mirror,"locked",false);
    }
}
