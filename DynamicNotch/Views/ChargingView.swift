import SwiftUI

struct ChargingView: View {

    @ObservedObject
    var battery: BatteryManager


    var body: some View {

        HStack(
            spacing: 11
        ) {

            // =================================================
            // ICON
            // =================================================

            Image(
                systemName:
                    battery.isCharging
                    ? "bolt.fill"
                    : "battery.100"
            )

            .font(
                .system(
                    size: 18,
                    weight: .semibold
                )
            )

            .foregroundStyle(
                battery.isCharging
                ? .green
                : .white
            )

            .frame(
                width: 24
            )


            // =================================================
            // LABEL + BAR
            // =================================================

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack {

                    Text(
                        battery.isCharging
                        ? "Charging"
                        : "On Battery"
                    )

                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )

                    .foregroundStyle(
                        .white
                    )


                    Spacer()


                    Text(
                        "\(battery.percentage)%"
                    )

                    .font(
                        .system(
                            size: 10,
                            weight: .medium
                        )
                    )

                    .foregroundStyle(
                        .gray
                    )

                    .monospacedDigit()
                }


                // =============================================
                // BATTERY BAR
                // =============================================

                GeometryReader { geometry in

                    ZStack(
                        alignment: .leading
                    ) {

                        Capsule()

                            .fill(
                                Color.white
                                    .opacity(
                                        0.18
                                    )
                            )


                        Capsule()

                            .fill(
                                battery.isCharging
                                ? Color.green
                                : Color.white
                            )

                            .frame(
                                width:
                                    geometry
                                        .size
                                        .width
                                    *
                                    CGFloat(
                                        battery.percentage
                                    )
                                    / 100
                            )
                    }
                }

                .frame(
                    height: 5
                )
            }
        }


        .padding(
            .horizontal,
            15
        )


        // Account for physical notch.
        .padding(
            .top,
            29
        )


        .padding(
            .bottom,
            8
        )
    }
}
