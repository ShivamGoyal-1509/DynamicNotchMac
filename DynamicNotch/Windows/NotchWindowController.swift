import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {

    private var panel: NSPanel?

    private let panelWidth: CGFloat = 420
    private let panelHeight: CGFloat = 150

    init() {
        createPanel()
    }

    func show() {
        guard let panel else {
            return
        }

        updatePosition()

        panel.orderFrontRegardless()
    }

    private func createPanel() {

        guard let screen = targetScreen else {
            print("Could not find display")
            return
        }

        let frame =
            panelFrame(
                for: screen
            )

        let panel =
            NSPanel(
                contentRect: frame,
                styleMask: [
                    .borderless,
                    .nonactivatingPanel
                ],
                backing: .buffered,
                defer: false
            )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false

        panel.level = .statusBar

        panel.isMovable = false
        panel.isMovableByWindowBackground = false

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let rootView =
            NotchIslandView()

        let hostingView =
            NSHostingView(
                rootView: rootView
            )

        hostingView.frame =
            NSRect(
                x: 0,
                y: 0,
                width: panelWidth,
                height: panelHeight
            )

        panel.contentView =
            hostingView

        self.panel =
            panel

        observeScreenChanges()
    }

    private var targetScreen: NSScreen? {

        if let notchedScreen =
            NSScreen.screens.first(
                where: {
                    $0.safeAreaInsets.top > 0
                }
            ) {
            return notchedScreen
        }

        return NSScreen.main
    }

    private func panelFrame(
        for screen: NSScreen
    ) -> NSRect {

        let x =
            screen.frame.midX
            - panelWidth / 2

        let y =
            screen.frame.maxY
            - panelHeight

        return NSRect(
            x: x,
            y: y,
            width: panelWidth,
            height: panelHeight
        )
    }

    private func updatePosition() {

        guard
            let panel,
            let screen = targetScreen
        else {
            return
        }

        panel.setFrame(
            panelFrame(
                for: screen
            ),
            display: true
        )
    }

    private func observeScreenChanges() {

        NotificationCenter.default.addObserver(
            forName:
                NSApplication
                .didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in

            Task { @MainActor in
                self?.updatePosition()
            }
        }
    }
}
