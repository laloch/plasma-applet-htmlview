import QtQuick
import QtQuick.Controls as QQC2
import QtWebEngine
import QtQuick.Layouts 1.1
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0
import org.kde.draganddrop 2.0 as DragDrop
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    //Plasmoid.backgroundHints: "NoBackground"
    // Plasmoid.backgroundHints: "ShadowBackground"
    Plasmoid.backgroundHints: Plasmoid.configuration.background

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1
        Layout.minimumHeight: Kirigami.Units.gridUnit * 1
        Layout.preferredWidth: Kirigami.Units.gridUnit * 27
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        property bool isSuspended: false

        Component.onCompleted: {
            if (Plasmoid.configuration.suspended) {
                delayedSuspendTimer.start();
            }
        }

        function setUrl() {
            if (!(plasmoid.configuration.islocal ? plasmoid.configuration.file : plasmoid.configuration.url)) {
                webView.url = Qt.resolvedUrl("placeholder.html");
            } else {
                webView.url = plasmoid.configuration.islocal ? "file:" + plasmoid.configuration.file : plasmoid.configuration.url;
            }

            if (refreshIntervalTimer.running) {
                refreshIntervalTimer.restart();
            }
        }

        Connections {
            target: plasmoid.configuration
            function onUrlChanged() {
                setUrl();
            }
            function onFileChanged() {
                setUrl();
            }
            function onIslocalChanged() {
                setUrl();
            }
            function onShowScrollBarsChanged() {
                webView.settings.showScrollBars = Plasmoid.configuration.showScrollBars;
                webView.anchors.bottomMargin = 1;
                layoutFixTimer.restart();
            }
            function onAllowInsecureChanged() {
                 webView.settings.allowRunningInsecureContent = Plasmoid.configuration.allowInsecure;
                 webView.reload();
            }
            function onAllowRemoteAccessChanged() {
                 webView.settings.localContentCanAccessRemoteUrls = Plasmoid.configuration.allowRemoteAccess;
                 webView.reload();
            }
            function onIgnoreCertificateErrorsChanged() {
                 webView.reload();
            }
            function onForceTransparentChanged() {
                 webView.reload();
            }
        }

        Timer {
            id: layoutFixTimer
            interval: 10
            onTriggered: webView.anchors.bottomMargin = 0
        }

        Timer {
            id: refreshIntervalTimer
            repeat: true
            interval: Plasmoid.configuration.interval * 1000
            running: Plasmoid.configuration.interval > 0 && !isSuspended
            onTriggered: webView.reload()
        }

        Timer {
            id: delayedSuspendTimer
            interval: 30000
            onTriggered: isSuspended = true
        }

        WebEngineView {
            id: webView
            property string lastErrorString: ""
            property bool isError: false

            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                    isError = true;
                    lastErrorString = loadRequest.errorString;
                } else if (loadRequest.status === WebEngineView.LoadStartedStatus) {
                    isError = false;
                } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    if (Plasmoid.configuration.forceTransparent) {
                        webView.runJavaScript("(function() { var style = document.createElement('style'); style.innerText = 'html, body { background: transparent !important; }'; document.head.appendChild(style); function clearBg(el) { if (el.nodeType !== 1) return; var width = el.clientWidth; var height = el.clientHeight; if (width > window.innerWidth * 0.9 && height > window.innerHeight * 0.9) { var comp = window.getComputedStyle(el); if (comp.backgroundColor !== 'rgba(0, 0, 0, 0)' && comp.backgroundColor !== 'transparent') { el.style.setProperty('background-color', 'transparent', 'important'); el.style.setProperty('background-image', 'none', 'important'); } } Array.from(el.children).forEach(clearBg); } clearBg(document.body); var observer = new MutationObserver(function(mutations) { mutations.forEach(function(m) { if (m.type === 'childList') { m.addedNodes.forEach(clearBg); } else if (m.type === 'attributes') { clearBg(m.target); } }); }); observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['style', 'class'] }); })();");
                    }
                }
            }
            
            onCertificateError: function(error) {
                if (Plasmoid.configuration.ignoreCertificateErrors) {
                    error.acceptCertificate();
                    return true;
                }
            }

            anchors.fill: parent
            //opacity: 0.4
            opacity: isSuspended ? 0.5 : 1.0
            lifecycleState: isSuspended ? WebEngineView.Frozen : WebEngineView.Active
            zoomFactor: Plasmoid.configuration.scale / 100
            layer.enabled: true
            layer.smooth: true
            layer.format: ShaderEffectSource.RGBA

            settings.allowRunningInsecureContent: Plasmoid.configuration.allowInsecure
            settings.javascriptEnabled: !isSuspended
            settings.localContentCanAccessFileUrls: true
            settings.localContentCanAccessRemoteUrls: Plasmoid.configuration.allowRemoteAccess
            settings.navigateOnDropEnabled: false
            settings.screenCaptureEnabled: true
            settings.showScrollBars: Plasmoid.configuration.showScrollBars
            profile.httpUserAgent: components.system.getUserAgent()
            profile.storageName: "plasmoid-html-view"
            backgroundColor: "transparent"

            url: plasmoid.configuration.url

            // property QQC2.Menu contextMenu: QQC2.Menu {
            QQC2.Menu {
                id: contextMenu
                Repeater {
                    model: [
                        WebEngineView.Back,
                        WebEngineView.Forward,
                        WebEngineView.Reload,
                        // WebEngineView.SavePage,
                        WebEngineView.Copy,
                        WebEngineView.Paste,
                        WebEngineView.Cut,
                        // WebEngineView.ChangeTextDirectionLTR,
                        // WebEngineView.ChangeTextDirectionRTL,
                    ]
                    QQC2.MenuItem {
                        text: webView.action(modelData).text
                        enabled: webView.action(modelData).enabled
                        onClicked: webView.action(modelData).trigger()
                        icon.name: webView.action(modelData).iconName
                        display: QQC2.MenuItem.TextBesideIcon
                    }
                }
            }
            onContextMenuRequested: {
                request.accepted = true;
                contextMenu.popup();
            }

            onNewWindowRequested: function(request) {
                if (request.userInitiated) {
                    Qt.openUrlExternally(request.requestedUrl);
                }
            }

            Component.onCompleted: {
                const plasmaInterface = {
                    name: "PlasmoidInterface",
                    injectionPoint: WebEngineScript.DocumentCreation,
                    worldId: WebEngineScript.MainWorld,
                    sourceCode: "
                        document.__plasmoid = {
                            addStyleSheet: function(styleSheet) {
                                const ss = new CSSStyleSheet();
                                ss.replaceSync(styleSheet);
                                document.adoptedStyleSheets.push(ss);
                            },
                        }",
                }
                userScripts.collection = [ plasmaInterface, ];

                setUrl();
            }

            function navigate(url) {
                var urlStr = url.toString();
                if (urlStr.startsWith("file://")) {
                     plasmoid.configuration.islocal = true;
                     plasmoid.configuration.file = urlStr.replace(/^file:\/\//, "");
                } else {
                     plasmoid.configuration.islocal = false;
                     plasmoid.configuration.url = urlStr;
                }
            }
       }

     DragDrop.DropArea {
        id: dropArea
        anchors.fill: parent

        onDrop: {
            var md = event.mimeData;
            if (md.hasUrls) {
                var urls = md.urls;
                for (var i = 0, j = urls.length; i < j; ++i) {
                    var url = urls[i];
                    webView.navigate(url);
                    break;
                }
            }
            event.accept(Qt.CopyAction);
        }
    }

    QQC2.BusyIndicator {
        anchors.centerIn: parent
        running: webView.loading
        visible: running
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: errorLabel.height + Kirigami.Units.gridUnit
        color: "red"
        radius: Kirigami.Units.smallSpacing
        visible: webView.isError

        QQC2.Label {
            id: errorLabel
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit
            wrapMode: Text.Wrap
            text: i18n("Error loading page: %1", webView.lastErrorString)
            color: "white"
        }
    }

    MouseArea {
        id: hoverTrigger
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Kirigami.Units.gridUnit * 3
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        Rectangle {
            anchors.centerIn: parent
            width: navRow.width + Kirigami.Units.largeSpacing
            height: navRow.height + Kirigami.Units.smallSpacing
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.75)
            opacity: hoverTrigger.containsMouse || navRowHover.containsMouse ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            MouseArea {
                 anchors.fill: parent
                 hoverEnabled: true
                 id: navRowHover
                 onPressed: mouse.accepted = true
            }

            RowLayout {
                id: navRow
                anchors.centerIn: parent
                spacing: 0

                QQC2.ToolButton {
                    icon.name: isSuspended ? "media-playback-start" : "media-playback-pause"
                    text: isSuspended ? i18nc("@action:button", "Resume") : i18nc("@action:button", "Suspend")
                    display: QQC2.AbstractButton.IconOnly
                    onClicked: {
                        isSuspended = !isSuspended;
                        Plasmoid.configuration.suspended = isSuspended;
                        delayedSuspendTimer.stop();
                    }
                }

                QQC2.ToolButton {
                    icon.name: "go-previous"
                    text: i18nc("@action:button", "Back")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: webView.canGoBack
                    onClicked: webView.goBack()
                }
                QQC2.ToolButton {
                    icon.name: "go-next"
                    text: i18nc("@action:button", "Forward")
                    display: QQC2.AbstractButton.IconOnly
                    enabled: webView.canGoForward
                    onClicked: webView.goForward()
                }
                QQC2.ToolButton {
                    icon.name: "view-refresh"
                    text: i18nc("@action:button", "Reload")
                    display: QQC2.AbstractButton.IconOnly
                    onClicked: webView.reload()
                }
            }
        }
    }
  }
}

