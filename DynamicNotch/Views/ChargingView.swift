import SwiftUI

struct ChargingView: View {

    @ObservedObject
    var battery: BatteryManager

    let notchWidth: CGFloat

    @State
    private var pulse = false


    // =========================================================
    // WING WIDTHS
    // =========================================================
    //
    // Increase these if you want the charging notch wider.
    //

    private let leftWingWidth:
        CGFloat = 76

    private let rightWingWidth:
        CGFloat = 44


    var body: some View {

        HStack(
            spacing: 0
        ) {

            // =====================================================
            // LEFT WING
            // =====================================================

            HStack(
                spacing: 5
            ) {

                Image(
                    systemName:
                        "battery.100percent"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.78)
                )


                Text(
                    "\(battery.percentage)%"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    .white
                )
            }
            .frame(
                width: leftWingWidth,
                height: 30,
                alignment: .leading
            )
            .padding(
                .leading,
                8
            )


            // =====================================================
            // PHYSICAL NOTCH RESERVED AREA
            // =====================================================
            //
            // Absolutely nothing is drawn here.
            //

            Color.clear
                .frame(
                    width: notchWidth,
                    height: 30
                )


            // =====================================================
            // RIGHT WING
            // =====================================================

            HStack {

                Spacer(
                    minLength: 0
                )


                // =================================================
                // CHARGING BOLT
                // =================================================
                //
                // Green while actively charging.
                //
                // Completely invisible when not charging.
                //

                Image(
                    systemName:
                        "bolt.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    battery.isCharging
                        ? Color.green
                        : Color.clear
                )

                // Pulse only while charging.
                .scaleEffect(
                    battery.isCharging
                        ? (
                            pulse
                            ? 1.07
                            : 0.94
                        )
                        : 1.0
                )

                .opacity(
                    battery.isCharging
                        ? (
                            pulse
                            ? 1.0
                            : 0.75
                        )
                        : 0
                )
            }
            .frame(
                width: rightWingWidth,
                height: 30
            )
            .padding(
                .trailing,
                8
            )
        }


        // =========================================================
        // TOTAL SIZE
        // =========================================================

        .frame(
            width:
                leftWingWidth
                +
                notchWidth
                +
                rightWingWidth,

            height: 30
        )


        // =========================================================
        // PULSE ANIMATION
        // =========================================================

        .onAppear {

            pulse =
                false


            withAnimation(
                .easeInOut(
                    duration: 0.65
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {

                pulse =
                    true
            }
        }
    }
}
