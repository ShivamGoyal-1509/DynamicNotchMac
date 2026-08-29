import SwiftUI

struct MusicView: View {

    @ObservedObject
    var music: AppleMusicManager

    @State
    private var isScrubbing =
        false

    @State
    private var scrubProgress:
        CGFloat = 0


    var body: some View {

        VStack(
            spacing: 11
        ) {

            // =====================================================
            // HEADER
            // =====================================================

            HStack(
                spacing: 11
            ) {

                artwork


                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        music.title
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .lineLimit(1)
                    .truncationMode(
                        .tail
                    )


                    Text(
                        music.artist
                    )
                    .font(
                        .system(
                            size: 10
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.58)
                    )
                    .lineLimit(1)
                    .truncationMode(
                        .tail
                    )
                }


                Spacer(
                    minLength: 5
                )


                Image(
                    systemName:
                        "waveform"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.78)
                )
            }


            // =====================================================
            // PLAYBACK CONTROLS
            // =====================================================

            HStack(
                spacing: 34
            ) {

                Button {
                    music.previous()
                } label: {

                    Image(
                        systemName:
                            "backward.fill"
                    )
                    .font(
                        .system(
                            size: 19,
                            weight: .bold
                        )
                    )
                    .frame(
                        width: 32,
                        height: 30
                    )
                }


                Button {
                    music.togglePlayback()
                } label: {

                    Image(
                        systemName:
                            music.isPlaying
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(
                        .system(
                            size: 24,
                            weight: .bold
                        )
                    )
                    .frame(
                        width: 36,
                        height: 32
                    )
                }


                Button {
                    music.next()
                } label: {

                    Image(
                        systemName:
                            "forward.fill"
                    )
                    .font(
                        .system(
                            size: 19,
                            weight: .bold
                        )
                    )
                    .frame(
                        width: 32,
                        height: 30
                    )
                }
            }
            .buttonStyle(
                .plain
            )
            .foregroundStyle(
                .white
            )


            // =====================================================
            // SCRUBBER
            // =====================================================

            HStack(
                spacing: 8
            ) {

                Text(
                    formatTime(
                        displayedCurrentTime
                    )
                )
                .font(
                    .system(
                        size: 9,
                        weight:
                            isScrubbing
                            ? .semibold
                            : .regular
                    )
                )
                .foregroundStyle(
                    isScrubbing
                    ? .white
                    : .white.opacity(0.56)
                )
                .monospacedDigit()


                GeometryReader { geometry in

                    ZStack(
                        alignment: .leading
                    ) {

                        // Background track
                        Capsule()
                            .fill(
                                Color.white.opacity(
                                    isScrubbing
                                    ? 0.24
                                    : 0.14
                                )
                            )


                        // Played progress
                        Capsule()
                            .fill(
                                Color.white.opacity(
                                    isScrubbing
                                    ? 1.0
                                    : 0.82
                                )
                            )
                            .frame(
                                width:
                                    geometry.size.width
                                    * displayedProgress
                            )


                        // Scrubbing thumb
                        if isScrubbing {

                            Circle()
                                .fill(
                                    .white
                                )
                                .frame(
                                    width: 10,
                                    height: 10
                                )
                                .offset(
                                    x:
                                        max(
                                            0,
                                            geometry.size.width
                                            * displayedProgress
                                            - 5
                                        )
                                )
                        }
                    }
                    .frame(
                        height:
                            isScrubbing
                            ? 7
                            : 4
                    )
                    .frame(
                        maxHeight: .infinity,
                        alignment: .center
                    )
                    .contentShape(
                        Rectangle()
                    )
                    .gesture(

                        DragGesture(
                            minimumDistance: 0
                        )

                        .onChanged { value in

                            guard
                                geometry.size.width > 0
                            else {
                                return
                            }


                            if !isScrubbing {

                                scrubProgress =
                                    progress
                            }


                            isScrubbing =
                                true


                            let rawProgress =
                                value.location.x
                                /
                                geometry.size.width


                            scrubProgress =
                                min(
                                    max(
                                        rawProgress,
                                        0
                                    ),
                                    1
                                )
                        }


                        .onEnded { value in

                            guard
                                geometry.size.width > 0
                            else {

                                isScrubbing =
                                    false

                                return
                            }


                            let rawProgress =
                                value.location.x
                                /
                                geometry.size.width


                            let finalProgress =
                                min(
                                    max(
                                        rawProgress,
                                        0
                                    ),
                                    1
                                )


                            scrubProgress =
                                finalProgress


                            let newTime =
                                music.duration
                                *
                                Double(
                                    finalProgress
                                )


                            music.seek(
                                to: newTime
                            )


                            isScrubbing =
                                false
                        }
                    )
                }
                .frame(
                    height: 18
                )


                Text(
                    formatTime(
                        music.duration
                    )
                )
                .font(
                    .system(
                        size: 9,
                        weight:
                            isScrubbing
                            ? .semibold
                            : .regular
                    )
                )
                .foregroundStyle(
                    isScrubbing
                    ? .white
                    : .white.opacity(0.56)
                )
                .monospacedDigit()
            }

            // Move only the seeking bar/time row upward.
            .offset(
                y: -9
            )
        }


        // =========================================================
        // PLAYER POSITIONING
        // =========================================================

        .padding(
            .horizontal,
            18
        )

        // Keeps artwork/title below the physical notch.
        .padding(
            .top,
            44
        )

        .padding(
            .bottom,
            11
        )
    }


    // =========================================================
    // ARTWORK
    // =========================================================

    private var artwork:
        some View {

        Group {

            if let artwork =
                music.artwork {

                Image(
                    nsImage: artwork
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width: 46,
                    height: 46
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 9,
                        style: .continuous
                    )
                )

            } else {

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 9,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                .purple,
                                .pink
                            ],
                            startPoint:
                                .topLeading,
                            endPoint:
                                .bottomTrailing
                        )
                    )


                    Image(
                        systemName:
                            "music.note"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                }
                .frame(
                    width: 46,
                    height: 46
                )
            }
        }
    }


    // =========================================================
    // NORMAL PROGRESS
    // =========================================================

    private var progress:
        CGFloat {

        guard
            music.duration > 0
        else {

            return 0
        }


        let value =
            music.currentTime
            /
            music.duration


        return CGFloat(
            min(
                max(
                    value,
                    0
                ),
                1
            )
        )
    }


    // =========================================================
    // DISPLAYED PROGRESS
    // =========================================================

    private var displayedProgress:
        CGFloat {

        if isScrubbing {

            return scrubProgress
        }


        return progress
    }


    // =========================================================
    // DISPLAYED CURRENT TIME
    // =========================================================

    private var displayedCurrentTime:
        Double {

        if isScrubbing {

            return music.duration
                *
                Double(
                    scrubProgress
                )
        }


        return music.currentTime
    }


    // =========================================================
    // TIME FORMAT
    // =========================================================

    private func formatTime(
        _ time: Double
    ) -> String {

        guard
            time.isFinite,
            time >= 0
        else {

            return "0:00"
        }


        let total =
            Int(time)


        let minutes =
            total / 60


        let seconds =
            total % 60


        return String(
            format:
                "%d:%02d",
            minutes,
            seconds
        )
    }
}
