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
    // ACTIVITY STATE
    // ========================================================

    @State
    private var activity:
        IslandActivity = .idle

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
    // PHYSICAL NOTCH
    // ========================================================

    private let collapsedWidth:
        CGFloat = 187

    private let collapsedHeight:
        CGFloat = 32


    // ========================================================
    // MUSIC
    // ========================================================

    private let musicWidth:
        CGFloat = 330

    private let musicHeight:
        CGFloat = 104


    // ========================================================
    // CHARGING
    // ========================================================

    private let chargingWidth:
        CGFloat = 260

    private let chargingHeight:
        CGFloat = 78


    // ========================================================
    // AIRDROP
    // ========================================================

    private let airDropWidth:
        CGFloat = 300

    private let airDropHeight:
        CGFloat = 125


    // ========================================================
    // BODY
    // ========================================================

    var body: some View {

        VStack(spacing: 0) {

            ZStack {

                // =================================================
                // BLACK NOTCH BACKGROUND
                // =================================================

                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius:
                        cornerRadius,
                    bottomTrailingRadius:
                        cornerRadius,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(.black)


                // =================================================
                // CURRENT ACTIVITY
                // =================================================

                switch activity {

                case .idle:

                    EmptyView()


                case .music:

                    MusicView(
                        music: music
                    )
                    .transition(
                        activityTransition
                    )


                case .charging:

                    ChargingView(
                        battery: battery
                    )
                    .transition(
                        activityTransition
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
                    .transition(
                        activityTransition
                    )
                }
            }


            // =====================================================
            // CURRENT SIZE
            // =====================================================

            .frame(
                width:
                    currentWidth,

                height:
                    currentHeight
            )


            // =====================================================
            // SHADOW
            // =====================================================

            .shadow(
                color:
                    activity == .idle
                    ? .clear
                    : .black.opacity(0.25),

                radius: 8,

                y: 3
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
            // CHARGING STATE CHANGE
            // =====================================================

            .onChange(
                of:
                    battery.changeToken
            ) { _, _ in

                guard
                    activity != .airDrop
                else {
                    return
                }

                showCharging()
            }


            // =====================================================
            // MUSIC PLAYING STATE
            // =====================================================

            .onChange(
                of:
                    music.isPlaying
            ) { _, isPlaying in

                // If music stops or pauses while the
                // music island is visible, collapse it.
                if !isPlaying,
                   activity == .music {

                    dismissTask?
                        .cancel()

                    mouseInsideIsland =
                        false

                    withAnimation(
                        .spring(
                            response: 0.30,
                            dampingFraction: 0.84
                        )
                    ) {

                        activity =
                            .idle
                    }
                }
            }


            Spacer()
        }


        // =========================================================
        // LARGE TRANSPARENT PANEL CONTAINER
        // =========================================================

        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
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
    // GLOBAL MOUSE MONITOR
    // ========================================================

    private func startMouseMonitor() {

        hoverTimer?
            .invalidate()


        hoverTimer =
            Timer.scheduledTimer(
                withTimeInterval: 0.08,
                repeats: true
            ) { _ in

                Task { @MainActor in

                    checkMousePosition()
                }
            }
    }


    // ========================================================
    // CHECK CURSOR POSITION
    // ========================================================

    private func checkMousePosition() {

        guard let screen =
            targetScreen
        else {
            return
        }


        // Charging and AirDrop are temporary activities.
        // Hover logic should not interfere with them.
        switch activity {

        case .charging,
             .airDrop:

            return


        case .idle,
             .music:

            break
        }


        // ====================================================
        // MUSIC SHOULD ONLY REACT WHEN IT IS PLAYING
        // ====================================================

        guard music.isPlaying else {

            mouseInsideIsland =
                false


            if activity == .music {

                withAnimation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.84
                    )
                ) {

                    activity =
                        .idle
                }
            }

            return
        }


        let mouse =
            NSEvent.mouseLocation


        let hitWidth:
            CGFloat

        let hitHeight:
            CGFloat


        // When Music is expanded, keep the entire
        // music island interactive so controls and
        // scrubbing remain usable.
        if activity == .music {

            hitWidth =
                musicWidth

            hitHeight =
                musicHeight

        } else {

            // When idle, only the physical notch
            // region activates Music.
            hitWidth =
                collapsedWidth

            hitHeight =
                collapsedHeight
        }


        let islandRect =
            NSRect(
                x:
                    screen.frame.midX
                    - hitWidth / 2,

                y:
                    screen.frame.maxY
                    - hitHeight,

                width:
                    hitWidth,

                height:
                    hitHeight
            )


        let inside =
            islandRect.contains(
                mouse
            )


        guard
            inside
                != mouseInsideIsland
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
    // TARGET SCREEN
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
    // TRANSITION
    // ========================================================

    private var activityTransition:
        AnyTransition {

        .opacity
            .combined(
                with:
                    .scale(
                        scale: 0.96
                    )
            )
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
    // CORNER RADIUS
    // ========================================================

    private var cornerRadius:
        CGFloat {

        switch activity {

        case .idle:

            return 10


        case .music:

            return 22


        case .charging:

            return 20


        case .airDrop:

            return 22
        }
    }


    // ========================================================
    // SHOW MUSIC
    // ========================================================

    private func showMusic() {

        // Never show Music when nothing is playing.
        guard music.isPlaying else {
            return
        }


        dismissTask?
            .cancel()


        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.78
            )
        ) {

            activity =
                .music
        }
    }


    // ========================================================
    // HIDE MUSIC
    // ========================================================

    private func hideMusicAfterDelay() {

        dismissTask?
            .cancel()


        dismissTask =
            Task {

                try? await Task.sleep(
                    for:
                        .milliseconds(180)
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


                    withAnimation(
                        .spring(
                            response: 0.30,
                            dampingFraction: 0.84
                        )
                    ) {

                        activity =
                            .idle
                    }
                }
            }
    }


    // ========================================================
    // SHOW CHARGING
    // ========================================================

    private func showCharging() {

        dismissTask?
            .cancel()


        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.78
            )
        ) {

            activity =
                .charging
        }


        dismissTemporaryActivity(
            after: 2000
        )
    }


    // ========================================================
    // SHOW AIRDROP TARGET
    // ========================================================

    private func showAirDropTarget() {

        dismissTask?
            .cancel()


        withAnimation(
            .spring(
                response: 0.26,
                dampingFraction: 0.76
            )
        ) {

            activity =
                .airDrop
        }
    }


    // ========================================================
    // HANDLE DROPPED FILES
    // ========================================================

    private func handleDroppedFiles(
        _ providers: [NSItemProvider]
    ) -> Bool {

        let supportedProviders =
            providers.filter {

                $0.hasItemConformingToTypeIdentifier(
                    UTType.fileURL.identifier
                )
            }


        guard
            !supportedProviders.isEmpty
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
            supportedProviders {

            group.enter()


            provider.loadItem(
                forTypeIdentifier:
                    UTType.fileURL.identifier,
                options: nil
            ) { item, _ in

                defer {

                    group.leave()
                }


                var discoveredURL:
                    URL?


                // Finder can provide the file URL as Data.
                if let data =
                    item as? Data {

                    discoveredURL =
                        URL(
                            dataRepresentation:
                                data,
                            relativeTo: nil
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
            queue: .main
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


            airDrop.sendViaAirDrop(
                urls: urls
            )


            airDrop
                .isDraggingOverNotch =
                false


            restoreAfterTemporaryActivity()
        }


        return true
    }


    // ========================================================
    // RESTORE NORMAL STATE
    // ========================================================

    private func restoreAfterTemporaryActivity() {

        mouseInsideIsland =
            false


        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.84
            )
        ) {

            activity =
                .idle
        }


        // Mouse monitor will reopen Music automatically
        // only if:
        // 1. Music is actually playing.
        // 2. Cursor is over the notch.
    }


    // ========================================================
    // TEMPORARY ACTIVITY DISMISSAL
    // ========================================================

    private func dismissTemporaryActivity(
        after milliseconds: Int
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
