import SwiftUI

struct GlassNotchBackground: View {

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    // 0 = collapsed
    // 1 = fully expanded
    let progress: CGFloat


    var body: some View {

        ZStack {

            // =====================================================
            // NATIVE ADAPTIVE LIQUID GLASS BASE
            // =====================================================
            //
            // Keep .regular so the macOS Liquid Glass slider
            // continues to affect this surface.
            //

            Color.clear
                .frame(
                    width: width,
                    height: height
                )
                .glassEffect(
                    .regular
                        .interactive(),

                    in:
                        islandShape(
                            radius: cornerRadius
                        )
                )


            // =====================================================
            // MAIN BLACK -> GLASS MELT
            // =====================================================

            islandShape(
                radius: cornerRadius
            )
            .fill(
                verticalMelt
            )


            // =====================================================
            // CENTER DEPTH
            // =====================================================

            islandShape(
                radius: cornerRadius
            )
            .fill(
                centerDepth
            )
        }

        .frame(
            width: width,
            height: height
        )

        .clipShape(
            islandShape(
                radius: cornerRadius
            )
        )
    }


    // =========================================================
    // NORMALIZED PROGRESS
    // =========================================================

    private var p: Double {

        Double(
            min(
                max(
                    progress,
                    0
                ),
                1
            )
        )
    }


    // =========================================================
    // SHAPE
    // =========================================================

    private func islandShape(
        radius: CGFloat
    ) -> UnevenRoundedRectangle {

        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: radius,
            bottomTrailingRadius: radius,
            topTrailingRadius: 0,
            style: .continuous
        )
    }


    // =========================================================
    // MAIN VERTICAL MELT
    // =========================================================

    private var verticalMelt:
        LinearGradient {

        // =====================================================
        // FIXED, ORDERED STOP POSITIONS
        // =====================================================
        //
        // These NEVER change order.
        //
        // That avoids:
        //
        // "Gradient stop locations must be ordered."
        //

        let pureBlackEnd:
            CGFloat = 0.30

        let veryDarkEnd:
            CGFloat = 0.38

        let darkMiddle:
            CGFloat = 0.44

        let middleMelt:
            CGFloat = 0.49

        let lightMelt:
            CGFloat = 0.53

        let almostClear:
            CGFloat = 0.57

        let fullGlassStart:
            CGFloat = 0.60


        // =====================================================
        // ANIMATED OPACITIES
        // =====================================================
        //
        // Instead of moving the stops around, we animate how
        // opaque each black stage is.
        //
        // This keeps the transition smooth and avoids warnings.
        //

        let veryDarkOpacity =
            1.0
            -
            p * 0.05


        let darkOpacity =
            1.0
            -
            p * 0.30


        let middleOpacity =
            1.0
            -
            p * 0.68


        let lightOpacity =
            1.0
            -
            p * 0.96


        let almostClearOpacity =
            1.0
            -
            p


        let bottomOpacity =
            1.0
            -
            p


        return LinearGradient(

            stops: [

                // =============================================
                // TRUE BLACK
                // =============================================

                .init(
                    color: .black,
                    location: 0.00
                ),

                .init(
                    color: .black,
                    location: pureBlackEnd
                ),


                // =============================================
                // VERY DARK
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            veryDarkOpacity
                        ),
                    location:
                        veryDarkEnd
                ),


                // =============================================
                // DARK
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            darkOpacity
                        ),
                    location:
                        darkMiddle
                ),


                // =============================================
                // MID MELT
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            middleOpacity
                        ),
                    location:
                        middleMelt
                ),


                // =============================================
                // LIGHT MELT
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            lightOpacity
                        ),
                    location:
                        lightMelt
                ),


                // =============================================
                // ALMOST CLEAR
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            almostClearOpacity
                        ),
                    location:
                        almostClear
                ),


                // =============================================
                // BLACK REACHES ZERO
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            bottomOpacity
                        ),
                    location:
                        fullGlassStart
                ),


                // =============================================
                // PURE NATIVE LIQUID GLASS
                // =============================================

                .init(
                    color: .clear,
                    location: 0.62
                ),

                .init(
                    color: .clear,
                    location: 1.00
                )
            ],

            startPoint: .top,
            endPoint: .bottom
        )
    }


    // =========================================================
    // CENTER DEPTH
    // =========================================================
    //
    // Adds extra depth directly underneath the hardware notch
    // without darkening the lower clear-glass region.
    //

    private var centerDepth:
        RadialGradient {

        let inverse =
            1.0
            -
            p


        let coreOpacity =
            0.52
            +
            inverse * 0.38


        let secondaryOpacity =
            0.10
            +
            inverse * 0.28


        return RadialGradient(

            stops: [

                // =============================================
                // DEEP CENTER
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            coreOpacity
                        ),
                    location:
                        0.00
                ),


                // =============================================
                // FAST FALL-OFF
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            secondaryOpacity
                        ),
                    location:
                        0.18
                ),


                // =============================================
                // VERY SMALL REMAINDER
                // =============================================

                .init(
                    color:
                        .black.opacity(
                            0.012
                            +
                            inverse * 0.06
                        ),
                    location:
                        0.30
                ),


                // =============================================
                // COMPLETELY GONE
                // =============================================

                .init(
                    color: .clear,
                    location: 0.40
                ),

                .init(
                    color: .clear,
                    location: 1.00
                )
            ],

            center:
                UnitPoint(
                    x: 0.50,
                    y: -0.10
                ),

            startRadius:
                0,

            endRadius:
                max(
                    width * 0.31,
                    height * 0.52
                )
        )
    }
}
