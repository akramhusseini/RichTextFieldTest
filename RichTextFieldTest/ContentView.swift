import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Modal rich-text HTML test") {
                    NavigationLink {
                        LegacyModalComposerView(direction: .leftToRight)
                    } label: {
                        RouteRow(
                            icon: "rectangle.bottomthird.inset.filled",
                            title: "Modal editor - LTR",
                            subtitle: "Bottom sheet rich-text editing"
                        )
                    }

                    NavigationLink {
                        LegacyModalComposerView(direction: .rightToLeft)
                    } label: {
                        RouteRow(
                            icon: "rectangle.bottomthird.inset.filled",
                            title: "Modal editor - RTL",
                            subtitle: "Arabic layout direction"
                        )
                    }
                }
            }
            .navigationTitle("RichTextFieldTest")
        }
    }
}

private struct RouteRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
