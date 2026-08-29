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

    @State
    private var chargingExpansion:
        CGFloat = 0


    // ========================================================
    // MUSIC SIZE
    // ========================================================

    private let musicWidth:
        CGFloat = 350

    private let musicHeight:
        CGFloat = 145


    // ========================================================
    // CHARGING WINGS
    // ========================================================

    private let chargingLeftWingWidth:
        CGFloat = 85

    private let chargingRightWingWidth:
        CGFloat = 54


    private var chargingExpandedWidth:
        CGFloat {

        collapsedWidth
            +
            chargingLeftWingWidth
            +
            chargingRightWingWidth
    }


    // ========================================================
    // AIRDROP SIZE
    // ========================================================

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

    private let chargingExpandAnimation =
        Animation.spring(
            response: 0.30,
            dampingFraction: 0.86,
            blendDuration: 0.03
        )

    private let chargingCollapseAnimation =
        Animation.spring(
            response: 0.26,
            dampingFraction: 0.92,
            blendDuration: 0.03
        )

    private let glassAnimation =
        Animation.easeInOut(
            duration: 0.20
        )

    private let contentInAnimation =
        Animation.easeOut(
            duration: 0.10
        )

    private let contentOutAnimation =
        Animation.easeOut(
            duration: 0.06
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
                // BACKGROUND
                // =================================================

                if activity == .charging {

                    chargingBackground

                } else {

                    GlassNotchBackground(
                        width: currentWidth,
                        height: currentHeight,
                        cornerRadius: currentCornerRadius,
                        progress: glassProgress
                    )
                }


                // =================================================
                // CONTENT
                // =================================================

                if showContent {

                    currentContent
                        .transition(
                            .opacity
                        )
                }
            }

            .frame(
                width: currentWidth,
                height: currentHeight
            )

            .animation(
                activity == .charging
                ? nil
                : (
                    activity == .idle
                    ? collapseAnimation
                    : expandAnimation
                ),
                value: activity
            )

            .shadow(
                color:
                    activity == .idle
                    ||
                    activity == .charging
                    ? .clear
                    : .black.opacity(0.24),

                radius:
                    activity == .idle
                    ||
                    activity == .charging
                    ? 0
                    : 10,

                y:
                    activity == .idle
                    ||
                    activity == .charging
                    ? 0
                    : 4
            )

            .onDrop(
                of: [
                    UTType.fileURL.identifier
                ],

                isTargeted:
                    Binding(

                        get: {
                            airDrop.isDraggingOverNotch
                        },

                        set: { targeted in

                            airDrop.isDraggingOverNotch =
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

            .onChange(
                of: battery.changeToken
            ) { _, _ in

                guard
                    activity != .airDrop
                else {
                    return
                }

                showCharging()
            }

            .onChange(
                of: music.isPlaying
            ) { _, isPlaying in

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

        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )

        .onAppear {
            startMouseMonitor()
        }

        .onDisappear {

            hoverTimer?
                .invalidate()

            hoverTimer =
                nil
        }
    }


    // ========================================================
    // CHARGING BACKGROUND
    // ========================================================

    private var chargingBackground:
        some View {

        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 8,
            bottomTrailingRadius: 8,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(
            Color.black
        )
        .frame(
            width: currentWidth,
            height: collapsedHeight
        )
    }


    // ========================================================
    // CURRENT CONTENT
    // ========================================================

    @ViewBuilder
    private var currentContent:
        some View {

        switch activity {

        case .idle:

            EmptyView()


        case .music:

            MusicView(
                music: music
            )


        case .charging:

            ChargingView(
                battery: battery,
                notchWidth: collapsedWidth
            )


        case .airDrop:

            AirDropView(
                fileCount:
                    airDrop.droppedFiles.count,

                isTargeted:
                    airDrop.isDraggingOverNotch
            )
        }
    }


    // ========================================================
    // HARDWARE NOTCH WIDTH
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

        let value =
            right.minX
            -
            left.maxX

        return value > 0
            ? value
            : 185
    }


    // ========================================================
    // HARDWARE NOTCH HEIGHT
    // ========================================================

    private var collapsedHeight:
        CGFloat {

        guard let screen =
            targetScreen
        else {
            return 32
        }

        let value =
            screen.safeAreaInsets.top

        return value > 0
            ? value
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

            return collapsedWidth
                +
                (
                    chargingExpandedWidth
                    -
                    collapsedWidth
                )
                *
                chargingExpansion


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

            return collapsedHeight


        case .airDrop:

            return airDropHeight
        }
    }


    // ========================================================
    // CORNER RADIUS
    // ========================================================

    private var currentCornerRadius:
        CGFloat {

        switch activity {

        case .idle:

            return 8


        case .music:

            return 28


        case .charging:

            return 8


        case .airDrop:

            return 22
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
    // MOUSE MONITOR
    // ========================================================

    private func startMouseMonitor() {

        hoverTimer?
            .invalidate()

        hoverTimer =
            Timer.scheduledTimer(
                withTimeInterval: 0.06,
                repeats: true
            ) { _ in

                Task { @MainActor in
                    checkMousePosition()
                }
            }
    }


    private func checkMousePosition() {

        guard let screen =
            targetScreen
        else {
            return
        }

        switch activity {

        case .charging,
             .airDrop:

            return

        case .idle,
             .music:

            break
        }

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

        let hitWidth =
            activity == .music
            ? musicWidth
            : collapsedWidth

        let hitHeight =
            activity == .music
            ? musicHeight
            : collapsedHeight

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
            inside != mouseInsideIsland
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
    // STANDARD ACTIVITY
    // ========================================================

    private func showActivity(
        _ newActivity:
            IslandActivity
    ) {

        dismissTask?
            .cancel()

        glassProgress =
            0

        withAnimation(
            expandAnimation
        ) {

            activity =
                newActivity
        }

        if newActivity != .charging {

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
        }

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

        dismissTask?
            .cancel()

        showContent =
            false

        chargingExpansion =
            0

        activity =
            .charging


        // ====================================================
        // EXPAND WIDTH ONLY
        // ====================================================

        withAnimation(
            chargingExpandAnimation
        ) {

            chargingExpansion =
                1
        }


        // ====================================================
        // SHOW CONTENT
        // ====================================================

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(100)
            )

            guard
                activity == .charging
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


        // ====================================================
        // HOLD
        // ====================================================

        dismissTask =
            Task {

                try? await Task.sleep(
                    for:
                        .milliseconds(1700)
                )

                guard
                    !Task.isCancelled
                else {
                    return
                }

                await MainActor.run {
                    hideCharging()
                }
            }
    }


    // ========================================================
    // HIDE CHARGING
    // ========================================================

    private func hideCharging() {

        guard
            activity == .charging
        else {
            return
        }

        withAnimation(
            contentOutAnimation
        ) {

            showContent =
                false
        }

        Task { @MainActor in

            try? await Task.sleep(
                for:
                    .milliseconds(45)
            )

            withAnimation(
                chargingCollapseAnimation
            ) {

                chargingExpansion =
                    0
            }

            try? await Task.sleep(
                for:
                    .milliseconds(260)
            )

            guard
                chargingExpansion <= 0.01
            else {
                return
            }

            activity =
                .idle

            showContent =
                false
        }
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

        if activity == .charging {

            hideCharging()

            return
        }

        dismissTask?
            .cancel()

        withAnimation(
            contentOutAnimation
        ) {

            showContent =
                false
        }

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
    // AIRDROP FILE HANDLING
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

        for provider in supported {

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
            queue: .main
        ) {

            guard
                !urls.isEmpty
            else {

                restoreAfterTemporaryActivity()

                return
            }

            airDrop.droppedFiles =
                urls

            airDrop.sendViaAirDrop(
                urls: urls
            )

            airDrop.isDraggingOverNotch =
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
    // TEMPORARY DISMISS
    // ========================================================

    private func dismissTemporaryActivity(
        after milliseconds:
            Int
    ) {

        dismissTask =
            Task {

                try? await Task.sleep(
                    for:
                        .milliseconds(milliseconds)
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
