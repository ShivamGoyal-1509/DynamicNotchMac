import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct NotchIslandView: View {

    // ========================================================
    // MANAGERS
    // ========================================================

    @StateObject
    private var music =
        AppleMusicManager()

    @StateObject
    private var battery =
        BatteryManager()

    @StateObject
    private var airDrop =
        AirDropManager()


    // ========================================================
    // STATE
    // ========================================================

    @State
    private var activity:
        IslandActivity = .idle


    // Controls only the black -> Liquid Glass reveal.
    @State
    private var glassProgress:
        CGFloat = 0


    @State
    private var showContent =
        false


    @State
    private var dismissTask:
        Task<Void, Never>?


    @State
    private var hoverTimer:
        Timer?


    @State
    private var mouseInsideIsland =
        false


    // ========================================================
    // EXPANDED SIZES
    // ========================================================

    private let musicWidth:
        CGFloat = 350

    private let musicHeight:
        CGFloat = 145


    private let chargingWidth:
        CGFloat = 260

    private let chargingHeight:
        CGFloat = 78


    private let airDropWidth:
        CGFloat = 300

    private let airDropHeight:
        CGFloat = 125


    // ========================================================
    // ANIMATIONS
    // ========================================================

    private let expandAnimation =
        Animation.spring(
            response: 0.35,
            dampingFraction: 0.89,
            blendDuration: 0.07
        )


    private let collapseAnimation =
        Animation.spring(
            response: 0.30,
            dampingFraction: 0.94,
            blendDuration: 0.05
        )


    private let glassAnimation =
        Animation.easeInOut(
            duration: 0.20
        )


    private let contentInAnimation =
        Animation.easeOut(
            duration: 0.11
        )


    private let contentOutAnimation =
        Animation.easeOut(
            duration: 0.07
        )


    // ========================================================
    // BODY
    // ========================================================

    var body: some View {

        VStack(
            spacing: 0
        ) {

            ZStack {

                // =================================================
                // LIQUID GLASS BACKGROUND
                // =================================================
                //
                // IMPORTANT:
                //
                // GlassNotchBackground.swift is the ONLY place
                // where .glassEffect(...) should be applied.
                //

                GlassNotchBackground(
                    width:
                        currentWidth,

                    height:
                        currentHeight,

                    cornerRadius:
                        currentCornerRadius,

                    progress:
                        glassProgress
                )


                // =================================================
                // ACTIVITY CONTENT
                // =================================================

                if showContent {

                    currentContent
                        .transition(
                            .opacity
                        )
                }
            }


            // =====================================================
            // SIZE
            // =====================================================

            .frame(
                width:
                    currentWidth,

                height:
                    currentHeight
            )


            // =====================================================
            // GEOMETRY ANIMATION
            // =====================================================
            //
            // This controls the physical shape expanding from
            // and collapsing into the MacBook notch.
            //

            .animation(
                activity == .idle
                ? collapseAnimation
                : expandAnimation,

                value:
                    activity
            )


            // =====================================================
            // SHADOW
            // =====================================================

            .shadow(
                color:
                    activity == .idle
                    ? .clear
                    : .black.opacity(0.24),

                radius:
                    activity == .idle
                    ? 0
                    : 10,

                y:
                    activity == .idle
                    ? 0
                    : 4
            )


            // =====================================================
            // AIRDROP
            // =====================================================

            .onDrop(
                of: [
                    UTType.fileURL.identifier
                ],

                isTargeted:
                    Binding(

                        get: {

                            airDrop
                                .isDraggingOverNotch
                        },

                        set: { targeted in

                            airDrop
                                .isDraggingOverNotch =
                                targeted


                            if targeted {

                                showAirDropTarget()

                            } else if
                                activity == .airDrop {

                                restoreAfterTemporaryActivity()
                            }
                        }
                    )
            ) { providers in

                handleDroppedFiles(
                    providers
                )
            }


            // =====================================================
            // CHARGING
            // =====================================================

            .onChange(
                of:
                    battery.changeToken
            ) { _, _ in

                // AirDrop should not be interrupted.
                guard
                    activity != .airDrop
                else {

                    return
                }


                showCharging()
            }


            // =====================================================
            // MUSIC STATE
            // =====================================================

            .onChange(
                of:
                    music.isPlaying
            ) { _, isPlaying in

                // If Music gets paused or stopped while
                // expanded, collapse back into the notch.

                if !isPlaying,
                   activity == .music {

                    dismissTask?
                        .cancel()


                    mouseInsideIsland =
                        false


                    collapseToIdle()
                }
            }


            Spacer()
        }


        // =========================================================
        // FLOATING PANEL AREA
        // =========================================================

        .frame(
            maxWidth:
                .infinity,

            maxHeight:
                .infinity,

            alignment:
                .top
        )


        // =========================================================
        // START MOUSE MONITOR
        // =========================================================

        .onAppear {

            startMouseMonitor()
        }


        // =========================================================
        // STOP MOUSE MONITOR
        // =========================================================

        .onDisappear {

            hoverTimer?
                .invalidate()


            hoverTimer =
                nil
        }
    }


    // ========================================================
    // ACTIVITY CONTENT
    // ========================================================

    @ViewBuilder
    private var currentContent:
        some View {

        switch activity {

        case .idle:

            EmptyView()


        case .music:

            MusicView(
                music:
                    music
            )


        case .charging:

            ChargingView(
                battery:
                    battery
            )


        case .airDrop:

            AirDropView(

                fileCount:
                    airDrop
                        .droppedFiles
                        .count,

                isTargeted:
                    airDrop
                        .isDraggingOverNotch
            )
        }
    }


    // ========================================================
    // ACTUAL MACBOOK NOTCH WIDTH
    // ========================================================

    private var collapsedWidth:
        CGFloat {

        guard let screen =
            targetScreen
        else {

            return 185
        }


        guard
            let left =
                screen.auxiliaryTopLeftArea,

            let right =
                screen.auxiliaryTopRightArea

        else {

            return 185
        }


        let width =
            right.minX
            -
            left.maxX


        return width > 0
            ? width
            : 185
    }


    // ========================================================
    // ACTUAL MACBOOK NOTCH HEIGHT
    // ========================================================

    private var collapsedHeight:
        CGFloat {

        guard let screen =
            targetScreen
        else {

            return 32
        }


        let height =
            screen
                .safeAreaInsets
                .top


        return height > 0
            ? height
            : 32
    }


    // ========================================================
    // CURRENT WIDTH
    // ========================================================

    private var currentWidth:
        CGFloat {

        switch activity {

        case .idle:

            return collapsedWidth


        case .music:

            return musicWidth


        case .charging:

            return chargingWidth


        case .airDrop:

            return airDropWidth
        }
    }


    // ========================================================
    // CURRENT HEIGHT
    // ========================================================

    private var currentHeight:
        CGFloat {

        switch activity {

        case .idle:

            return collapsedHeight


        case .music:

            return musicHeight


        case .charging:

            return chargingHeight


        case .airDrop:

            return airDropHeight
        }
    }


    // ========================================================
    // CURRENT CORNER RADIUS
    // ========================================================

    private var currentCornerRadius:
        CGFloat {

        switch activity {

        case .idle:

            return 8


        case .music:

            return 28


        case .charging:

            return 20


        case .airDrop:

            return 22
        }
    }


    // ========================================================
    // TARGET DISPLAY
    // ========================================================

    private var targetScreen:
        NSScreen? {

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
    // MOUSE MONITOR
    // ========================================================

    private func startMouseMonitor() {

        hoverTimer?
            .invalidate()


        hoverTimer =
            Timer.scheduledTimer(

                withTimeInterval:
                    0.06,

                repeats:
                    true

            ) { _ in

                Task { @MainActor in

                    checkMousePosition()
                }
            }
    }


    // ========================================================
    // CHECK MOUSE POSITION
    // ========================================================

    private func checkMousePosition() {

        guard let screen =
            targetScreen
        else {

            return
        }


        // Charging and AirDrop control themselves.
        switch activity {

        case .charging,
             .airDrop:

            return


        case .idle,
             .music:

            break
        }


        // ====================================================
        // MUSIC ONLY RESPONDS WHILE PLAYING
        // ====================================================

        guard
            music.isPlaying
        else {

            mouseInsideIsland =
                false


            if activity == .music {

                collapseToIdle()
            }


            return
        }


        let mouse =
            NSEvent.mouseLocation


        let hitWidth:
            CGFloat


        let hitHeight:
            CGFloat


        if activity == .music {

            // Full expanded player remains interactive.

            hitWidth =
                musicWidth


            hitHeight =
                musicHeight

        } else {

            // Collapsed state uses only the hardware notch.

            hitWidth =
                collapsedWidth


            hitHeight =
                collapsedHeight
        }


        let rect =
            NSRect(

                x:
                    screen.frame.midX
                    -
                    hitWidth / 2,

                y:
                    screen.frame.maxY
                    -
                    hitHeight,

                width:
                    hitWidth,

                height:
                    hitHeight
            )


        let inside =
            rect.contains(
                mouse
            )


        guard
            inside
            !=
            mouseInsideIsland
        else {

            return
        }


        mouseInsideIsland =
            inside


        if inside {

            if activity == .idle {

                showMusic()
            }

        } else {

            if activity == .music {

                hideMusicAfterDelay()
            }
        }
    }


    // ========================================================
    // SHOW ACTIVITY
    // ========================================================

    private func showActivity(
        _ newActivity:
            IslandActivity
    ) {

        dismissTask?
            .cancel()


        // Start fully black.
        glassProgress =
            0


        // ====================================================
        // 1. EXPAND FROM PHYSICAL NOTCH
        // ====================================================

        withAnimation(
            expandAnimation
        ) {

            activity =
                newActivity
        }


        // ====================================================
        // 2. REVEAL LIQUID GLASS
        // ====================================================

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(25)
            )


            guard
                activity == newActivity
            else {

                return
            }


            withAnimation(
                glassAnimation
            ) {

                glassProgress =
                    1
            }
        }


        // ====================================================
        // 3. SHOW CONTENT
        // ====================================================

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(65)
            )


            guard
                activity == newActivity
            else {

                return
            }


            withAnimation(
                contentInAnimation
            ) {

                showContent =
                    true
            }
        }
    }


    // ========================================================
    // MUSIC
    // ========================================================

    private func showMusic() {

        guard
            music.isPlaying
        else {

            return
        }


        showActivity(
            .music
        )
    }


    private func hideMusicAfterDelay() {

        dismissTask?
            .cancel()


        dismissTask =
            Task {

                try? await Task.sleep(
                    for:
                        .milliseconds(120)
                )


                guard
                    !Task.isCancelled
                else {

                    return
                }


                await MainActor.run {

                    guard
                        activity == .music,
                        !mouseInsideIsland
                    else {

                        return
                    }


                    collapseToIdle()
                }
            }
    }


    // ========================================================
    // CHARGING
    // ========================================================

    private func showCharging() {

        showActivity(
            .charging
        )


        dismissTemporaryActivity(
            after:
                2000
        )
    }


    // ========================================================
    // AIRDROP
    // ========================================================

    private func showAirDropTarget() {

        showActivity(
            .airDrop
        )
    }


    // ========================================================
    // COLLAPSE
    // ========================================================

    private func collapseToIdle() {

        dismissTask?
            .cancel()


        // ====================================================
        // 1. CONTENT OUT
        // ====================================================

        withAnimation(
            contentOutAnimation
        ) {

            showContent =
                false
        }


        // ====================================================
        // 2. GLASS RETURNS TO BLACK
        // ====================================================

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(15)
            )


            withAnimation(
                glassAnimation
            ) {

                glassProgress =
                    0
            }
        }


        // ====================================================
        // 3. COLLAPSE INTO HARDWARE NOTCH
        // ====================================================

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(40)
            )


            withAnimation(
                collapseAnimation
            ) {

                activity =
                    .idle
            }
        }
    }


    // ========================================================
    // HANDLE AIRDROP FILES
    // ========================================================

    private func handleDroppedFiles(
        _ providers:
            [NSItemProvider]
    ) -> Bool {

        let supported =
            providers.filter {

                $0.hasItemConformingToTypeIdentifier(
                    UTType.fileURL.identifier
                )
            }


        guard
            !supported.isEmpty
        else {

            return false
        }


        let lock =
            NSLock()


        var urls:
            [URL] = []


        let group =
            DispatchGroup()


        for provider in
            supported {

            group.enter()


            provider.loadItem(

                forTypeIdentifier:
                    UTType.fileURL.identifier,

                options:
                    nil

            ) { item, _ in

                defer {

                    group.leave()
                }


                var discoveredURL:
                    URL?


                if let data =
                    item as? Data {

                    discoveredURL =
                        URL(

                            dataRepresentation:
                                data,

                            relativeTo:
                                nil
                        )


                } else if let url =
                    item as? URL {

                    discoveredURL =
                        url


                } else if let nsURL =
                    item as? NSURL {

                    discoveredURL =
                        nsURL as URL
                }


                if let discoveredURL {

                    lock.lock()


                    urls.append(
                        discoveredURL
                    )


                    lock.unlock()
                }
            }
        }


        group.notify(
            queue:
                .main
        ) {

            guard
                !urls.isEmpty
            else {

                restoreAfterTemporaryActivity()

                return
            }


            airDrop
                .droppedFiles =
                urls


            airDrop
                .sendViaAirDrop(
                    urls:
                        urls
                )


            airDrop
                .isDraggingOverNotch =
                false


            restoreAfterTemporaryActivity()
        }


        return true
    }


    // ========================================================
    // RESTORE
    // ========================================================

    private func restoreAfterTemporaryActivity() {

        mouseInsideIsland =
            false


        collapseToIdle()
    }


    // ========================================================
    // TEMPORARY ACTIVITY DISMISSAL
    // ========================================================

    private func dismissTemporaryActivity(
        after milliseconds:
            Int
    ) {

        dismissTask =
            Task {

                try? await Task.sleep(
                    for:
                        .milliseconds(
                            milliseconds
                        )
                )


                guard
                    !Task.isCancelled
                else {

                    return
                }


                await MainActor.run {

                    restoreAfterTemporaryActivity()
                }
            }
    }
}
