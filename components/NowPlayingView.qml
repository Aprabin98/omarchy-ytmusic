import QtQuick
import qs.Commons
import qs.Ui
import "../YtmModel.js" as Model

// Cover, track info, seek bar, transport and volume for the current track.
Item {
  id: root

  property var service: null
  property QtObject bar: null
  property bool panelOpen: false

  readonly property color foreground: "#e2e8f0"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var track: service ? service.currentTrack : null
  readonly property bool hasMedia: service ? service.hasMedia : false
  readonly property real duration: service ? service.duration : 0
  readonly property real position: service ? service.position : 0
  readonly property bool liked: !!service && service.currentLike === "LIKE"
  readonly property bool accountActions: !!service && service.signedIn && hasMedia

  readonly property bool albumLinked: !!track && !!track.album && !!track.album.id

  signal addToPlaylistRequested()
  // An artist ({ name, id }) or the track's album was clicked.
  signal artistRequested(var artist)
  signal albumRequested(var track)

  implicitHeight: content.implicitHeight + Style.space(28)

  Rectangle {
    anchors.fill: parent
    radius: Style.space(14)
    color: "#1a1c23"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.06)
  }

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(10)

    Row {
      width: parent.width
      height: Style.space(20)
      spacing: Style.space(6)

      Rectangle {
        width: Style.space(6)
        height: width
        radius: width / 2
        color: root.service && root.service.playing ? "#8b5cf6" : "#697080"
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: statusLabel
        text: root.service && root.service.playing ? "NOW PLAYING" : "READY WHEN YOU ARE"
        color: "#8b92a5"
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1
      }

      Item {
        width: parent.width - statusLabel.width - liveLabel.width - visualizer.width - parent.spacing * 3
        height: 1
      }

      Text {
        id: liveLabel
        anchors.verticalCenter: parent.verticalCenter
        text: root.service && root.service.playing ? "LIVE" : "YTM"
        color: "#a78bfa"
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Item {
        id: visualizer
        readonly property bool active: !!root.service && root.service.playing && root.panelOpen
        property var levels: [5, 12, 8, 16, 7, 13, 10, 18, 8, 14, 6, 11]
        width: active ? Style.space(48) : 0
        height: Style.space(20)
        visible: active

        Timer {
          interval: 150
          repeat: true
          running: visualizer.active
          onTriggered: {
            var next = []
            for (var i = 0; i < 12; i++) next.push(3 + Math.random() * Style.space(16))
            visualizer.levels = next
          }
        }

        Row {
          anchors.fill: parent
          spacing: Style.space(2)

          Repeater {
            model: 12

            Rectangle {
              required property int index
              width: Style.space(2)
              height: Math.max(Style.space(3), visualizer.levels[index])
              anchors.verticalCenter: parent.verticalCenter
              radius: width
              color: index % 3 === 0 ? "#a78bfa" : "#8b5cf6"

              Behavior on height {
                NumberAnimation {
                  duration: Style.duration(140)
                  easing.type: Easing.OutCubic
                }
              }
            }
          }
        }
      }
    }

  Row {
    width: parent.width
    spacing: Style.space(14)

    CoverArt {
      id: cover
      size: Style.space(80)
      store: root.service ? root.service.store : null
      source: root.track ? (root.track.thumbLarge || root.track.thumb || "") : ""
      foreground: root.foreground
      fontFamily: root.fontFamily

      HoverHandler {
        enabled: root.albumLinked
        cursorShape: Qt.PointingHandCursor
      }

      TapHandler {
        enabled: root.albumLinked
        onTapped: root.albumRequested(root.track)
      }
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - cover.width - parent.spacing
      spacing: Style.space(3)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: root.track ? root.track.title : "Nothing playing"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      // Artists; the ones with a channel open their page.
      Flow {
        id: artistFlow
        width: parent.width
        visible: !!root.track && root.track.artistText !== ""

        Repeater {
          model: root.track && root.track.artists ? root.track.artists : []

          Row {
            id: artistItem
            required property var modelData
            required property int index
            readonly property bool linked: !!modelData.id

            Text {
              width: Math.min(implicitWidth, artistFlow.width - separator.implicitWidth)
              textFormat: Text.PlainText
              text: artistItem.modelData.name
              color: Qt.darker(root.foreground, 1.3)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.underline: artistItem.linked && artistHover.hovered
              elide: Text.ElideRight

              HoverHandler {
                id: artistHover
                enabled: artistItem.linked
                cursorShape: Qt.PointingHandCursor
              }

              TapHandler {
                enabled: artistItem.linked
                onTapped: root.artistRequested(artistItem.modelData)
              }
            }

            Text {
              id: separator
              textFormat: Text.PlainText
              text: artistItem.index < root.track.artists.length - 1 ? ", " : ""
              color: Qt.darker(root.foreground, 1.3)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }
      }

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: root.service && root.service.canResume ? "Pick up where you left off:"
          : "Search (2) or open Home (4) to pick something."
        visible: !root.track
        color: Qt.darker(root.foreground, 1.3)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
      }

      Button {
        visible: !root.track && !!root.service && root.service.canResume
        iconText: "󰐊"
        text: root.service && root.service.resumeTitle !== "" ? "Resume " + root.service.resumeTitle : "Resume"
        tooltipText: "Restore the queue and continue the song where it stopped"
        foreground: root.foreground
        fontSize: Style.font.caption
        width: Math.min(implicitWidth, parent.width)
        onClicked: root.service.resume()
      }

      Text {
        width: Math.min(implicitWidth, parent.width)
        textFormat: Text.PlainText
        text: root.track && root.track.album ? root.track.album.name : ""
        visible: text !== ""
        color: Qt.darker(root.foreground, 1.6)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.underline: root.albumLinked && albumHover.hovered
        elide: Text.ElideRight

        HoverHandler {
          id: albumHover
          enabled: root.albumLinked
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          enabled: root.albumLinked
          onTapped: root.albumRequested(root.track)
        }
      }

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: !root.service ? ""
          : root.service.pendingTitle !== "" ? "Loading “" + root.service.pendingTitle + "”…"
          : root.service.buffering ? "Loading…"
          : root.service.lastError
        visible: text !== ""
        color: root.service && (root.service.buffering || root.service.pendingTitle !== "") ? Qt.darker(root.foreground, 1.6) : Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }
    }
  }

  Column {
    width: parent.width
    spacing: Style.space(2)

    PanelSlider {
      id: seekSlider
      width: parent.width
      height: Style.space(20)
      bar: root.bar
      minimum: 0
      maximum: Math.max(1, root.duration)
      step: 1
      value: root.position
      trackColor: "#35323f"
      fillColor: "#8b5cf6"
      knobColor: "#c4b5fd"
      enabled: root.hasMedia && root.duration > 0
      opacity: enabled ? 1 : 0.4
      // Seek once, on release; while dragging only the time preview moves.
      onReleased: function(v) { if (root.service) root.service.seek(v) }
    }

    Item {
      width: parent.width
      height: elapsed.implicitHeight

      Text {
        id: elapsed
        textFormat: Text.PlainText
        text: root.hasMedia ? Model.formatDuration(seekSlider.dragging ? seekSlider.liveValue : root.position) : ""
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.right: parent.right
        textFormat: Text.PlainText
        text: root.hasMedia && root.duration > 0 ? Model.formatDuration(root.duration) : ""
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  Item {
    width: parent.width
    height: transport.height

    Button {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      visible: root.accountActions
      iconText: root.liked ? "󰋑" : "󰋕"
      tooltipText: root.liked ? "Remove from Liked Music (L)" : "Like (L)"
      foreground: root.liked ? "#a78bfa" : root.foreground
      accent: "#8b5cf6"
      onClicked: root.service.toggleLike(root.track)
    }

    Button {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: root.accountActions
      iconText: "󰐒"
      tooltipText: "Add to playlist (p)"
      foreground: root.foreground
      accent: "#8b5cf6"
      onClicked: root.addToPlaylistRequested()
    }

    Row {
      id: transport
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(8)

      Button {
        readonly property bool shuffleOn: !!root.service && root.service.shuffle
        anchors.verticalCenter: parent.verticalCenter
        iconText: shuffleOn ? "󰒝" : "󰒞"
        tooltipText: shuffleOn ? "Shuffle is on (s)" : "Shuffle (s)"
        foreground: shuffleOn ? "#a78bfa" : "#8b92a5"
        accent: "#8b5cf6"
        onClicked: root.service.toggleShuffle()
      }

      Button {
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰒮"
        tooltipText: "Previous"
        foreground: root.foreground
        accent: "#8b5cf6"
        enabled: root.hasMedia
        opacity: enabled ? 1 : 0.4
        onClicked: root.service.previous()
      }

      Button {
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(38)
        height: width
        radius: width / 2
        horizontalPadding: 0
        verticalPadding: 0
        iconText: root.service && root.service.playing ? "󰏤" : "󰐊"
        tooltipText: root.service && root.service.playing ? "Pause" : "Play"
        foreground: "#ffffff"
        accent: "#8b5cf6"
        selected: true
        iconSize: Style.font.icon
        enabled: !!root.service && (root.hasMedia || root.service.playlistCount > 0)
        opacity: enabled ? 1 : 0.4
        onClicked: root.service.playPause()
      }

      Button {
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰒭"
        tooltipText: "Next"
        foreground: root.foreground
        accent: "#8b5cf6"
        enabled: root.hasMedia
        opacity: enabled ? 1 : 0.4
        onClicked: root.service.next()
      }

      Button {
        readonly property string loopMode: root.service ? root.service.repeatMode : "off"
        anchors.verticalCenter: parent.verticalCenter
        iconText: loopMode === "one" ? "󰑘" : loopMode === "all" ? "󰑖" : "󰑗"
        tooltipText: loopMode === "one" ? "Repeating this song (r)" : loopMode === "all" ? "Repeating the queue (r)" : "Repeat (r)"
        foreground: loopMode !== "off" ? "#a78bfa" : "#8b92a5"
        accent: "#8b5cf6"
        onClicked: root.service.cycleRepeat()
      }
    }
  }

  Row {
    width: parent.width
    spacing: Style.space(8)

    Text {
      id: volumeIcon
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root.service && root.service.volume === 0 ? "󰖁" : "󰕾"
      color: Qt.darker(root.foreground, 1.3)
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon
    }

    PanelSlider {
      id: volumeSlider
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - volumeIcon.width - volumeText.width - parent.spacing * 2
      height: Style.space(20)
      bar: root.bar
      minimum: 0
      maximum: 100
      step: 5
      integer: true
      value: root.service ? Math.min(100, root.service.volume) : 100
      trackColor: "#35323f"
      fillColor: "#8b5cf6"
      knobColor: "#c4b5fd"
      onMoved: function(v) { if (root.service) root.service.setVolume(v) }
    }

    Text {
      id: volumeText
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(34)
      horizontalAlignment: Text.AlignRight
      textFormat: Text.PlainText
      text: Math.round(volumeSlider.dragging ? volumeSlider.liveValue : volumeSlider.value) + "%"
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
  }
}
