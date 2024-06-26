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


struct OnboardingConsentMarkdownTestView1: View {
    @Environment(OnboardingNavigationPath.self) private var path
    
    private var documentIdentifier = "FirstConsentDocument"

    
    var body: some View {
        OnboardingConsentView(
            markdown: {
                Data("This is the first *markdown* **example**".utf8)
            },
            action: {
                path.nextStep()
            },
            title: "First Consent",
            identifier: documentIdentifier,
            exportConfiguration: .init(paperSize: .dinA4, includingTimestamp: true)
        )
    }
}


#if DEBUG
struct OnboardingFirstConsentMarkdownTestView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingStack(startAtStep: OnboardingConsentMarkdownTestView1.self) {
            for onboardingView in OnboardingFlow.previewSimulatorViews {
                onboardingView
            }
        }
    }
}
#endif
