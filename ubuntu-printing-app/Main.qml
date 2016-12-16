/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of ubuntu-printing-app.
 *
 * ubuntu-printing-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-printing-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Andrew Hayzen <andrew.hayzen@canonical.com>
 */
import QtQuick 2.4
import QtQuick.Layouts 1.1

import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.1
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
    applicationName: "ubuntu-printing-app"

    width: units.gu(45)
    height: units.gu(70)

    Connections {  // split into ContentHubHelper which has onDocumentUrlChanged, exportDocument(url)
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

        // TODO: status ? similar style of onError to Document

        onExportRequest: pageStack.push(Qt.resolvedUrl("components/ContentPeerPickerDialog.qml"), {"url": filepath})
    }

    Component {  // cannot split due to issue
        id: dialogComponent
        Dialog {
            id: dialog

            Button {
                text: i18n.tr("OK")

                onClicked: PopupUtils.close(dialog)
            }
        }
    }

    Document {
        id: document

        onError: {
            var errorString;

            switch (errorType) {
            case Document.ErrorDocumentInvalid:
                errorString = i18n.tr("Document is invalid");
                break;
            case Document.ErrorNotFound:
                errorString = i18n.tr("Document not found");
                break;
            case Document.ErrorNotPdf:
                errorString = i18n.tr("Not a PDF document");
                break;
            default:
                errorString = i18n.tr("An unknown error occurred");
                break;
            }

            PopupUtils.open(
                dialogComponent,  // Qt.resolvedUrl("components/AlertDialog.qml"),  // FIXME: doesn't work when document is set onCompleted of MainView
                undefined,
                {
                    "text": errorString,
                    "title": i18n.tr("Error"),
                }
            )
        }
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

    PageStack {
        id: pageStack
        anchors {
            fill: parent
        }
    }

    Page {
        id: page
        anchors {
            fill: parent
        }
        width: mainView.width
        visible: false

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
            id: scrollView
            anchors {
                bottom: printRow.top
                left: parent.left
                right: parent.right
                top: page.header.bottom
            }

            ColumnLayout {
                id: columnLayout
                spacing: units.gu(1)
                width: mainView.width

                PreviewRow {
                    document: document
                    printer: printer
                    view: scrollView
                }

                SelectorRow {
                    model: PrinterInfo.availablePrinterNames
                    selectedIndex: model.indexOf(printer.name)
                    text: i18n.tr("Printer")

                    onSelectedValueChanged: {
                        printer.pdfMode = selectedIndex === model.length - 1
                        printer.name = selectedValue
                    }
                }

                TextFieldRow {
                    enabled: !printer.pdfMode
                    inputMethodHints: Qt.ImhDigitsOnly
                    placeholderText: printer.copies
                    text: i18n.tr("Copies")
                    validator: IntValidator {
                        bottom: 1
                        top: 999
                    }

                    onValueChanged: {
                        if (acceptableInput) {
                            printer.copies = Number(text);
                        }
                    }
                }

                CheckBoxRow {
                    checked: printer.duplex
                    checkboxText: i18n.tr("Two Sided")
                    enabled: document.count > 1 && printer.duplexSupported && !printer.pdfMode

                    onCheckedChanged: printer.duplex = checked
                }

                SelectorRow {
                    id: pageRangeSelector
                    enabled: !printer.pdfMode
                    model: [i18n.tr("All"), i18n.tr("Range")]
                    modelValue: [Printer.AllPages, Printer.PageRange]
                    selectedIndex: 0
                    text: i18n.tr("Pages")

                    onSelectedValueChanged: printer.printRangeMode = selectedValue
                }

                TextFieldRow {
                    enabled: !printer.pdfMode
                    validator: RegExpValidator {
//                        regExp: ""  // TODO: validate to only 0-9||9-0||0 ,
                    }
                    visible: pageRangeSelector.selectedValue === Printer.PageRange

                    onValueChanged: printer.printRange = value
                }

                LabelRow {
                    enabled: !printer.pdfMode
                    secondaryText: i18n.tr("eg 1-3,8")
                    visible: pageRangeSelector.selectedValue === Printer.PageRange
                }

                SelectorRow {
                    enabled: !printer.pdfMode
                    model: [i18n.tr("Black & White"), i18n.tr("Color")]
                    modelValue: [Printer.GrayScale, Printer.Color]
                    selectedIndex: modelValue.indexOf(printer.colorMode)
                    text: i18n.tr("Color")

                    onSelectedValueChanged: printer.colorMode = selectedValue
                }

                SelectorRow {
                    enabled: !printer.pdfMode  // !Printer.pdfMode
                    model: [i18n.tr("Draft"), i18n.tr("Normal"), i18n.tr("Best"), i18n.tr("Photo")]
                    modelValue: [Printer.Draft, Printer.Normal, Printer.Best, Printer.Photo]
                    selectedIndex: modelValue.indexOf(printer.quality)
                    text: i18n.tr("Quality")

                    onSelectedValueChanged: printer.quality = selectedValue
                }

                Item {
                    height: units.gu(2)
                    width: parent.width
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

    Arguments {
        id: args
        Argument {
            name: "url"
            help: i18n.tr("Url of PDF to print")
            required: false
            valueNames: ["url"]
        }
    }

    Component.onCompleted: {
        pageStack.push(page)

        console.debug("Printers:", PrinterInfo.availablePrinterNames);

        if (args.values.url) {
            document.url = Qt.resolvedUrl(args.values.url);
        }
    }
}


