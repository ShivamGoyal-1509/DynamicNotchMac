import SwiftUI

struct AirDropView: View {

    let fileCount: Int
    let isTargeted: Bool

    var body: some View {

        VStack(spacing: 7) {

            Spacer()
                .frame(height: 28)

            HStack(spacing: 10) {

                Image(
                    systemName:
                        isTargeted
                        ? "arrow.down.circle.fill"
                        : "airplayaudio"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isTargeted
                    ? .blue
                    : .white
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("AirDrop")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(
                            .system(size: 9)
                        )
                        .foregroundStyle(.gray)
                }

                Spacer()

                if isTargeted {

                    Text("DROP")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.blue)
                }
            }

            // Actual visible drop zone.
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .strokeBorder(
                Color.white.opacity(
                    isTargeted
                    ? 0.55
                    : 0.20
                ),
                style:
                    StrokeStyle(
                        lineWidth: 1,
                        dash: [5, 4]
                    )
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(
                    Color.white.opacity(
                        isTargeted
                        ? 0.10
                        : 0.04
                    )
                )
            )
            .overlay {

                Text(
                    isTargeted
                    ? "Release here"
                    : "Drop files here"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    isTargeted
                    ? .white
                    : .gray
                )
            }
            .frame(
                height: 32
            )
        }

        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    private var subtitle: String {

        if fileCount == 0 {

            return "Drag files below the notch"
        }

        if fileCount == 1 {

            return "1 file ready"
        }

        return "\(fileCount) files ready"
    }
}
