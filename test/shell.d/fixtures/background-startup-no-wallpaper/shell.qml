import QtQuick
import Quickshell
import "services"
import "background" as BackgroundPlugin

ShellRoot {
  id: test
  property var services: ({ "omarchy.background": background })
  property var bar: ({})
  property bool failed: false
  function firstPartyServiceFor(id) { return services[id] || null }
  function check(ok, message) {
    if (!ok) {
      failed = true
      console.log("RESULT fail " + message)
    }
  }

  BackgroundPlugin.Background { id: background }
  BackgroundIntro { id: intro; host: test }

  // Readiness can lift the cover only once the layer is ready, so a cover
  // lifted while it is not was lifted by the startup deadline instead.
  Connections {
    target: intro
    function onCoverChanged() {
      if (intro.cover) return
      test.check(background.ready && background.displayedBackground === "", "the desktop is released once the layer settles on no wallpaper")
    }
    function onStartupPendingChanged() {
      if (intro.startupPending) return
      test.check(!intro.cover && intro.startupOpacity === 0, "a desktop without a wallpaper fades in before the startup deadline")
      if (!test.failed) console.log("RESULT pass")
      Qt.quit()
    }
  }

  // Past BackgroundIntro's 10 s startup deadline and its fade, so a desktop
  // that is never revealed fails here rather than at the runner's timeout.
  Timer {
    interval: 12000
    running: true
    onTriggered: {
      test.check(false, "a desktop without a wallpaper fades in before the startup deadline")
      Qt.quit()
    }
  }
}
