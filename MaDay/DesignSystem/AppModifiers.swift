import SwiftUI

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .foregroundColor(AppColor.white)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .fill(AppColor.primary)
            )
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .foregroundColor(AppColor.white)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .fill(AppColor.secondaryStrong)
            )
    }
}

struct NeutralButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .foregroundColor(AppColor.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .fill(AppColor.neutralButton)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .stroke(AppColor.textSecondary.opacity(0.35), lineWidth: 1)
            )
    }
}

struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .fill(AppColor.surface)
                    .shadow(color: AppShadow.card, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
            )
    }
}

struct AppBarTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.title())
            .foregroundColor(AppColor.textPrimary)
    }
}

struct SectionTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.headline())
            .foregroundColor(AppColor.textPrimary)
    }
}

struct BodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFont.body())
            .foregroundColor(AppColor.textSecondary)
    }
}

struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.smallPlus)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .stroke(AppColor.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                            .fill(AppColor.surface)
                    )
            )
    }
}

struct MultilineInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.smallPlus)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                    .stroke(AppColor.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.standard, style: .continuous)
                            .fill(AppColor.surface)
                    )
            )
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonModifier())
    }

    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }

    func neutralButtonStyle() -> some View {
        modifier(NeutralButtonModifier())
    }

    func sectionCardStyle() -> some View {
        modifier(SectionCardModifier())
    }

    func appBarTitleStyle() -> some View {
        modifier(AppBarTitleModifier())
    }

    func sectionTitleStyle() -> some View {
        modifier(SectionTitleModifier())
    }

    func bodyTextStyle() -> some View {
        modifier(BodyTextModifier())
    }

    func inputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }

    func multilineInputFieldStyle() -> some View {
        modifier(MultilineInputModifier())
    }
}
