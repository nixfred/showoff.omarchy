import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

// The real Omarchy wordmark (never typeset from a font — the letters in
// omarchy.ttf are empty stubs). Read the stock SVG, recolour its single
// fill to the theme accent, and glow it.
Item {
  id: root
  property color accent: "#44E8CB"
  property real logoWidth: 900
  property string svg: ""

  width: logoWidth
  height: Math.round(logoWidth * 285 / 1215)

  FileView {
    id: file
    path: (Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy") + "/logo.svg"
    onLoaded: root.svg = text()
    onLoadFailed: path = "/usr/share/omarchy/logo.svg"
  }

  readonly property string source: svg
    ? "data:image/svg+xml;utf8," + encodeURIComponent(svg.replace(/fill="#000(000)?"/g, 'fill="' + accent + '"'))
    : ""

  Image {
    id: img
    anchors.fill: parent
    source: root.source
    sourceSize.width: Math.round(root.logoWidth * 1.5)
    fillMode: Image.PreserveAspectFit
    visible: false
  }
  MultiEffect { anchors.fill: img; source: img; blurEnabled: true; blurMax: 64; blur: 1.0; brightness: 0.2; opacity: 0.9 }
  MultiEffect { anchors.fill: img; source: img; blurEnabled: true; blurMax: 16; blur: 0.5; opacity: 0.8 }
  Image {
    anchors.fill: parent
    source: root.source
    sourceSize.width: Math.round(root.logoWidth * 1.5)
    fillMode: Image.PreserveAspectFit
  }
}
