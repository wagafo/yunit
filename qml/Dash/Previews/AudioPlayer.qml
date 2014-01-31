/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1

PreviewWidget {
    implicitHeight: childrenRect.height

    function stop() {
        audio.stop()
    }

    Audio {
        id: audio
        objectName: "audio"

        property real progress: audio.position / audio.duration
        property Item playingItem

        Component.onDestruction: {
            audio.stop();
        }

        onErrorStringChanged: console.warn("Audio player error:", errorString)
    }

    Column {
        anchors { left: parent.left; right: parent.right }
        visible: trackRepeater.count > 0

        Repeater {
            id: trackRepeater
            objectName: "trackRepeater"

            model: data

            delegate: Item {
                id: trackItem
                objectName: "trackItem" + index

                property bool isPlayingItem: audio.playingItem == trackItem

                anchors { left: parent.left; right: parent.right }
                height: units.gu(5)

                function play() {
                    audio.stop();
                    // Make sure we change the source, even if two items point to the same uri location
                    audio.source = "";
                    audio.source = modelData["source"];
                    audio.playingItem = trackItem;
                    audio.play();
                }

                Row {
                    id: trackRow

                    property int column1Width: units.gu(3)
                    property int column2Width: width - (2 * spacing) - column1Width - column3Width
                    property int column3Width: units.gu(4)

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: units.gu(1)

                    Button {
                        objectName: "playButton"
                        width: trackRow.column1Width
                        height: width
                        iconSource: audio.playbackState == Audio.PlayingState && trackItem.isPlayingItem ? "image://theme/media-playback-pause" : "image://theme/media-playback-start"

                        // Can't be "transparent" or "#00xxxxxx" as the button optimizes away the surrounding shape
                        // FIXME when this is resolved: https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1251685
                        color: "#01000000"

                        onClicked: {
                            if (trackItem.isPlayingItem) {
                                if (audio.playbackState == Audio.PlayingState) {
                                    audio.pause();
                                } else if (audio.playbackState == Audio.PausedState){
                                    audio.play();
                                }
                            } else {
                                trackItem.play();
                            }
                        }
                    }

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.column2Width
                        height: trackSubtitleLabel.visible ? trackTitleLabel.height + trackSubtitleLabel.height : trackTitleLabel.height

                        Label {
                            id: trackTitleLabel
                            objectName: "trackTitleLabel"
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            opacity: 0.9
                            color: "white"
                            fontSize: "small"
                            horizontalAlignment: Text.AlignLeft
                            text: modelData["title"]
                            style: Text.Raised
                            styleColor: "black"
                            elide: Text.ElideRight
                        }

                        Label {
                            id: trackSubtitleLabel
                            objectName: "trackSubtitleLabel"
                            anchors { top: trackTitleLabel.bottom; left: parent.left; right: parent.right }
                            visible: text != ""
                            opacity: 0.9
                            color: "white"
                            fontSize: "small"
                            horizontalAlignment: Text.AlignLeft
                            text: modelData["subtitle"] !== undefined ? modelData["subtitle"] : ""
                            style: Text.Raised
                            styleColor: "black"
                            elide: Text.ElideRight
                        }

                        UbuntuShape {
                            id: progressBarFill
                            objectName: "progressBarFill"

                            property int maxWidth: progressBarImage.width - units.dp(4)

                            anchors {
                                left: progressBarImage.left
                                right: progressBarImage.right
                                verticalCenter: progressBarImage.verticalCenter
                                margins: units.dp(2)
                                rightMargin: maxWidth - (maxWidth * audio.progress) + units.dp(2)
                            }
                            height: units.dp(2)
                            visible: progressBarImage.visible
                            color: UbuntuColors.orange
                        }

                        Image {
                            id: progressBarImage
                            anchors { left: parent.left; top: parent.bottom; right: parent.right }
                            height: units.dp(6)
                            visible: audio.playbackState != Audio.StoppedState && trackItem.isPlayingItem && modelData["length"] > 0
                            source: "graphics/music_progress_bg.png"
                        }
                    }

                    Label {
                        id: timeLabel
                        objectName: "timeLabel"
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.column3Width
                        opacity: 0.9
                        color: "white"
                        fontSize: "small"
                        horizontalAlignment: Text.AlignRight
                        text: lengthToString(modelData["length"])
                        style: Text.Raised
                        styleColor: "black"

                        function lengthToString(s) {
                            if (s <= 0 || s === undefined) return ""

                            var sec = "" + s % 60
                            if (sec.length == 1) sec = "0" + sec
                            var hour = Math.floor(s / 3600)
                            if (hour < 1) {
                                return Math.floor(s / 60) + ":" + sec
                            } else {
                                var min = "" + Math.floor(s / 60) % 60
                                if (min.length == 1) min = "0" + min
                                return hour + ":" + min + ":" + sec
                            }
                        }
                    }
                }
            }
        }
    }
}
