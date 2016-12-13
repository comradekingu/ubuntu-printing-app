import QtQuick 2.4
import QtQuick.Layouts 1.1

import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Content 0.1
import Ubuntu_Printing_App 1.0

import "components"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    id: mainView
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "ubuntu-printing-app.ahayzen"

    width: units.gu(40)
    height: units.gu(60)

    Connections {
        target: ContentHub

        onImportRequested: {
            console.debug("State:", transfer.state)
            console.debug("Transfer:", transfer)
            console.debug("Items:", transfer.items)

            for (var i=0; i < transfer.items.length; i++) {
                var item = transfer.items[i];

                document.url = item.url;
                console.debug("Item URL:", item.url);
            }
        }
    }

    Printer {
        id: printer
        name: PrinterInfo.defaultPrinterName

        // TODO: status ?

        onExportRequest: console.debug("Export requested!", filepath)
    }

    Document {
        id: document
    }

    /*
    PrinterInfo.availablePrinterNames

    PrinterInfo.defaultName

    Printer {
      error: false
      errorString: ""
      name: PrinterInfo.defaultName

      colorMode: ColorModes.greyscale
      copies: 2

      print(Document document)  // async

      status: {Null,Rendering,SentToPrinter,Error}
      progress: 0.6  // progress of print
    }

    Document {
        error: false
        errorString: ""
        url: "/tmp/my.pdf"
    }

    */

    Page {
        id: page
        anchors {
            fill: parent
        }
        width: mainView.width

        header: PageHeader {
            id: pageHeader
            leadingActionBar {
                actions: [
                    Action {
                        iconName: "back"

                        onTriggered: Qt.quit()
                    }
                ]
            }

            title: printer.pdfMode ? i18n.tr("Page Setup") : i18n.tr("Printer Options")
        }

        ScrollView {
            anchors {
                bottom: printRow.top
                left: parent.left
                right: parent.right
                top: page.header.bottom
            }

            Item {
                height: columnLayout.height + units.gu(2)
                width: mainView.width - units.gu(2)
                x: units.gu(1)
                y: x

                ColumnLayout {
                    id: columnLayout
                    spacing: units.gu(1)
                    width: parent.width

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        color: "#EEE"
                        implicitHeight: units.gu(25)

                        RowLayout {
                            anchors.fill: parent

                            Button {
                                enabled: previewImage.pageNumber > 0
                                Layout.preferredWidth: units.gu(4)
                                color: "#000"
                                text: "<"

                                onClicked: previewImage.pageNumber--
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: units.gu(25)

                                Image {
                                    id: previewImage
                                    anchors {
                                        fill: parent
                                    }

                                    asynchronous: true
                                    source: document.url.toString() !== "" ? "image://poppler/" + pageNumber + "/" + printer.colorMode + "/" + document.url : ""
                                    sourceSize {
                                        height: units.gu(25)
                                        width: previewImage.width
                                    }

                                    property int pageNumber: 0
                                }

                                ActivityIndicator {
                                    anchors {
                                        centerIn: parent
                                    }
                                    running: previewImage.status == Image.Loading
                                }
                            }

                            Button {
                                color: "#000"
                                enabled: previewImage.pageNumber < document.count - 1
                                Layout.preferredWidth: units.gu(4)
                                text: ">"

                                onClicked: previewImage.pageNumber++
                            }
                        }
                    }


                    SelectorRow {
                        model: PrinterInfo.availablePrinterNames
                        selectedIndex: model.indexOf(printer.name)
                        text: i18n.tr("Printer")

                        onSelectedIndexChanged: {
                            printer.pdfMode = selectedIndex === model.length - 1
                            printer.name = model[selectedIndex]
                        }
                    }

                    RowLayout {
                        Label {
                            Layout.preferredWidth: units.gu(10)
                            text: i18n.tr("Copies")
                        }

                        TextField {
                            enabled: !printer.pdfMode
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.fillWidth: true
                            Layout.preferredWidth: units.gu(5)
                            text: printer.copies
                            validator: IntValidator {
                                bottom: 1
                                top: 999
                            }

                            // TODO: acceptableInput is False show hint

                            onTextChanged: {
                                if (acceptableInput) {
                                    printer.copies = Number(text);
                                }
                            }
                        }
                    }

                    RowLayout {
                        Item {
                            Layout.preferredWidth: units.gu(10)
                        }

                        MouseArea {
                            enabled: checkbox.enabled
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(3)
                            Layout.preferredWidth: units.gu(10)

                            onClicked: checkbox.checked = !checkbox.checked

                            Row {
                                anchors {
                                    fill: parent
                                }
                                spacing: units.gu(1)

                                CheckBox {
                                    id: checkbox
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                    }
                                    checked: printer.duplex
                                    enabled: document.count > 1 && printer.duplexSupported

                                    onCheckedChanged: printer.duplex = checked
                                }

                                Label {
                                    enabled: document.count > 1
                                    height: parent.height
                                    text: i18n.tr("Two-Sided")
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                        }
                    }

                    SelectorRow {
                        enabled: !printer.pdfMode
                        model: [i18n.tr("Black & White"), i18n.tr("Color")]
                        selectedIndex: modelValue.indexOf(printer.colorMode)
                        text: i18n.tr("Color")

                        property var modelValue: [Printer.GrayScale, Printer.Color]

                        onSelectedIndexChanged: printer.colorMode = modelValue[selectedIndex]
                    }

                    SelectorRow {
                        enabled: !printer.pdfMode
                        model: [i18n.tr("Draft"), i18n.tr("Normal"), i18n.tr("Best"), i18n.tr("Photo")]
                        selectedIndex: modelValue.indexOf(printer.quality)
                        text: i18n.tr("Quality")

                        property var modelValue: [Printer.Draft, Printer.Normal, Printer.Best, Printer.Photo]

                        onSelectedIndexChanged: printer.quality = modelValue[selectedIndex]
                    }
                }
            }
        }

        PrintRow {
            id: printRow
            anchors {
                bottom: parent.bottom
                left: parent.left
                leftMargin: units.gu(1)
                right: parent.right
                rightMargin: units.gu(1)
            }
            pdfMode: printer.pdfMode
            sheets: document.count

            onCancel: Qt.quit()
            onConfirm: printer.print(document);  // TODO: check document is valid raise error if not?
        }
    }

    Component.onCompleted: {
//        document.url = Qt.resolvedUrl("/home/andy/Workspace/Work/Canonical/dump/2016-11-17T12:00:08");
        document.url = Qt.resolvedUrl("/home/andrew/Downloads/UbuntuPhone.pdf");
//        document.url = Qt.resolvedUrl("/home/andrew/Documents/test.pdf");
        console.debug("Printers:", PrinterInfo.availablePrinterNames);
    }
}

