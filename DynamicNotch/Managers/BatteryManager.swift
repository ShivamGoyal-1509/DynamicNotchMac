import Foundation
import Combine
import IOKit.ps

@MainActor
final class BatteryManager: ObservableObject {

    // Battery percentage: 0...100
    @Published var percentage: Int = 0

    // True when connected to external power.
    @Published var isCharging: Bool = false

    // True when a battery exists.
    @Published var hasBattery: Bool = true

    // Changes whenever charging state changes.
    @Published var changeToken: Int = 0

    private var previousChargingState: Bool?

    private var timer: Timer?


    // ========================================================
    // INIT
    // ========================================================

    init() {

        updateBattery(
            triggerActivity: false
        )

        startTimer()
    }


    deinit {

        timer?.invalidate()
    }


    // ========================================================
    // TIMER
    // ========================================================

    private func startTimer() {

        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in

            Task { @MainActor in

                self?.updateBattery(
                    triggerActivity: true
                )
            }
        }
    }


    // ========================================================
    // UPDATE BATTERY
    // ========================================================

    private func updateBattery(
        triggerActivity: Bool
    ) {

        guard let snapshot =
            readBatteryState()
        else {

            hasBattery = false

            return
        }


        hasBattery = true

        percentage =
            snapshot.percentage


        // Only trigger the Dynamic Island when
        // charging/power state actually changes.
        if let previous =
            previousChargingState {

            if previous
                != snapshot.isCharging {

                if triggerActivity {

                    changeToken += 1
                }
            }
        }


        previousChargingState =
            snapshot.isCharging


        isCharging =
            snapshot.isCharging
    }


    // ========================================================
    // READ BATTERY
    // ========================================================

    private func readBatteryState()
        -> (
            percentage: Int,
            isCharging: Bool
        )? {

        guard let powerSourceInfo =
            IOPSCopyPowerSourcesInfo()?
                .takeRetainedValue()
        else {

            return nil
        }


        guard let powerSources =
            IOPSCopyPowerSourcesList(
                powerSourceInfo
            )?
            .takeRetainedValue()
            as? [CFTypeRef]
        else {

            return nil
        }


        for source in powerSources {

            guard let description =
                IOPSGetPowerSourceDescription(
                    powerSourceInfo,
                    source
                )?
                .takeUnretainedValue()
                as? [String: Any]
            else {

                continue
            }


            // -----------------------------------------------
            // Current charge
            // -----------------------------------------------

            let currentCapacity =
                description[
                    kIOPSCurrentCapacityKey
                        as String
                ]
                as? Int
                ?? 0


            let maxCapacity =
                description[
                    kIOPSMaxCapacityKey
                        as String
                ]
                as? Int
                ?? 100


            let calculatedPercentage: Int

            if maxCapacity > 0 {

                calculatedPercentage =
                    Int(
                        (
                            Double(
                                currentCapacity
                            )
                            /
                            Double(
                                maxCapacity
                            )
                        )
                        * 100
                    )

            } else {

                calculatedPercentage =
                    currentCapacity
            }


            // -----------------------------------------------
            // Power source
            // -----------------------------------------------

            let powerSourceState =
                description[
                    kIOPSPowerSourceStateKey
                        as String
                ]
                as? String


            let connectedToAC =
                powerSourceState
                    == (
                        kIOPSACPowerValue
                            as String
                    )


            // -----------------------------------------------
            // Is actively charging?
            //
            // For our UI, consider AC power as the
            // "charging connected" state. This means
            // the animation also works at 100%.
            // -----------------------------------------------

            return (
                max(
                    0,
                    min(
                        calculatedPercentage,
                        100
                    )
                ),
                connectedToAC
            )
        }


        return nil
    }
}
