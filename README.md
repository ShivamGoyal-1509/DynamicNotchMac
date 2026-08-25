# # DynamicNotch

<p align="center">
  <strong>Turn your MacBook's notch into a Dynamic Island.</strong>
</p>

<p align="center">
  A native macOS utility that transforms the MacBook notch into an interactive area for media controls, charging status, AirDrop, and more.
</p>

---

## Features

### Apple Music

DynamicNotch integrates with Apple Music and displays media controls directly below the MacBook notch.

- Album artwork
- Song title and artist
- Play / Pause
- Previous track
- Next track
- Playback progress
- Interactive music scrubbing
- Automatically appears when music is playing
- Collapses when music is paused or stopped

The music interface appears when you hover over the notch while Apple Music is actively playing.

---

### Charging Status

Connecting or disconnecting your MacBook charger triggers a temporary charging animation.

DynamicNotch displays:

- Current battery percentage
- Charging status
- Battery progress indicator

The charging interface automatically disappears after a short delay.

---

### AirDrop

Drag files directly onto the DynamicNotch area to quickly initiate AirDrop.

1. Select one or more files in Finder.
2. Drag them toward DynamicNotch.
3. Drop them onto the AirDrop interface.
4. macOS opens the native AirDrop sharing experience.
5. Select the receiving device.

Multiple files are supported.

---

### Dynamic Interaction

DynamicNotch normally stays hidden within the physical MacBook notch.

Different activities temporarily expand the notch when needed.

```text
                    MacBook Notch
                         ↓
                  ███████████████
                  ███████████████

                         ↓

              ╭────────────────────╮
              │     DynamicNotch   │
              ╰────────────────────╯
```

The interface automatically returns to its collapsed state after temporary activities finish.

---

## Requirements

DynamicNotch is currently designed for:

- macOS
- MacBook models with a display notch
- Apple Silicon
- Apple Music for media integration

The current development version targets **macOS 27**.

> DynamicNotch is currently an experimental project and has primarily been tested on the developer's own MacBook.

---

## Architecture

The project is intentionally divided by functionality to make adding new DynamicNotch activities straightforward.

```text
DynamicNotch
│
├── App
│   ├── AppDelegate.swift
│   └── MyApp.swift
│
├── Managers
│   ├── AirDropManager.swift
│   ├── AppleMusicManager.swift
│   └── BatteryManager.swift
│
├── Models
│   └── IslandActivity.swift
│
├── Views
│   ├── AirDropView.swift
│   ├── ChargingView.swift
│   ├── MusicView.swift
│   └── NotchIslandView.swift
│
├── Windows
│   └── NotchWindowController.swift
│
└── DynamicNotch.icon
```

### Managers

Managers handle communication with macOS services and applications.

For example:

- `AppleMusicManager` communicates with Apple Music.
- `BatteryManager` monitors charging state.
- `AirDropManager` invokes the native macOS AirDrop sharing service.

### Views

Each feature has an independent SwiftUI interface.

This makes it possible to add future activities without placing all functionality inside one large view.

### IslandActivity

`IslandActivity` determines what DynamicNotch is currently displaying.

```swift
enum IslandActivity: Equatable {
    case idle
    case music
    case charging
    case airDrop
}
```

---

## Building From Source

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/DynamicNotch.git
cd DynamicNotch
```

### 2. Open the project

```bash
open DynamicNotch.xcodeproj
```

Or open the project directly from Xcode.

### 3. Configure signing

In Xcode:

```text
DynamicNotch
→ TARGETS
→ DynamicNotch
→ Signing & Capabilities
```

Enable:

```text
Automatically manage signing
```

and select your Apple development team.

### 4. Bundle Identifier

Use your own unique bundle identifier if necessary.

For example:

```text
com.yourname.DynamicNotch
```

### 5. Apple Events

DynamicNotch uses Apple Events to communicate with Apple Music.

Under:

```text
Signing & Capabilities
→ Hardened Runtime
```

enable:

```text
Apple Events
```

The app also requires an Apple Events usage description in its application configuration.

### 6. Build

Select:

```text
My Mac
```

as the run destination.

Then:

```text
⌘B
```

to build or:

```text
⌘R
```

to run.

---

## Permissions

### Apple Music

DynamicNotch uses Apple Events / AppleScript to obtain Apple Music playback information and control playback.

The first time this functionality is used, macOS may ask:

> "DynamicNotch would like to control Music"

Choose **Allow**.

The permission can later be managed under:

```text
System Settings
→ Privacy & Security
→ Automation
→ DynamicNotch
→ Music
```

### AirDrop

DynamicNotch uses the native macOS sharing service to initiate AirDrop.

Recipient discovery and file transfer continue to be handled by macOS.

---

## Installing a Local Build

Create a Release archive from Xcode:

```text
Product
→ Archive
```

Then export the resulting application and place:

```text
DynamicNotch.app
```

inside:

```text
/Applications
```

DynamicNotch can then run independently of Xcode.

---

## App Icon

The DynamicNotch application icon was created using Apple's **Icon Composer**.

The source icon is included as:

```text
DynamicNotch.icon
```

---

## Roadmap

Potential future features include:

- Display brightness
- AirPods connection status
- Improved battery animations
- Notifications
- Timers
- Microphone activity
- Camera activity
- Multi-display support
- Settings interface
- Launch at Login
- Per-feature enable/disable controls
- Additional DynamicNotch themes

---

## Project Status

DynamicNotch is currently **experimental / work in progress**.

APIs, UI behavior, project structure, and supported macOS versions may change as development continues.

The project currently targets a beta version of macOS, so behavior may change with future macOS and Xcode releases.

---

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you would like to contribute:

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Open a pull request.

---

## License

A license has not yet been selected for this project.

Until a license is added, the source code remains copyrighted by its author and should not be assumed to be available for redistribution or modification outside the permissions provided by GitHub.

---

## Disclaimer

DynamicNotch is an independent project and is not affiliated with, endorsed by, or sponsored by Apple Inc.

Apple, macOS, MacBook, AirDrop, and Apple Music are trademarks of Apple Inc.
