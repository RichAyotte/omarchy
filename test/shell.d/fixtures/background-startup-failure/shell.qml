import QtQuick
import Quickshell
import "services"
import "background" as BackgroundPlugin

ShellRoot {
  id: test
  property var services: ({ "omarchy.background": background })
  property var bar: ({})
  property bool failed: false
  property bool linkSettled: false
  function firstPartyServiceFor(id) { return services[id] || null }
  function check(ok, message) {
    if (!ok) {
      failed = true
      console.log("RESULT fail " + message)
    }
  }

  BackgroundPlugin.Background { id: background }
  BackgroundIntro { id: intro; host: test }

  // The empty wallpaper the layer starts with looks the same as one the link
  // read cleared, so the check waits for the read to land. The version moves
  // before a selected wallpaper is displayed, so the check runs once the call
  // that moved it has returned.
  Connections {
    target: background
    function onBackgroundVersionChanged() {
      if (test.linkSettled) return
      test.linkSettled = true
      Qt.callLater(function() {
        test.check(background.displayedBackground === "", "the missing wallpaper leaves the desktop without one")
      })
    }
  }

  Timer {
    interval: 600
    running: true
    onTriggered: {
      test.check(!background.ready && intro.startupPending && intro.cover, "the failed image cannot release startup through readiness")
    }
  }
  Timer {
    interval: 11000
    running: true
    onTriggered: {
      test.check(test.linkSettled, "the missing wallpaper's link is read")
      test.check(!background.ready, "the missing wallpaper never becomes ready")
      test.check(!intro.startupPending && !intro.cover && intro.startupOpacity === 0, "the deadline fades the cover away despite the failed wallpaper")
      if (!test.failed) console.log("RESULT pass")
      Qt.quit()
    }
  }
}
