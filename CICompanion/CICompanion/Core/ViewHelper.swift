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
            VStack(spacing: 0) {
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
            VStack(alignment: .leading, spacing: 12) {
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
        TextField(placeholder, text: text, axis: .vertical)
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
    
    init (
        _ text: String,
        _ color: Color
    ) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: ViewHelper.textSize))
            .foregroundColor(color)
            .lineLimit(1)
    }
}

struct CIDropDown: View {
    var options: [String]
    var action: (Int) -> Void
    @State private var selected: Int = 0
    
    @State private var enabled: Bool = false
    
    init(
        options: [String],
        action: @escaping (Int) -> Void,
        selected: Int = 0
    ) {
        self.options = options
        self.action = action
        self.selected = selected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            Button(action: {
                enabled.toggle()
            }) {
                HStack {
                    CIText(options[selected], .white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(ViewHelper.padding)
                .background(ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
            }

            if enabled {
                ScrollView() {
                    ForEach(Array(options.enumerated()).filter { $0.offset != selected },
                            id: \.0) { index, value in
                        Button(action: {
                            action(index)
                            enabled = false
                            selected = index
                        }) {
                            HStack {
                                CIText(value, .white)
                                Spacer()
                            }
                            .padding(ViewHelper.padding)
                            .background(ViewHelper.fieldBgColor)
                            .cornerRadius(ViewHelper.componentRounding)
                        }
                    }
                }
            }
        }
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

class ViewHelper {
    public static let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    public static let fieldBgColor = Color(red: 0.12, green: 0.14, blue: 0.20)
    public static let textImportant = Color.white
    public static let text = Color.gray
    public static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    public static let accentGreen = Color(red: 0.2, green: 0.85, blue: 0.8)
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
}
