import SwiftUI

struct MeetingSchedulerView: View {
    var body: some View {
        CIView() {
            CIHeader {
                CIPageTitle("Schedule")
            }
            
            ScrollView(.vertical, showsIndicators: false) {
            }
        }
    }
}

#Preview {
    MeetingSchedulerView()
}
