//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


struct OnboardingConsentMarkdownTestView: View {
    @Environment(OnboardingNavigationPath.self) private var path
    
    
    var body: some View {
        let data = """
        **Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor
        invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
        accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata
        sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing
        elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,
        sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita
        kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum
        dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut
        labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo
        duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem
        ipsum dolor sit amet.**

        # Test
        *Duis autem* ***vel eum iriure*** dolor in hendrerit in vulputate velit esse molestie consequat,
        vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio
        dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla
        facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh
        euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.

        Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis
        nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in
        vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at
        vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit
        augue duis dolore te feugait nulla facilisi.

        Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod
        mazim placerat facer
        
        Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis
        nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in
        vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at
        vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit
        augue duis dolore te feugait nulla facilisi.

        Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod
        mazim placerat facer

        Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis
        nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in
        vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at
        vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit
        augue duis dolore te feugait nulla facilisi.

        Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod
        mazim placerat facer
        """
        OnboardingConsentView(
            markdown: {
                Data(data.utf8)
            },
            action: {
                path.nextStep()
            },
            exportConfiguration: .init(paperSize: .dinA4, includingTimestamp: true)
        )
    }
}


#if DEBUG
struct OnboardingConsentMarkdownTestView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingStack(startAtStep: OnboardingConsentMarkdownTestView.self) {
            for onboardingView in OnboardingFlow.previewSimulatorViews {
                onboardingView
            }
        }
    }
}
#endif
