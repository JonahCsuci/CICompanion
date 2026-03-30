//
//  ViewHelper.swift
//  CICompanion
//
//  Created by Emma on 3/29/26.
//

import SwiftUI

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
        Text(title)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
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
    
    init (
        placeholder: String,
        text: Binding<String>
    ) {
        self.placeholder = placeholder
        self.text = text
    }
    
    var body: some View {
        TextField(placeholder, text: text)
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(14)
            .background(ViewHelper.fieldBgColor)
            .cornerRadius(10)
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
    public static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
}
