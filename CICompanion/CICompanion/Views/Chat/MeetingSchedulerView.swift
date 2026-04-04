import SwiftUI

struct MeetingSchedulerView: View {
    var body: some View {
        CIView(heading: {
            CIHeader() {
                CIPageTitle("hi")
            }
        }, content: {
            CIScrollView {
                let todayBlocks = []
                if todayBlocks.isEmpty {
                    CIText("No classes today", .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
        })
    }
}

#Preview {
    MeetingSchedulerView()
}
