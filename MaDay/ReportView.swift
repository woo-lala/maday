import SwiftUI

struct ReportView: View {
    @State private var selectedDateRange: String = "Aug 14 - Aug 20"
    @State private var selectedDay: String = "Mon"

    private let categoryColors: [String: Color] = [
        "Work": AppColor.work,
        "Study": AppColor.learning,
        "Leisure": AppColor.youtube,
        "Health": AppColor.fitness,
        "Personal": AppColor.personal
    ]

    private let weeklyTimelineData: [DayTimeline] = DayTimeline.sample
    private let categoryRatioData: [CategoryRatio] = CategoryRatio.sample
    private let weeklyDistributionData: [DayDistribution] = DayDistribution.sample
    private let dailyActivitiesData: [DailyTask] = DailyTask.sample

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                header
                weeklyTimeline
                categoryRatio
                weeklyDistribution
                dailyActivities
            }
            .padding(.horizontal, AppSpacing.mediumPlus)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Weekly Report")
                .font(AppFont.largeTitle())
                .foregroundColor(AppColor.textPrimary)

            HStack {
                Button(action: moveToPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                }
                Spacer()
                Button(action: openCalendar) {
                    Text(selectedDateRange)
                        .font(AppFont.headline())
                        .foregroundColor(AppColor.textPrimary)
                }
                Spacer()
                Button(action: moveToNextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Weekly Performance Overview
    private var weeklyTimeline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Weekly Performance Overview")
                .sectionTitleStyle()

            GeometryReader { geo in
                let chartHeight: CGFloat = 240
                let axisWidth: CGFloat = 40
                let gap: CGFloat = AppSpacing.xSmall
                let barWidth = (geo.size.width - axisWidth - gap * 6) / 7

                VStack(spacing: AppSpacing.small) {
                    HStack(alignment: .top, spacing: gap) {
                        ZStack(alignment: .topLeading) {
                            ForEach(Array(timeTicks.enumerated()), id: \.offset) { _, tick in
                                let y = chartHeight * CGFloat(tick.position)
                                Rectangle()
                                    .fill(AppColor.border)
                                    .frame(height: 1)
                                    .opacity(0.4)
                                    .offset(y: y)

                                Text(tick.label)
                                    .font(AppFont.caption())
                                    .foregroundColor(AppColor.textSecondary)
                                    .offset(x: 0, y: y - 6)
                            }
                        }
                        .frame(width: axisWidth, height: chartHeight, alignment: .topLeading)

                        HStack(alignment: .top, spacing: gap) {
                            ForEach(weeklyTimelineData) { day in
                                ZStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: AppRadius.button)
                                        .fill(AppColor.surface)
                                        .frame(width: barWidth, height: chartHeight)

                                    ZStack(alignment: .top) {
                                        ForEach(day.blocks) { block in
                                            RoundedRectangle(cornerRadius: AppRadius.button)
                                                .fill(categoryColors[block.category] ?? AppColor.primary)
                                                .frame(width: barWidth, height: CGFloat(block.durationRatio) * chartHeight)
                                                .offset(y: CGFloat(block.startRatio) * chartHeight)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: chartHeight)
                    }

                    HStack(alignment: .center, spacing: gap) {
                        Spacer().frame(width: axisWidth)
                        ForEach(weeklyTimelineData) { day in
                            Text(day.day)
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.textSecondary)
                                .frame(width: barWidth)
                        }
                    }
                }
            }
            .frame(height: 280)
        }
    }

    private func timeGrid(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: height/4) {
            ForEach(["00:00","06:00","12:00","18:00","24:00"], id: \.self) { label in
                HStack(spacing: AppSpacing.small) {
                    Text(label)
                        .font(AppFont.caption())
                        .foregroundColor(AppColor.textSecondary)
                    Rectangle()
                        .fill(AppColor.border)
                        .frame(height: 1)
                        .opacity(0.4)
                }
            }
        }
    }

    // MARK: Category Ratio
    private var categoryRatio: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Weekly Category Ratio")
                .sectionTitleStyle()

            HStack(alignment: .center, spacing: AppSpacing.medium) {
                DonutChart(data: categoryRatioData, colors: categoryColors)
                    .frame(width: 180, height: 180)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    ForEach(categoryRatioData) { item in
                        HStack(spacing: AppSpacing.small) {
                            Circle()
                                .fill(categoryColors[item.category] ?? AppColor.primary)
                                .frame(width: 10, height: 10)
                            Text("\(item.category) • \(Int(item.percentage))%")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Weekly Distribution
    private var weeklyDistribution: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Weekly Distribution")
                .sectionTitleStyle()

            Text("Click a day to view daily details.")
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)

            HStack(alignment: .bottom, spacing: AppSpacing.small) {
                ForEach(weeklyDistributionData) { item in
                    let isSelected = item.day == selectedDay
                    VStack {
                        Rectangle()
                            .fill(isSelected ? AppColor.primaryStrong : AppColor.primary.opacity(0.8))
                            .frame(width: 28, height: CGFloat(item.totalHours) * 8)
                            .cornerRadius(AppRadius.button)
                            .shadow(color: isSelected ? AppColor.primary.opacity(0.3) : .clear, radius: 3, x: 0, y: 2)
                            .onTapGesture { selectedDay = item.day }
                        Text(item.day)
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: Daily Activities
    private var dailyActivities: some View {
        guard let selected = weeklyDistributionData.first(where: { $0.day == selectedDay }) else { return AnyView(EmptyView()) }
        let dayTasks = dailyActivitiesData.filter { $0.day == selectedDay }
        let totalText = formattedDuration(selected.totalHours * 3600)

        return AnyView(
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack {
                    Text(selected.fullDate)
                        .sectionTitleStyle()
                    Spacer()
                    Text(totalText)
                        .font(AppFont.body())
                        .foregroundColor(AppColor.textSecondary)
                }

                VStack(spacing: AppSpacing.smallPlus) {
                    ForEach(dayTasks) { task in
                        HStack {
                            Text(task.title)
                                .font(AppFont.body())
                                .foregroundColor(AppColor.textPrimary)
                            Spacer()
                            TaskDurationBadge(text: task.duration)
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.smallPlus)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.standard)
                    }
                }
            }
        )
    }

    // MARK: Helpers
    private func formattedDuration(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func moveToPreviousWeek() {}
    private func moveToNextWeek() {}
    private func openCalendar() {}
}

// MARK: Components
private struct TaskDurationBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.caption())
            .fontWeight(.semibold)
            .padding(.horizontal, AppSpacing.smallPlus)
            .padding(.vertical, AppSpacing.xSmall)
            .background(AppColor.primary)
            .foregroundColor(AppColor.white)
            .cornerRadius(AppRadius.button)
    }
}

private struct DonutChart: View {
    let data: [CategoryRatio]
    let colors: [String: Color]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(segments) { segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(colors[segment.category] ?? AppColor.primary, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Circle()
                    .fill(AppColor.surface)
                    .frame(width: size * 0.55, height: size * 0.55)
            }
        }
    }

    private var segments: [DonutSegment] {
        var acc: CGFloat = 0
        let total = data.reduce(0) { $0 + $1.percentage }
        return data.map { item in
            let start = acc
            let end = acc + CGFloat(item.percentage / total)
            acc = end
            return DonutSegment(category: item.category, start: start, end: end)
        }
    }

    private struct DonutSegment: Identifiable {
        let id = UUID()
        let category: String
        let start: CGFloat
        let end: CGFloat
    }
}

// MARK: Sample Data Models
private struct DayTimeline: Identifiable {
    let id = UUID()
    let day: String
    let blocks: [TimelineBlock]

    struct TimelineBlock: Identifiable {
        let id = UUID()
        let category: String
        let startRatio: Double // 0...1 of day start
        let durationRatio: Double // 0...1 of day
    }

    static let sample: [DayTimeline] = [
        DayTimeline(day: "Mon", blocks: [
            .init(category: "Work", startRatio: 0.25, durationRatio: 0.25),
            .init(category: "Study", startRatio: 0.6, durationRatio: 0.15)
        ]),
        DayTimeline(day: "Tue", blocks: [
            .init(category: "Work", startRatio: 0.2, durationRatio: 0.3),
            .init(category: "Personal", startRatio: 0.65, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Wed", blocks: [
            .init(category: "Work", startRatio: 0.3, durationRatio: 0.25),
            .init(category: "Leisure", startRatio: 0.7, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Thu", blocks: [
            .init(category: "Work", startRatio: 0.2, durationRatio: 0.35)
        ]),
        DayTimeline(day: "Fri", blocks: [
            .init(category: "Work", startRatio: 0.25, durationRatio: 0.3),
            .init(category: "Health", startRatio: 0.65, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Sat", blocks: [
            .init(category: "Leisure", startRatio: 0.4, durationRatio: 0.25)
        ]),
        DayTimeline(day: "Sun", blocks: [
            .init(category: "Personal", startRatio: 0.3, durationRatio: 0.2)
        ])
    ]
}

private let timeTicks: [(label: String, position: Double)] = [
    ("00:00", 0.0),
    ("06:00", 0.25),
    ("12:00", 0.5),
    ("18:00", 0.75),
    ("24:00", 1.0)
]

private struct CategoryRatio: Identifiable {
    let id = UUID()
    let category: String
    let percentage: Double

    static let sample: [CategoryRatio] = [
        .init(category: "Work", percentage: 35),
        .init(category: "Study", percentage: 20),
        .init(category: "Leisure", percentage: 18),
        .init(category: "Health", percentage: 15),
        .init(category: "Personal", percentage: 12)
    ]
}

private struct DayDistribution: Identifiable {
    let id = UUID()
    let day: String
    let totalHours: Double
    let fullDate: String

    static let sample: [DayDistribution] = [
        .init(day: "Mon", totalHours: 3.5, fullDate: "Monday, Aug 14"),
        .init(day: "Tue", totalHours: 4.0, fullDate: "Tuesday, Aug 15"),
        .init(day: "Wed", totalHours: 2.0, fullDate: "Wednesday, Aug 16"),
        .init(day: "Thu", totalHours: 5.5, fullDate: "Thursday, Aug 17"),
        .init(day: "Fri", totalHours: 3.0, fullDate: "Friday, Aug 18"),
        .init(day: "Sat", totalHours: 4.5, fullDate: "Saturday, Aug 19"),
        .init(day: "Sun", totalHours: 2.5, fullDate: "Sunday, Aug 20")
    ]
}

private struct DailyTask: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let duration: String

    static let sample: [DailyTask] = [
        .init(day: "Mon", title: "Project Planning", duration: "1h 20m"),
        .init(day: "Mon", title: "Client Meeting", duration: "0h 50m"),
        .init(day: "Mon", title: "Design Review", duration: "0h 40m"),
        .init(day: "Tue", title: "Code Review", duration: "1h 00m"),
        .init(day: "Tue", title: "Documentation", duration: "0h 30m"),
        .init(day: "Wed", title: "Research", duration: "1h 00m"),
        .init(day: "Thu", title: "Development", duration: "3h 00m"),
        .init(day: "Fri", title: "Testing", duration: "1h 30m"),
        .init(day: "Sat", title: "Family Time", duration: "2h 00m"),
        .init(day: "Sun", title: "Reading", duration: "1h 15m")
    ]
}
