//
//  ViewHelper.swift
//  CICompanion
//
//  Created by Emma on 3/29/26.
//

import SwiftUI

// CIView: Base view: should be used on every page!
// CIHeader: A heading wrapper, put things you want to be always on the top in here
// CIPageTitle: Formatting for a page title. Put this in either CIHeader or CIScrollable depending on your preference
// CILoadingPage: If something is loading, just put this page until it's done
// CIErrorPage: If there's an error, put this page up
// CIScrollView: A formatted scrollable view. Use this when the page should be scrollable, not for small things that should be scrollable like dropdown menus
// CIDelete: A delete button, dunno why I put this here tbh
// CIItem: An item on a page (use this for forms, it'll format it with a label and then put the contents under that table
// CITextField: A text field for a form
// CICheckBoxToggle: A toggleable button formatted with a checkbox
// CISliderToggle: A toggleable button formatted with a slider
// CITextButton: An unformatted button that displays just some text
// CIText: Text. Use this often for free formatting.
// CIDropDown: Dropdown menu
// CISwipeable: A swipeable button that does something when you swipe
// ViewHelper: Global variables changeable to edit the style of ALL PAGES

struct CIView<Heading: View, Content: View>: View {
    let heading: Heading
    let content: Content
    
    init(
        @ViewBuilder heading: () -> Heading,
        @ViewBuilder content: () -> Content
    ) {
        self.heading = heading()
        self.content = content()
    }
    
    init(
        @ViewBuilder content: () -> Content
    ) where Heading == EmptyView {
        self.heading = EmptyView()
        self.content = content()
    }
    
    
    var body: some View {
        ZStack {
            ViewHelper.bgColor.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                heading
                content
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }
}

struct CIHeader<Content: View>: View {
    let content: Content
    
    init(
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CIPageTitle: View {
    let title: String
    
    init (
        _ title: String
    ) {
        self.title = title;
    }
    
    var body: some View {
        HStack() {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct CILoadingPage: View {
    var body: some View {
        ProgressView()
            .tint(.white)
            .padding(.top, 40)
    }
}

struct CIErrorMessage: View {
    let errorMessage: String
    
    init (
        errorMessage: String
    ) {
        self.errorMessage = errorMessage;
    }
    
    var body: some View {
        Text(errorMessage)
            .foregroundColor(.red)
            .padding(.top, 40)
    }
}

struct CIScrollView<Content: View>: View {
    let content: Content
    
    init(
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ViewHelper.spacing * 2) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

struct CIDelete: View {
    var onDelete: () -> Void
    
    init(
        onDelete: @escaping () -> Void
    ) {
        self.onDelete = onDelete
    }
    
    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "trash.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .background(Color.red)
                .frame(width: 50, height: 36)
                .cornerRadius(8)
        }
        .tint(.red)
    }
}

struct CIItem<Content: View>: View {
    let name: String
    let content: Content
    
    init (
        name: String,
        @ViewBuilder content: () -> Content
    ) {
        self.name = name
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            content
        }
    }
}

struct CITextField: View {
    let placeholder: String
    let text: Binding<String>
    let lines: ClosedRange<Int>
    
    init (
        placeholder: String,
        text: Binding<String>,
        lines: Int
    ) {
        self.placeholder = placeholder
        self.text = text
        self.lines = lines...lines
    }
    
    init (
        placeholder: String,
        text: Binding<String>,
        lines: ClosedRange<Int>
    ) {
        self.placeholder = placeholder
        self.text = text
        self.lines = lines
    }
    
    var body: some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(ViewHelper.text), axis: .vertical)
            .font(.system(size: ViewHelper.textSize))
            .foregroundColor(.white)
            .lineLimit(lines)
            .padding(ViewHelper.padding)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
    }
}

struct CICheckBoxToggle: View {
    var label: String
    var toggleBool: Bool
    var toggleAction: () -> Void
    
    init (
        label: String,
        toggleBool: Bool,
        toggleAction: @escaping () -> Void
    ) {
        self.label = label
        self.toggleBool = toggleBool
        self.toggleAction = toggleAction
    }
    
    var body: some View {
        Button(action: {
            toggleAction()
        }) {
            HStack(spacing: ViewHelper.spacing) {
                Image(systemName: toggleBool ? "checkmark.square.fill" : "square")
                    .font(.system(size: ViewHelper.bigIconSize))
                    .foregroundColor(toggleBool ? ViewHelper.accentBlue : ViewHelper.text)
                
                Text(label)
                    .font(.system(size: ViewHelper.textSize))
                    .foregroundColor(ViewHelper.textImportant)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CISliderToggle: View {
    var label: String
    var toggleBool: Binding<Bool>
    var toggleAction: () -> Void
    
    init (
        label: String,
        toggleBool: Binding<Bool>,
        toggleAction: @escaping () -> Void
    ) {
        self.label = label
        self.toggleBool = toggleBool
        self.toggleAction = toggleAction
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: ViewHelper.textSize, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: toggleBool)
                .onSubmit({
                    toggleAction()
                })
                .tint(ViewHelper.accentGreen)
        }
    }
}

struct CITextButton: View {
    var text: String
    var action: () -> Void
    
    init (
        text: String,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: ViewHelper.textSize, weight: .medium))
                .foregroundColor(ViewHelper.accentBlue)
        }
    }
}

struct CIText: View {
    var text: String
    var color: Color
    var fontSize: CGFloat
    var fontWeight: Font.Weight
    
    init (
        _ text: String,
        color: Color = ViewHelper.textImportant,
        fontSize: CGFloat = ViewHelper.textSize,
        fontWeight: Font.Weight = .regular
    ) {
        self.text = text
        self.color = color
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(color)
            .lineLimit(1)
    }
}

struct CIDateField: View {
    @Binding var date: Date
    @State private var showPicker = false

    private var formattedDate: String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack {
                CIText(formattedDate, color: .white)
                    .font(Font.system(size: ViewHelper.smallTextSize))
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
        .sheet(isPresented: $showPicker) {
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}

struct CITimeField: View {
    @Binding var time: Date
    @State private var showPicker = false
    
    private var formattedDate: String {
        time.formatted(.dateTime.hour().minute())
    }
    
    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack {
                CIText(formattedDate, color: .white)
                    .font(Font.system(size: ViewHelper.smallTextSize))
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
        .sheet(isPresented: $showPicker) {
            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}

struct CIDropDown: View {
    var options: [String]
    @State private var selectedItem: String

    init(options: [String], selected: String) {
        self.options = options
        _selectedItem = State(initialValue: selected)
    }

    var body: some View {
        Menu(content: {
            ForEach(options, id: \.self) { option in
                Button {
                    selectedItem = option
                } label: {
                    HStack {
                        Text(option)

                        Spacer()

                        if option == selectedItem {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
        }, label: {
            HStack {
                CIText(selectedItem, color: .white)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
            }
            .padding(ViewHelper.padding)
            .frame(maxWidth: .infinity)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        })
        .preferredColorScheme(.dark)
    }
}

struct CISwipeable<Content: View, SwipeOptions: View>: View {
    let swipeOptions: SwipeOptions
    let content: Content
    
    init(
        @ViewBuilder swipeOptions: () -> SwipeOptions,
        @ViewBuilder content: () -> Content
    ) {
        self.swipeOptions = swipeOptions()
        self.content = content()
    }
    
    var body: some View {
        content
            .swipeActions(edge: .trailing) {
                swipeOptions
            }
    }
    
}

struct CIDropDownCard<Before: View, ExpandedContent: View>: View {
    let title: String
    let subtitle: String
    let before : Before
    let expandedContent: ExpandedContent
    
    let color: Color
    let onOpen: () -> Void
    
    let accentWidth: CGFloat = 3
    
    @State var isExpanded : Bool = false
    
    init(
        title: String,
        subtitle: String,
        @ViewBuilder before: () -> Before = { EmptyView() },
        @ViewBuilder expandedContent: () -> ExpandedContent = { EmptyView() },
        color : Color = ViewHelper.fieldBgColor,
        onOpen : @escaping () -> Void = {}
        
    ) {
        self.title = title
        self.subtitle = subtitle
        self.before = before()
        self.expandedContent = expandedContent()
        self.color = color
        self.onOpen = onOpen
    }
    
    var body : some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(width: 16)
                    .padding(.top, 5)
                    .padding(.trailing, 6)
                
                before
                
                RoundedRectangle(cornerRadius: ViewHelper.componentRounding / 4)
                    .fill(color)
                    .frame(width: accentWidth)
                    .padding(.vertical, 2)
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: ViewHelper.spacing / 2) {
                    CIText(title, color: color)
                        .font(.system(size: ViewHelper.textSize * 1.5, weight: .bold))
                    
                    HStack(spacing: ViewHelper.spacing) {
                        CIText(subtitle, color: ViewHelper.text)
                            .font(.system(size: ViewHelper.smallTextSize))
                    }
                }
                
                Spacer()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onOpen()
                    isExpanded = !isExpanded
                }
            }
            
            if isExpanded {
                Divider()
                expandedContent
            }
        }
        .padding(ViewHelper.smallPadding)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

class ViewHelper {
    public static let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    public static let fieldBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    public static let textImportant = Color.white
    public static let text = Color.gray
    public static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    public static let accentGreen = Color(red: 0.2, green: 0.85, blue: 0.8)
    public static let accentBigGreen = Color(red: 0.2, green: 0.85, blue: 0.2)
    public static let accentRed = Color(red: 0.9, green: 0.325, blue: 0.325)
    public static let currentUserColor = Color(red: 0.329, green: 0.431, blue: 1)
    public static let otherUserColor = Color(red: 0.769, green: 0.306, blue: 0.984)
    public static let componentRounding = 10.0
    public static let iconSize = 12.0
    public static let bigIconSize = 20.0
    public static let tinyPadding = 6.0
    public static let smallPadding = 8.0
    public static let padding = 14.0
    public static let smallTextSize = 12.0
    public static let textSize = 16.0
    public static let titleTextSize = 28.0
    public static let spacing = 8.0
    public static let borderWidth = 1.5
    public static let opacity = 0.22
}
