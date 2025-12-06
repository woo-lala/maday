import SwiftUI

struct AppButton<Label: View>: View {
    enum Style {
        case primary
        case secondary
        case neutral
        case destructive
    }

    let style: Style
    let action: () -> Void
    private let label: () -> Label

    init(style: Style = .primary, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.style = style
        self.action = action
        self.label = label
    }

    @ViewBuilder
    var body: some View {
        switch style {
        case .primary:
            button.primaryButtonStyle()
        case .secondary:
            button.secondaryButtonStyle()
        case .neutral:
            button.neutralButtonStyle()
        case .destructive:
            button.destructiveButtonStyle()
        }
    }

    private var button: some View {
        Button(action: action) {
            label()
                .font(AppFont.button())
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
        }
        .buttonStyle(.plain)
    }
}

struct AppTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String

    init(_ placeholder: LocalizedStringKey, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFont.body())
            .foregroundColor(AppColor.textPrimary)
            .inputFieldStyle()
    }
}

struct AppTextEditor: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String

    init(_ placeholder: LocalizedStringKey, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AppFont.bodyRegular())
                    .foregroundColor(AppColor.textSecondary.opacity(0.5))
                    .padding(.horizontal, AppSpacing.smallPlus)
                    .padding(.vertical, AppSpacing.smallPlus)
            }

            TextEditor(text: $text)
                .font(AppFont.bodyRegular())
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.smallPlus - AppSpacing.xSmall)
                .padding(.vertical, AppSpacing.smallPlus - AppSpacing.xSmall)
                .scrollContentBackground(.hidden)
                .background(AppColor.clear)
        }
        .multilineInputFieldStyle()
    }
}

struct AppSectionHeader: View {
    let title: String
    let indicatorColor: Color?

    init(title: String, indicatorColor: Color? = nil) {
        self.title = title
        self.indicatorColor = indicatorColor
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            if let indicatorColor {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: AppSpacing.small, height: AppSpacing.small)
            }
            Text(title)
                .font(AppFont.callout())
                .foregroundColor(AppColor.textSecondary)
        }
    }
}

struct AppBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(AppFont.badge())
            .padding(.horizontal, AppSpacing.smallPlus)
            .padding(.vertical, AppSpacing.small)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
            .foregroundColor(color)
    }
}

struct AppBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var title: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                dismiss()
            }
        } label: {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                if let title {
                    Text(title)
                        .font(AppFont.body())
                }
            }
            .foregroundColor(AppColor.textPrimary)
            .frame(height: AppMetrics.toolbarIconSize)
        }
        .buttonStyle(.plain)
    }
}
