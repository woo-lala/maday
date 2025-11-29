import SwiftUI

struct ContactSupportView: View {
    @State private var selectedCategory: SupportCategory = .general
    @State private var subject = ""
    @State private var message = ""
    @State private var includeDeviceInfo = true
    @State private var showSuccessAlert = false
    @State private var isSending = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerSection
                quickHelpSection
                contactFormSection
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Message Sent!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We'll get back to you as soon as possible.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("How can we help?")
                .font(AppFont.title())
                .foregroundColor(AppColor.textPrimary)
            
            Text("We're here to help you get the most out of MaDay.")
                .font(AppFont.body())
                .foregroundColor(AppColor.textSecondary)
        }
    }
    
    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Quick Help")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.small) {
                QuickHelpButton(
                    icon: "book.fill",
                    title: "Help Center",
                    description: "Browse common questions and guides"
                )
                
                QuickHelpButton(
                    icon: "ant.fill",
                    title: "Report a Bug",
                    description: "Let us know if something isn't working"
                )
                
                QuickHelpButton(
                    icon: "lightbulb.fill",
                    title: "Feature Request",
                    description: "Suggest new features and improvements"
                )
            }
        }
    }
    
    private var contactFormSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Send us a message")
                .font(AppFont.headline())
                .foregroundColor(AppColor.textPrimary)
            
            VStack(spacing: AppSpacing.medium) {
                // Category Picker
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Category")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                    
                    Menu {
                        ForEach(SupportCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(category.rawValue)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory.rawValue)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        .padding(AppSpacing.medium)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.standard)
                    }
                }
                
                // Subject
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Subject")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                    
                    TextField("Brief description of your issue", text: $subject)
                        .font(AppFont.body())
                        .padding(AppSpacing.medium)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.standard)
                }
                
                // Message
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Message")
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                    
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Describe your issue or question in detail...")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textSecondary.opacity(0.5))
                                .padding(AppSpacing.medium)
                        }
                        
                        TextEditor(text: $message)
                            .font(AppFont.body())
                            .padding(AppSpacing.small)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                    }
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.standard)
                }
                
                // Include Device Info
                Toggle(isOn: $includeDeviceInfo) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include device information")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.textPrimary)
                        
                        Text("Helps us diagnose technical issues")
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: AppColor.primary))
                .padding(AppSpacing.medium)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.standard)
                
                // Send Button
                Button {
                    sendMessage()
                } label: {
                    HStack {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send Message")
                        }
                    }
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .fill(canSend ? AppColor.primary : AppColor.border.opacity(0.3))
                    )
                    .foregroundColor(.white)
                }
                .disabled(!canSend || isSending)
            }
            .padding(AppSpacing.medium)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
    
    private var canSend: Bool {
        !subject.isEmpty && !message.isEmpty
    }
    
    private func sendMessage() {
        isSending = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            showSuccessAlert = true
            
            // Clear form
            subject = ""
            message = ""
            selectedCategory = .general
        }
    }
}

enum SupportCategory: String, CaseIterable {
    case general = "General Question"
    case technical = "Technical Issue"
    case bug = "Bug Report"
    case feature = "Feature Request"
    case account = "Account & Billing"
    case privacy = "Privacy & Data"
}

private struct QuickHelpButton: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        Button {
            // Navigate to respective section
        } label: {
            HStack(spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.body())
                        .fontWeight(.medium)
                        .foregroundColor(AppColor.textPrimary)
                    
                    Text(description)
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.textSecondary.opacity(0.5))
            }
            .padding(AppSpacing.medium)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.standard)
        }
    }
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
