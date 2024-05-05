//
//  ThemeEditorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import AppKit.NSColor

struct ThemeEditorView: View {
    
    @State var theme: Theme
    let isBundled: Bool
    let onUpdate: (Theme) -> Void
    
    @State private var isMetadataPresenting = false
    @State private var needsNotify = false
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .trailingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Text:", table: "ThemeEditor"),
                                selection: $theme.text.binding, supportsOpacity: false)
                    ColorPicker(String(localized: "Invisibles:", table: "ThemeEditor"),
                                selection: $theme.invisibles.binding)
                    SystemColorPicker(String(localized: "Cursor:", table: "ThemeEditor"),
                                      selection: $theme.insertionPoint,
                                      systemColor: Color(nsColor: .textInsertionPointColor))
                }.accessibilityElement(children: .contain)
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Background:", table: "ThemeEditor"),
                                selection: $theme.background.binding, supportsOpacity: false)
                    ColorPicker(String(localized: "Current Line:", table: "ThemeEditor"),
                                selection: $theme.lineHighlight.binding, supportsOpacity: false)
                    SystemColorPicker(String(localized: "Selection:", table: "ThemeEditor"),
                                      selection: $theme.selection,
                                      systemColor: Color(nsColor: .selectedTextBackgroundColor),
                                      supportsOpacity: false)
                }.accessibilityElement(children: .contain)
            }.accessibilityElement(children: .contain)
            
            GridRow {
                Text("Syntax", tableName: "ThemeEditor")
                    .fontWeight(.bold)
                    .gridCellColumns(2)
                    .gridCellAnchor(.leading)
                    .accessibilityAddTraits(.isHeader)
            }
            
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "\(SyntaxType.keywords.label):"),
                                selection: $theme.keywords.binding)
                    ColorPicker(String(localized: "\(SyntaxType.commands.label):"),
                                selection: $theme.commands.binding)
                    ColorPicker(String(localized: "\(SyntaxType.types.label):"),
                                selection: $theme.types.binding)
                    ColorPicker(String(localized: "\(SyntaxType.attributes.label):"),
                                selection: $theme.attributes.binding)
                    ColorPicker(String(localized: "\(SyntaxType.variables.label):"),
                                selection: $theme.variables.binding)
                }.accessibilityElement(children: .contain)
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "\(SyntaxType.values.label):"),
                                selection: $theme.values.binding)
                    ColorPicker(String(localized: "\(SyntaxType.numbers.label):"),
                                selection: $theme.numbers.binding)
                    ColorPicker(String(localized: "\(SyntaxType.strings.label):"),
                                selection: $theme.strings.binding)
                    ColorPicker(String(localized: "\(SyntaxType.characters.label):"),
                                selection: $theme.characters.binding)
                    ColorPicker(String(localized: "\(SyntaxType.commands.label):"),
                                selection: $theme.comments.binding)
                }.accessibilityElement(children: .contain)
            }.accessibilityElement(children: .contain)
            
            HStack {
                Spacer()
                Button(String(localized: "Show theme file information", table: "ThemeEditor"), systemImage: "info") {
                    self.isMetadataPresenting.toggle()
                }
                .symbolVariant(.circle)
                .labelStyle(.iconOnly)
                .popover(isPresented: self.$isMetadataPresenting, arrowEdge: .trailing) {
                    ThemeMetadataView(metadata: $theme.metadata ?? .init(), isEditable: !self.isBundled)
                }
                .buttonStyle(.borderless)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Theme Editor", table: "ThemeEditor"))
        .onChange(of: self.theme) { (_, newValue) in
            if self.isMetadataPresenting {
                // postpone notification to avoid closing the popover
                self.needsNotify = true
            } else {
                self.onUpdate(newValue)
            }
        }
        .onChange(of: self.isMetadataPresenting) { (_, newValue) in
            guard !newValue, self.needsNotify else { return }
            
            self.onUpdate(self.theme)
            self.needsNotify = false
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}


private struct SystemColorPicker: View {
    
    let label: String
    @Binding var selection: Theme.SystemDefaultStyle
    var systemColor: Color
    var supportsOpacity: Bool
    
    @Namespace private var accessibility
    
    
    init(_ label: String, selection: Binding<Theme.SystemDefaultStyle>, systemColor: Color, supportsOpacity: Bool = true) {
        
        self.label = label
        self._selection = selection
        self.systemColor = systemColor
        self.supportsOpacity = supportsOpacity
    }
    
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 4) {
            ColorPicker(selection: self.selection.usesSystemSetting ? .constant(self.systemColor) : $selection.binding, supportsOpacity: self.supportsOpacity) {
                Text(self.label)
                    .accessibilityLabeledPair(role: .label, id: "color", in: self.accessibility)
            }
            Toggle(String(localized: "Use system color", table: "ThemeEditor", comment: "toggle button label"), isOn: $selection.usesSystemSetting)
                .controlSize(.small)
                .accessibilityLabeledPair(role: .content, id: "color", in: self.accessibility)
        }.accessibilityElement(children: .contain)
    }
        
}


private struct ThemeMetadataView: View {
    
    @Binding var metadata: Theme.Metadata
    let isEditable: Bool
    
    @Namespace private var accessibility
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                self.itemView(String(localized: "Author:", table: "ThemeEditor"),
                              text: $metadata.author ?? "")
            }
            GridRow {
                self.itemView(String(localized: "URL:", table: "ThemeEditor"),
                              text: $metadata.distributionURL ?? "")
                LinkButton(url: self.metadata.distributionURL ?? "")
                    .foregroundStyle(.secondary)
            }
            GridRow {
                self.itemView(String(localized: "License:", table: "ThemeEditor"),
                              text: $metadata.license ?? "")
            }
            GridRow {
                self.itemView(String(localized: "Description:", table: "ThemeEditor"),
                              text: $metadata.description ?? "", lineLimit: 2...5)
            }
        }
        .padding(10)
        .controlSize(.small)
        .frame(width: 300, alignment: .leading)
    }
    
    
    @ViewBuilder private func itemView(_ title: String, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
        Text(title)
            .fontWeight(.bold)
            .gridColumnAlignment(.trailing)
            .accessibilityLabeledPair(role: .label, id: title, in: self.accessibility)
        
        if self.isEditable {
            TextField(title, text: text, prompt: Text("Not defined", tableName: "ThemeEditor", comment: "placeholder"), axis: .vertical)
                .lineLimit(lineLimit)
                .textFieldStyle(.plain)
                .accessibilityLabeledPair(role: .content, id: title, in: self.accessibility)
        } else {
            Text(text.wrappedValue)
                .textSelection(.enabled)
                .accessibilityLabeledPair(role: .content, id: title, in: self.accessibility)
        }
    }
}


private extension Theme.Style {
    
    var binding: Color {
        
        get { Color(nsColor: self.color) }
        set { self.color = NSColor(newValue).componentBased }
    }
}


private extension Theme.SystemDefaultStyle {
    
    var binding: Color {
        
        get { Color(nsColor: self.color) }
        set { self.color = NSColor(newValue).componentBased }
    }
}



// MARK: - Preview

#Preview(traits: .fixedLayout(width: 360, height: 280)) {
    ThemeEditorView(theme: try! ThemeManager.shared.setting(name: "Anura"), isBundled: false) { _ in }
}

#Preview("Metadata (editable)") {
    @State var metadata = Theme.Metadata(
        author: "Clarus",
        distributionURL: "https://coteditor.com"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: true)
}

#Preview("Metadata (fixed)") {
    @State var metadata = Theme.Metadata(
        author: "Claus"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: false)
}
