# DynamicNotch

<p align="center">
  <strong>Turn your MacBook's notch into a Dynamic Island.</strong>
</p>

<p align="center">
  A native macOS utility that transforms the MacBook notch into an interactive area for media controls, charging status, AirDrop, and more.
</p>

---

## Features

### Apple Music

DynamicNotch integrates with Apple Music and provides media controls directly from the MacBook notch.

- Album artwork
- Song title and artist
- Play / Pause
- Previous track
- Next track
- Playback progress
- Interactive music scrubbing
- Live playback position
- Automatically available while music is playing
- Collapses when music is paused or stopped

While Apple Music is actively playing, hovering over the MacBook notch expands DynamicNotch into the music player.

The music interface uses the native macOS **Liquid Glass** system through SwiftUI and adapts to the system Liquid Glass appearance.

---

### Liquid Glass

DynamicNotch uses Apple's native SwiftUI Liquid Glass APIs for supported interfaces.

The expanded music interface combines:

- Native Liquid Glass
- Interactive glass behavior
- System-controlled glass appearance
- Black-to-glass visual transition
- Rounded continuous geometry
- Animated expansion and contraction

The upper portion visually connects to the physical black MacBook notch while transitioning into Liquid Glass toward the lower portion of the interface.

DynamicNotch respects the system Liquid Glass appearance provided by macOS.

> Liquid Glass rendering and behavior may change while DynamicNotch targets beta versions of macOS.

---

### Charging Status

Connecting or disconnecting power triggers a temporary charging activity.

Unlike the larger music interface, the charging activity remains within the height of the physical MacBook notch and expands **horizontally only**.

It displays:

- Current battery percentage
- Battery indicator
- Charging indicator
- Green charging bolt while actively charging
- Animated horizontal expansion and contraction

The charging interface intentionally uses a **pure black background** rather than Liquid Glass so that it appears as a natural extension of the physical MacBook notch.

After a short delay, the expanded charging area contracts back into the notch.

---

### AirDrop

Drag files directly onto DynamicNotch to quickly initiate AirDrop.

1. Select one or more files in Finder.
2. Drag them toward the MacBook notch.
3. Drop them onto DynamicNotch.
4. macOS opens the native AirDrop sharing experience.
5. Select the receiving device.

Multiple files are supported.

DynamicNotch initiates the sharing flow while device discovery and file transfer continue to be handled by macOS.

---

### Dynamic Interaction

DynamicNotch normally remains visually integrated with the physical MacBook notch.

Activities expand it only when needed.

```text
                    MacBook Notch
                         ↓
                  ███████████████
                  ███████████████

                         ↓

              ╭────────────────────╮
              │    DynamicNotch    │
              ╰────────────────────╯
```

Different activities can use different expansion behaviors.

For example:

```text
Music
    ↓
expands horizontally + vertically
    ↓
Liquid Glass media player


Charging
    ↓
expands horizontally only
    ↓
pure black charging status


AirDrop
    ↓
expands for file interaction
    ↓
native macOS sharing flow
```

After temporary activities finish, DynamicNotch automatically returns to its collapsed state.

---

## Requirements

DynamicNotch is currently designed for:

- macOS
- MacBook models with a display notch
- Apple Silicon
- Apple Music for media integration
- A recent Xcode version capable of building the targeted macOS SDK

The current development version targets **macOS 27**.

> DynamicNotch is experimental software and has primarily been tested on the developer's own MacBook. Behavior on different MacBook models, displays, macOS versions, or beta releases may vary.

---

## Architecture

DynamicNotch is divided by functionality so that additional notch activities can be added without putting all behavior into one large view.

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
│   ├── GlassNotchBackground.swift
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

- `AppleMusicManager` communicates with Apple Music and manages playback information and controls.
- `BatteryManager` monitors battery level and charging state.
- `AirDropManager` invokes the native macOS AirDrop sharing service.

### Views

Each activity has its own SwiftUI interface.

- `MusicView` renders Apple Music information, controls, and interactive scrubbing.
- `ChargingView` renders the compact charging interface.
- `AirDropView` handles the AirDrop drop target and related UI.
- `GlassNotchBackground` renders the Liquid Glass background and black-to-glass transition.
- `NotchIslandView` coordinates activity state, geometry, animation, and transitions between features.

This separation makes it easier to add new activities without placing all functionality into a single view.

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

Each activity can define its own dimensions, presentation, animation, and visual treatment.

---

## Liquid Glass Implementation

DynamicNotch uses SwiftUI's native Liquid Glass APIs on supported macOS versions.

The glass surface is created using:

```swift
.glassEffect(
    .regular.interactive(),
    in: shape
)
```

The music interface uses Liquid Glass as its base surface while a custom black treatment visually connects the expanded interface to the physical MacBook notch.

Charging intentionally does **not** use Liquid Glass and instead uses a pure black surface.

Because Liquid Glass is controlled partly by macOS, its appearance may vary depending on:

- macOS version
- System appearance
- Liquid Glass system settings
- Content behind the interface
- Future changes to Apple's APIs

---

## Building From Source

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/DynamicNotch.git
cd DynamicNotch
```

Replace `YOUR_USERNAME` with the GitHub account hosting your fork or repository.

### 2. Open the project

```bash
open DynamicNotch.xcodeproj
```

Or open the project directly from Xcode.

### 3. Configure Signing

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

The application also requires the appropriate Apple Events usage description in its application configuration.

### 6. Build

Select:

```text
My Mac
```

as the run destination.

Then use:

```text
⌘B
```

to build, or:

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

Recipient discovery and file transfer remain handled by macOS.

DynamicNotch does **not** implement its own AirDrop protocol or file-transfer system.

---

## Installing a Local Build

Create a Release archive from Xcode:

```text
Product
→ Archive
```

Export the resulting application and place:

```text
DynamicNotch.app
```

inside:

```text
/Applications
```

DynamicNotch can then run independently of Xcode.

Depending on your signing configuration, macOS security settings may affect running locally exported builds.

---

## App Icon

The DynamicNotch application icon was created using Apple's **Icon Composer**.

The source icon is included in the project as:

```text
DynamicNotch.icon
```

---

## Roadmap

Potential future features include:

- Display brightness
- AirPods connection status
- Additional battery and charging animations
- Notifications
- Timers
- Microphone activity
- Camera activity
- Multi-display support
- Settings interface
- Launch at Login
- Per-feature enable/disable controls
- Additional DynamicNotch themes
- Additional media applications
- Improved Liquid Glass transitions
- More activity-specific animations

---

## Project Status

DynamicNotch is currently **experimental / work in progress**.

APIs, UI behavior, animation, project structure, and supported macOS versions may change as development continues.

The project currently targets a beta version of macOS and uses newer system UI APIs, including Liquid Glass. Their behavior may change with future macOS and Xcode releases.

---

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you would like to contribute:

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Test the changes on a notched MacBook when possible.
5. Open a pull request.

When reporting UI issues, including the MacBook model, macOS version, and a screenshot is especially helpful because notch geometry and system visual effects may differ between devices and OS releases.

---

## License

A license has not yet been selected for this project.

Until a license is added, the source code remains copyrighted by its author and should not be assumed to be available for redistribution, modification, or reuse beyond the permissions provided by applicable law and GitHub's Terms of Service.

If you intend for DynamicNotch to be open source, consider adding a standard license such as MIT, Apache-2.0, or GPL before accepting external contributions.

---

## Disclaimer

DynamicNotch is an independent project and is not affiliated with, endorsed by, or sponsored by Apple Inc.

Apple, macOS, MacBook, AirDrop, Apple Music, SwiftUI, and related names and trademarks are the property of Apple Inc.

"Dynamic Island" is an Apple product feature and trademark. DynamicNotch is an independent macOS project inspired by the concept and is not an official implementation of Apple's Dynamic Island.
