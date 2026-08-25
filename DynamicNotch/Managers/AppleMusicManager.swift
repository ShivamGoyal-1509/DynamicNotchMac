import AppKit
import Combine

@MainActor
final class AppleMusicManager: ObservableObject {

    @Published var title: String = "Nothing Playing"
    @Published var artist: String = "Apple Music"
    @Published var album: String = ""
    @Published var artwork: NSImage?

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    private var previousTrackIdentifier = ""
    private var timer: Timer?

    init() {
        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(500)
            )

            self.update()
            self.startTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // ========================================================
    // TIMER
    // ========================================================

    private func startTimer() {
        timer?.invalidate()

        timer =
            Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: true
            ) { [weak self] _ in

                Task { @MainActor in
                    self?.update()
                }
            }
    }

    // ========================================================
    // CHECK MUSIC
    // ========================================================

    private func isMusicRunning() -> Bool {
        NSWorkspace.shared
            .runningApplications
            .contains {
                $0.bundleIdentifier
                    == "com.apple.Music"
            }
    }

    // ========================================================
    // UPDATE CURRENT TRACK
    // ========================================================

    func update() {
        guard isMusicRunning() else {
            title = "Apple Music"
            artist = "Music is not open"
            album = ""
            artwork = nil

            isPlaying = false
            currentTime = 0
            duration = 0

            return
        }

        let script = """

        tell application id "com.apple.Music"

            try

                set currentState to player state as string

                if currentState is "stopped" then
                    return "NOT_PLAYING"
                end if

                set currentSong to current track

                set trackName to name of currentSong
                set artistName to artist of currentSong
                set albumName to album of currentSong
                set trackDuration to duration of currentSong
                set currentPosition to player position

                return trackName & "|||" & ¬
                    artistName & "|||" & ¬
                    albumName & "|||" & ¬
                    (trackDuration as string) & "|||" & ¬
                    (currentPosition as string) & "|||" & ¬
                    currentState

            on error errorMessage number errorNumber

                return "ERROR|||" & ¬
                    (errorNumber as string) & "|||" & ¬
                    errorMessage

            end try

        end tell
        """

        guard let result =
            runAppleScript(script)
        else {
            return
        }

        if result == "NOT_PLAYING" {
            title = "Nothing Playing"
            artist = "Apple Music"
            album = ""
            artwork = nil

            isPlaying = false
            currentTime = 0
            duration = 0

            previousTrackIdentifier = ""

            return
        }

        if result.hasPrefix("ERROR|||") {
            print(
                "Music error:",
                result
            )

            isPlaying = false
            return
        }

        let parts =
            result.components(
                separatedBy: "|||"
            )

        guard parts.count >= 6 else {
            return
        }

        let newTitle =
            parts[0]

        let newArtist =
            parts[1]

        let newAlbum =
            parts[2]

        title =
            newTitle

        artist =
            newArtist

        album =
            newAlbum

        duration =
            Double(parts[3]) ?? 0

        currentTime =
            Double(parts[4]) ?? 0

        isPlaying =
            parts[5]
                .lowercased()
                .contains("playing")

        let identifier =
            newTitle
            + "|"
            + newArtist
            + "|"
            + newAlbum

        if identifier != previousTrackIdentifier {
            previousTrackIdentifier =
                identifier

            loadCurrentArtwork()
        }
    }

    // ========================================================
    // ARTWORK
    // ========================================================

    private func loadCurrentArtwork() {
        let artworkPath =
            NSTemporaryDirectory()
            + "DynamicNotchArtwork"

        try? FileManager.default
            .removeItem(
                atPath: artworkPath
            )

        let script = """

        set artworkPath to "\(artworkPath)"

        tell application id "com.apple.Music"

            try

                set currentSong to current track

                if (count of artworks of currentSong) is 0 then
                    return "NO_ARTWORK"
                end if

                set artworkData to data of artwork 1 of currentSong

                set artworkFile to open for access POSIX file artworkPath with write permission

                set eof artworkFile to 0

                write artworkData to artworkFile starting at 0

                close access artworkFile

                return "OK"

            on error

                try
                    close access POSIX file artworkPath
                end try

                return "ERROR"

            end try

        end tell
        """

        guard
            let result =
                runAppleScript(script),
            result == "OK"
        else {
            artwork = nil
            return
        }

        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(100)
            )

            artwork =
                NSImage(
                    contentsOfFile:
                        artworkPath
                )
        }
    }

    // ========================================================
    // PREVIOUS
    // ========================================================

    func previous() {
        let script = """

        tell application id "com.apple.Music"
            previous track
        end tell
        """

        _ = runAppleScript(script)

        scheduleRefresh()
    }

    // ========================================================
    // PLAY / PAUSE
    // ========================================================

    func togglePlayback() {
        let script = """

        tell application id "com.apple.Music"
            playpause
        end tell
        """

        _ = runAppleScript(script)

        scheduleRefresh()
    }

    // ========================================================
    // NEXT
    // ========================================================

    func next() {
        let script = """

        tell application id "com.apple.Music"
            next track
        end tell
        """

        _ = runAppleScript(script)

        scheduleRefresh()
    }

    // ========================================================
    // SEEK / SCRUB
    // ========================================================

    func seek(
        to time: Double
    ) {
        guard duration > 0 else {
            return
        }

        let clampedTime =
            min(
                max(
                    time,
                    0
                ),
                duration
            )

        let script = """

        tell application id "com.apple.Music"
            set player position to \(clampedTime)
        end tell
        """

        _ = runAppleScript(script)

        // Update UI immediately.
        currentTime =
            clampedTime

        // Then refresh from Music.
        scheduleRefresh()
    }

    // ========================================================
    // REFRESH
    // ========================================================

    private func scheduleRefresh() {
        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(300)
            )

            self.update()
        }
    }

    // ========================================================
    // APPLESCRIPT
    // ========================================================

    private func runAppleScript(
        _ source: String
    ) -> String? {
        var error:
            NSDictionary?

        guard let script =
            NSAppleScript(
                source: source
            )
        else {
            return nil
        }

        let result =
            script.executeAndReturnError(
                &error
            )

        if let error {
            print(
                "AppleScript error:",
                error
            )

            return nil
        }

        return result.stringValue
    }
}
