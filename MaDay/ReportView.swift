import SwiftUI

struct ReportView: View {
    @State private var currentWeekStart: Date = Date().startOfWeek
    @State private var selectedDay: String = "Mon"
    @State private var isCalendarPresented = false

    private let categoryColors: [String: Color] = [
        "Work": AppColor.work,
        "Study": AppColor.learning,
        "Leisure": AppColor.youtube,
        "Health": AppColor.fitness,
        "Personal": AppColor.personal
    ]

    private var weeklyTimelineData: [DayTimeline] { DayTimeline.sample }
    private var categoryRatioData: [CategoryRatio] { CategoryRatio.sample }
    
    private var weeklyDistributionData: [DayDistribution] {
        DayDistribution.generate(startOfWeek: currentWeekStart)
    }
    
    private var dailyActivitiesData: [DailyTask] {
        DailyTask.generate(startOfWeek: currentWeekStart)
    }

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
        .sheet(isPresented: $isCalendarPresented) {
            CustomCalendarView(selectedDate: $currentWeekStart)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
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
                    Text(dateRangeString)
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
    
    private var dateRangeString: String {
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }

    // MARK: Weekly Performance Overview
    @State private var selectedBlockInfo: SelectedBlockInfo?

    private struct SelectedBlockInfo {
        let day: String
        let block: DayTimeline.TimelineBlock
    }

    private var weeklyTimeline: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Weekly Performance Overview")
                .sectionTitleStyle()

            Text("Click a block to view task details.")
                .font(AppFont.caption())
                .foregroundColor(AppColor.textSecondary)

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
                                            let isSelected = selectedBlockInfo?.block.id == block.id
                                            RoundedRectangle(cornerRadius: AppRadius.button)
                                                .fill(categoryColors[block.category] ?? AppColor.primary)
                                                .opacity(isSelected ? 1.0 : 0.8)
                                                .frame(width: barWidth, height: CGFloat(block.durationRatio) * chartHeight)
                                                .offset(y: CGFloat(block.startRatio) * chartHeight)
                                                .onTapGesture {
                                                    if selectedBlockInfo?.block.id == block.id {
                                                        selectedBlockInfo = nil
                                                    } else {
                                                        selectedBlockInfo = SelectedBlockInfo(day: day.day, block: block)
                                                    }
                                                }
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

            if let info = selectedBlockInfo {
                selectedBlockDetailView(info: info)
            }
        }
    }

    private func selectedBlockDetailView(info: SelectedBlockInfo) -> some View {
        let block = info.block
        let startTime = formatTime(ratio: block.startRatio)
        let endTime = formatTime(ratio: block.startRatio + block.durationRatio)
        let duration = formattedDuration(block.durationRatio * 24 * 3600)

        return HStack(spacing: AppSpacing.medium) {
            Circle()
                .fill(categoryColors[block.category] ?? AppColor.primary)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                
                Text("\(info.day) • \(startTime) - \(endTime) (\(duration))")
                    .font(AppFont.caption())
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
        .padding(AppSpacing.medium)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.standard)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func formatTime(ratio: Double) -> String {
        let totalMinutes = Int(ratio * 24 * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
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

            let sortedData = categoryRatioData.sorted { $0.percentage > $1.percentage }

            VStack(spacing: AppSpacing.large) {
                DonutChart(data: sortedData, colors: categoryColors)
                    .frame(width: 200, height: 200)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: AppSpacing.medium) {
                    ForEach(sortedData) { item in
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
            .padding(.top, AppSpacing.medium)
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

            HStack {
                Spacer()
                HStack(alignment: .bottom, spacing: AppSpacing.small) {
                    ForEach(weeklyDistributionData) { item in
                        let isSelected = item.day == selectedDay
                        VStack {
                            Rectangle()
                                .fill(isSelected ? AppColor.primaryStrong : AppColor.primary.opacity(0.7))
                                .frame(width: 45, height: CGFloat(item.totalHours) * 18)
                                .cornerRadius(AppRadius.button)
                                .shadow(color: isSelected ? AppColor.primary.opacity(0.3) : .clear, radius: 3, x: 0, y: 2)
                                .onTapGesture { selectedDay = item.day }
                            Text(item.day)
                                .font(AppFont.caption())
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                }
                Spacer()
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

    private func moveToPreviousWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func moveToNextWeek() {
        currentWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func openCalendar() {
        isCalendarPresented = true
    }
}

// MARK: Components
private struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            // Header
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColor.textPrimary)
                }
                Spacer()
                Text(monthYearString)
                    .font(AppFont.headline())
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColor.textPrimary)
                }
            }
            .padding(.horizontal)
            
            // Days Grid
            VStack(spacing: AppSpacing.small) {
                // Weekday Headers
                HStack {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(AppFont.caption())
                            .foregroundColor(AppColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(date: date, selectedDate: selectedDate) {
                                selectedDate = date
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    dismiss()
                                }
                            }
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white) // Opaque background
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        
        var days: [Date?] = []
        calendar.enumerateDates(startingAfter: dateInterval.start - 1, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            if date < dateInterval.end {
                if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                    days.append(date)
                } else {
                    days.append(nil) // Padding for start/end of grid if needed, or just skip
                }
            } else {
                stop = true
            }
        }
        
        // Better approach for grid alignment:
        let startOfMonth = currentMonth.startOfMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1
        
        var gridDays: [Date?] = Array(repeating: nil, count: offsetDays)
        
        if let range = calendar.range(of: .day, in: .month, for: currentMonth) {
            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    gridDays.append(date)
                }
            }
        }
        
        return gridDays
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

private struct DayCell: View {
    let date: Date
    let selectedDate: Date
    let action: () -> Void
    
    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isInRange: Bool {
        let calendar = Calendar.current
        let rangeEnd = calendar.date(byAdding: .day, value: 6, to: selectedDate) ?? selectedDate
        return date >= selectedDate && date <= rangeEnd
    }
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(AppFont.body())
                .foregroundColor(isSelected ? .white : (isInRange ? AppColor.primaryStrong : AppColor.textPrimary))
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            Circle().fill(AppColor.primaryStrong)
                        } else if isInRange {
                            Circle().fill(AppColor.primary.opacity(0.3))
                        }
                    }
                )
        }
    }
}

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
            ZStack {
                ForEach(segments) { segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(colors[segment.category] ?? AppColor.primary, style: StrokeStyle(lineWidth: 30, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
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
        let title: String
        let startRatio: Double // 0...1 of day start
        let durationRatio: Double // 0...1 of day
    }

    static let sample: [DayTimeline] = [
        DayTimeline(day: "Mon", blocks: [
            .init(category: "Work", title: "Project Planning", startRatio: 0.25, durationRatio: 0.25),
            .init(category: "Study", title: "iOS Development", startRatio: 0.6, durationRatio: 0.15)
        ]),
        DayTimeline(day: "Tue", blocks: [
            .init(category: "Work", title: "Client Meeting", startRatio: 0.2, durationRatio: 0.3),
            .init(category: "Personal", title: "Grocery Shopping", startRatio: 0.65, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Wed", blocks: [
            .init(category: "Work", title: "Code Review", startRatio: 0.3, durationRatio: 0.25),
            .init(category: "Leisure", title: "Gaming", startRatio: 0.7, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Thu", blocks: [
            .init(category: "Work", title: "Deep Work", startRatio: 0.2, durationRatio: 0.35)
        ]),
        DayTimeline(day: "Fri", blocks: [
            .init(category: "Work", title: "Weekly Sync", startRatio: 0.25, durationRatio: 0.3),
            .init(category: "Health", title: "Gym", startRatio: 0.65, durationRatio: 0.1)
        ]),
        DayTimeline(day: "Sat", blocks: [
            .init(category: "Leisure", title: "Movie Night", startRatio: 0.4, durationRatio: 0.25)
        ]),
        DayTimeline(day: "Sun", blocks: [
            .init(category: "Personal", title: "Reading", startRatio: 0.3, durationRatio: 0.2)
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

    static func generate(startOfWeek: Date) -> [DayDistribution] {
        let calendar = Calendar.current
        let baseHours = [3.5, 4.0, 2.0, 5.5, 3.0, 4.5, 2.5]
        
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) ?? startOfWeek
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E" // "Mon", "Tue"
            let fullDateFormatter = DateFormatter()
            fullDateFormatter.dateFormat = "EEEE, MMM d"
            
            return DayDistribution(
                day: dayFormatter.string(from: date),
                totalHours: baseHours[i % 7], // Cycle through sample data
                fullDate: fullDateFormatter.string(from: date)
            )
        }
    }
    
    static let sample = generate(startOfWeek: Date().startOfWeek)
}

private struct DailyTask: Identifiable {
    let id = UUID()
    let day: String
    let title: String
    let duration: String

    static func generate(startOfWeek: Date) -> [DailyTask] {
        // Return static sample data for now, but could be dynamic
        return sample
    }

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

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth) ?? self
    }
}
