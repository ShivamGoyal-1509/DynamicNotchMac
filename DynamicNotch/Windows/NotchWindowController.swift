import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {

    // ========================================================
    // WINDOW
    // ========================================================

    private var panel:
        NSPanel?


    // ========================================================
    // PANEL SIZE
    // ========================================================
    //
    // This panel is deliberately larger than the actual island.
    //
    // SwiftUI positions the activity itself at the top center.
    //

    private let panelWidth:
        CGFloat = 440

    private let panelHeight:
        CGFloat = 190


    // ========================================================
    // INIT
    // ========================================================

    init() {

        createPanel()
    }


    // ========================================================
    // SHOW
    // ========================================================

    func show() {

        guard let panel else {

            return
        }


        updatePosition()


        panel.orderFrontRegardless()
    }


    // ========================================================
    // CREATE PANEL
    // ========================================================

    private func createPanel() {

        guard let screen =
            targetScreen
        else {

            print(
                "DynamicNotch: No target display found."
            )

            return
        }


        // ====================================================
        // PANEL
        // ====================================================

        let panel =
            NSPanel(
                contentRect:
                    panelFrame(
                        for: screen
                    ),

                styleMask: [
                    .borderless,
                    .nonactivatingPanel
                ],

                backing:
                    .buffered,

                defer:
                    false
            )


        // ====================================================
        // TRUE TRANSPARENT NSWINDOW
        // ====================================================
        //
        // This is important for NSGlassEffectView.
        //
        // There must not be an opaque AppKit window background
        // between Liquid Glass and the desktop/app underneath.
        //

        panel.isOpaque =
            false


        panel.backgroundColor =
            NSColor.clear


        panel.hasShadow =
            false


        // ====================================================
        // UTILITY WINDOW BEHAVIOR
        // ====================================================

        panel.hidesOnDeactivate =
            false


        panel.level =
            .statusBar


        panel.isMovable =
            false


        panel.isMovableByWindowBackground =
            false


        // ====================================================
        // DON'T STEAL NORMAL APP FOCUS
        // ====================================================

        panel.becomesKeyOnlyIfNeeded =
            true


        // ====================================================
        // SPACES / FULL SCREEN
        // ====================================================

        panel.collectionBehavior = [

            .canJoinAllSpaces,

            .fullScreenAuxiliary,

            .stationary,

            .ignoresCycle
        ]


        // ====================================================
        // ROOT SWIFTUI VIEW
        // ====================================================

        let rootView =
            NotchIslandView()


        let hostingView =
            NSHostingView(
                rootView:
                    rootView
            )


        // ====================================================
        // HOST MUST ALSO BE TRANSPARENT
        // ====================================================

        hostingView.wantsLayer =
            true


        hostingView.layer?
            .backgroundColor =
            NSColor.clear.cgColor


        hostingView.frame =
            NSRect(
                x: 0,
                y: 0,
                width:
                    panelWidth,
                height:
                    panelHeight
            )


        // ====================================================
        // TRANSPARENT ROOT CONTAINER
        // ====================================================

        let container =
            NSView(
                frame:
                    NSRect(
                        x: 0,
                        y: 0,
                        width:
                            panelWidth,
                        height:
                            panelHeight
                    )
            )


        container.wantsLayer =
            true


        container.layer?
            .backgroundColor =
            NSColor.clear.cgColor


        container.addSubview(
            hostingView
        )


        // ====================================================
        // AUTOLAYOUT
        // ====================================================

        hostingView.translatesAutoresizingMaskIntoConstraints =
            false


        NSLayoutConstraint.activate(
            [

                hostingView.leadingAnchor
                    .constraint(
                        equalTo:
                            container.leadingAnchor
                    ),

                hostingView.trailingAnchor
                    .constraint(
                        equalTo:
                            container.trailingAnchor
                    ),

                hostingView.topAnchor
                    .constraint(
                        equalTo:
                            container.topAnchor
                    ),

                hostingView.bottomAnchor
                    .constraint(
                        equalTo:
                            container.bottomAnchor
                    )
            ]
        )


        panel.contentView =
            container


        // ====================================================
        // SAVE PANEL
        // ====================================================

        self.panel =
            panel


        // ====================================================
        // SHOW
        // ====================================================

        panel.orderFrontRegardless()


        // ====================================================
        // SCREEN CHANGES
        // ====================================================

        observeScreenChanges()
    }


    // ========================================================
    // TARGET SCREEN
    // ========================================================

    private var targetScreen:
        NSScreen? {

        // Prefer the actual MacBook notch display.

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


    // ========================================================
    // PANEL FRAME
    // ========================================================

    private func panelFrame(
        for screen:
            NSScreen
    ) -> NSRect {

        let x =
            screen.frame.midX
            -
            panelWidth / 2


        let y =
            screen.frame.maxY
            -
            panelHeight


        return NSRect(
            x:
                x,

            y:
                y,

            width:
                panelWidth,

            height:
                panelHeight
        )
    }


    // ========================================================
    // UPDATE POSITION
    // ========================================================

    private func updatePosition() {

        guard
            let panel,
            let screen =
                targetScreen
        else {

            return
        }


        panel.setFrame(
            panelFrame(
                for:
                    screen
            ),

            display:
                true
        )
    }


    // ========================================================
    // DISPLAY CHANGES
    // ========================================================

    private func observeScreenChanges() {

        NotificationCenter
            .default
            .addObserver(

                forName:
                    NSApplication
                        .didChangeScreenParametersNotification,

                object:
                    nil,

                queue:
                    .main

            ) { [weak self] _ in

                Task { @MainActor in

                    self?
                        .updatePosition()
                }
            }
    }
}
