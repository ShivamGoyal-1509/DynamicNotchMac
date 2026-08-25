import AppKit
import Foundation
import Combine

@MainActor
final class AirDropManager: NSObject, ObservableObject {

    @Published var droppedFiles: [URL] = []

    @Published var isDraggingOverNotch = false

    private var sharingService: NSSharingService?


    // ========================================================
    // SEND USING AIRDROP
    // ========================================================

    func sendViaAirDrop(
        urls: [URL]
    ) {

        guard !urls.isEmpty else {
            return
        }

        droppedFiles = urls


        guard let service =
            NSSharingService(
                named: .sendViaAirDrop
            )
        else {

            print(
                "AirDrop sharing service unavailable"
            )

            return
        }


        // Keep a strong reference while the
        // system sharing UI is active.
        sharingService = service


        // Allows us to tell macOS where the
        // share animation originated.
        service.delegate = self


        service.perform(
            withItems: urls
        )
    }


    // ========================================================
    // NOTCH FRAME
    // ========================================================

    private func notchFrameOnScreen()
        -> NSRect {

        guard let screen =
            NSScreen.screens.first(
                where: {
                    $0.safeAreaInsets.top > 0
                }
            )
            ?? NSScreen.main
        else {

            return .zero
        }


        // Your measured notch dimensions.
        let width: CGFloat = 187
        let height: CGFloat = 32


        return NSRect(
            x:
                screen.frame.midX
                - width / 2,

            y:
                screen.frame.maxY
                - height,

            width:
                width,

            height:
                height
        )
    }
}


// ============================================================
// NSSharingServiceDelegate
// ============================================================

extension AirDropManager:
    NSSharingServiceDelegate {


    // Tell macOS that the share starts from
    // the physical notch location.
    func sharingService(
        _ sharingService: NSSharingService,
        sourceFrameOnScreenForShareItem item: Any
    ) -> NSRect {

        return notchFrameOnScreen()
    }


    // Share succeeded.
    func sharingService(
        _ sharingService: NSSharingService,
        didShareItems items: [Any]
    ) {

        print(
            "AirDrop completed"
        )

        self.sharingService = nil
    }


    // Share failed.
    func sharingService(
        _ sharingService: NSSharingService,
        didFailToShareItems items: [Any],
        error: Error
    ) {

        print(
            "AirDrop failed:",
            error
        )

        self.sharingService = nil
    }
}
