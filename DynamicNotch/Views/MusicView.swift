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
            spacing: 6
        ) {

            // =================================================
            // TOP ROW
            // =================================================

            HStack(
                spacing: 8
            ) {

                artwork

                songInformation

                Spacer(
                    minLength: 0
                )

                playbackControls
            }

            // =================================================
            // SCRUBBABLE PROGRESS
            // =================================================

            progressView
        }

        .padding(
            .horizontal,
            11
        )

        .padding(
            .top,
            29
        )

        .padding(
            .bottom,
            5
        )
    }

    // ========================================================
    // ARTWORK
    // ========================================================

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
                    width: 36,
                    height: 36
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 7,
                        style: .continuous
                    )
                )

            } else {

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 7,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                .pink,
                                .purple
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
                            size: 14
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                }

                .frame(
                    width: 36,
                    height: 36
                )
            }
        }
    }

    // ========================================================
    // SONG INFO
    // ========================================================

    private var songInformation:
        some View {

        VStack(
            alignment: .leading,
            spacing: 1
        ) {

            Text(
                music.title
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
            .lineLimit(1)
            .truncationMode(
                .tail
            )

            Text(
                music.artist
            )
            .font(
                .system(
                    size: 9
                )
            )
            .foregroundStyle(
                .gray
            )
            .lineLimit(1)
            .truncationMode(
                .tail
            )
        }
    }

    // ========================================================
    // PLAYBACK CONTROLS
    // ========================================================

    private var playbackControls:
        some View {

        HStack(
            spacing: 14
        ) {

            // Previous
            Button {
                music.previous()
            } label: {

                Image(
                    systemName:
                        "backward.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 24,
                    height: 28
                )
            }

            // Play / Pause
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
                        size: 17,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 26,
                    height: 28
                )
            }

            // Next
            Button {
                music.next()
            } label: {

                Image(
                    systemName:
                        "forward.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 24,
                    height: 28
                )
            }
        }

        .buttonStyle(
            .plain
        )

        .foregroundStyle(
            .white
        )

        .offset(
            x: -6
        )
    }

    // ========================================================
    // SCRUBBABLE PROGRESS VIEW
    // ========================================================

    private var progressView:
        some View {

        HStack(
            spacing: 6
        ) {

            // =================================================
            // CURRENT TIME
            // =================================================

            Text(
                formatTime(
                    displayedCurrentTime
                )
            )

            .font(
                .system(
                    size:
                        isScrubbing
                        ? 9
                        : 8,

                    weight:
                        isScrubbing
                        ? .semibold
                        : .regular
                )
            )

            .foregroundStyle(
                isScrubbing
                ? .white
                : .gray
            )

            .monospacedDigit()


            // =================================================
            // SCRUBBER
            // =================================================

            GeometryReader { geometry in

                ZStack(
                    alignment: .leading
                ) {

                    // Background track
                    Capsule()

                        .fill(
                            Color.white
                                .opacity(
                                    isScrubbing
                                    ? 0.30
                                    : 0.18
                                )
                        )


                    // Played section
                    Capsule()

                        .fill(
                            Color.white
                        )

                        .frame(
                            width:
                                geometry
                                    .size
                                    .width
                                * displayedProgress
                        )
                }

                // Becomes much bolder while dragging.
                .frame(
                    height:
                        isScrubbing
                        ? 7
                        : 3
                )

                // Larger invisible hit area so
                // the tiny bar is easy to grab.
                .frame(
                    maxHeight:
                        .infinity,
                    alignment:
                        .center
                )

                .contentShape(
                    Rectangle()
                )

                .gesture(

                    DragGesture(
                        minimumDistance: 0
                    )

                    // -----------------------------------------
                    // DRAGGING
                    // -----------------------------------------

                    .onChanged { value in

                        if !isScrubbing {

                            let current =
                                progress

                            scrubProgress =
                                current
                        }

                        isScrubbing =
                            true


                        guard
                            geometry.size.width > 0
                        else {
                            return
                        }


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


                    // -----------------------------------------
                    // RELEASE
                    // -----------------------------------------

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


                .animation(
                    .spring(
                        response: 0.20,
                        dampingFraction: 0.80
                    ),
                    value:
                        isScrubbing
                )
            }

            // Important:
            // larger interactive area than the visual bar.
            .frame(
                height: 16
            )


            // =================================================
            // DURATION
            // =================================================

            Text(
                formatTime(
                    music.duration
                )
            )

            .font(
                .system(
                    size:
                        isScrubbing
                        ? 9
                        : 8,

                    weight:
                        isScrubbing
                        ? .semibold
                        : .regular
                )
            )

            .foregroundStyle(
                isScrubbing
                ? .white
                : .gray
            )

            .monospacedDigit()
        }
    }

    // ========================================================
    // NORMAL PROGRESS
    // ========================================================

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

    // ========================================================
    // PROGRESS WHILE SCRUBBING
    // ========================================================

    private var displayedProgress:
        CGFloat {

        if isScrubbing {
            return scrubProgress
        }

        return progress
    }

    // ========================================================
    // CURRENT TIME WHILE SCRUBBING
    // ========================================================

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

    // ========================================================
    // TIME FORMAT
    // ========================================================

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
