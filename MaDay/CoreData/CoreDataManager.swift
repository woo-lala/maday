import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}

    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    // MARK: - TaskEntity CRUD (Template)

    func createTask(title: String, 
                   category: CategoryEntity?, 
                   defaultGoalTime: Int64, 
                   defaultChecklist: [String]?, 
                   color: String?,
                   descriptionText: String? = nil,
                   usesChecklist: Bool = false,
                   dueDate: Date? = nil,
                   repeatDays: [Int]? = nil) -> TaskEntity {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = title
        task.category = category
        task.defaultGoalTime = defaultGoalTime
        task.defaultChecklist = defaultChecklist
        task.color = color
        task.descriptionText = descriptionText
        task.createdAt = Date()
        task.updatedAt = Date()
        task.usesChecklist = usesChecklist
        task.dueDate = dueDate
        task.repeatDays = repeatDays
        
        saveContext()
        return task
    }

    func fetchTasks() -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            // Ensure all tasks have stable IDs for selection/UI
            var needsSave = false
            results.forEach { task in
                if task.id == nil {
                    task.id = UUID()
                    needsSave = true
                }
            }
            if needsSave { saveContext() }
            return results
        } catch {
            print("Error fetching tasks: \(error.localizedDescription)")
            return []
        }
    }

    func updateTask(_ task: TaskEntity, 
                   title: String? = nil, 
                   category: CategoryEntity? = nil,
                   defaultGoalTime: Int64? = nil, 
                   defaultChecklist: [String]? = nil,
                   color: String? = nil,
                   descriptionText: String? = nil,
                   usesChecklist: Bool? = nil,
                   dueDate: Date? = nil,
                   repeatDays: [Int]? = nil) {
        if let title = title { task.title = title }
        if let category = category { task.category = category }
        if let defaultGoalTime = defaultGoalTime { task.defaultGoalTime = defaultGoalTime }
        if let defaultChecklist = defaultChecklist { task.defaultChecklist = defaultChecklist }
        if let color = color { task.color = color }
        if let descriptionText = descriptionText { task.descriptionText = descriptionText }
        if let usesChecklist = usesChecklist { task.usesChecklist = usesChecklist }
        if let dueDate = dueDate { task.dueDate = dueDate }
        if let repeatDays = repeatDays { task.repeatDays = repeatDays }
        task.updatedAt = Date()
        
        saveContext()
    }

    func deleteTask(_ task: TaskEntity) {
        context.delete(task)
        saveContext()
    }

    // MARK: - DailyTaskEntity CRUD (Snapshot)

    func createDailyTask(from template: TaskEntity, date: Date, order: Int16) -> DailyTaskEntity {
        let dailyTask = DailyTaskEntity(context: context)
        dailyTask.id = UUID()
        dailyTask.date = date
        dailyTask.createdAt = Date()
        dailyTask.updatedAt = Date()
        dailyTask.order = order
        dailyTask.title = template.title
        let templateChecklist = template.defaultChecklist ?? []
        dailyTask.usesChecklist = template.usesChecklist ? true : !templateChecklist.isEmpty
        
        // Snapshot: Copy values from template
        dailyTask.goalTime = template.defaultGoalTime
        dailyTask.realTime = 0
        dailyTask.isCompleted = false
        dailyTask.priority = 0
        dailyTask.descriptionText = template.descriptionText ?? ""
        dailyTask.categoryId = template.category?.id
        dailyTask.checklistTexts = template.defaultChecklist ?? []
        
        // Relationship
        dailyTask.task = template
        
        // Initialize Checklist State (Array of false)
        let count = template.defaultChecklist?.count ?? 0
        if count > 0 {
            dailyTask.checklistState = Array(repeating: false, count: count)
        } else {
            dailyTask.checklistState = []
        }
        
        saveContext()
        return dailyTask
    }

    func fetchDailyTasks(for date: Date) -> [DailyTaskEntity] {
        let request: NSFetchRequest<DailyTaskEntity> = DailyTaskEntity.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        // End of day is start of next day
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        // Sort by user-defined order, then createdAt
        request.sortDescriptors = [
            NSSortDescriptor(key: "order", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        
        do {
            let results = try context.fetch(request)
            var needsSave = false
            results.forEach { daily in
                if daily.id == nil {
                    daily.id = UUID()
                    needsSave = true
                }
            }
            if needsSave { saveContext() }
            return results
        } catch {
            print("Error fetching daily tasks: \(error.localizedDescription)")
            return []
        }
    }

    func fetchRecentDailyTasks(limitDays: Int) -> [DailyTaskEntity] {
        let request: NSFetchRequest<DailyTaskEntity> = DailyTaskEntity.fetchRequest()
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -limitDays, to: today) else { return [] }
        
        // Fetch tasks from [Today - limitDays] up to now (inclusive/future not strictly excluded but 'Recent' implies past usage)
        // Actually, we probably just want tasks CREATED/USED recently.
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent daily tasks: \(error.localizedDescription)")
            return []
        }
    }

    func updateDailyTask(_ dailyTask: DailyTaskEntity, 
                        realTime: Int64? = nil,
                        isCompleted: Bool? = nil,
                        checklistState: [Bool]? = nil,
                       checklistTexts: [String]? = nil,
                       descriptionText: String? = nil,
                       priority: Int16? = nil,
                       goalTime: Int64? = nil,
                       categoryId: UUID? = nil,
                       order: Int16? = nil,
                        title: String? = nil,
                        usesChecklist: Bool? = nil) {
        if let realTime = realTime { dailyTask.realTime = realTime }
        if let isCompleted = isCompleted { dailyTask.isCompleted = isCompleted }
        if let checklistState = checklistState { dailyTask.checklistState = checklistState }
        if let checklistTexts = checklistTexts { dailyTask.checklistTexts = checklistTexts }
        if let descriptionText = descriptionText { dailyTask.descriptionText = descriptionText }
        if let priority = priority { dailyTask.priority = priority }
        if let goalTime = goalTime { dailyTask.goalTime = goalTime }
        if let categoryId = categoryId { dailyTask.categoryId = categoryId }
        if let order = order { dailyTask.order = order }
        if let title = title { dailyTask.title = title }
        if let usesChecklist = usesChecklist { dailyTask.usesChecklist = usesChecklist }
        
        dailyTask.updatedAt = Date()
        saveContext()
    }

    func deleteDailyTask(_ dailyTask: DailyTaskEntity) {
        context.delete(dailyTask)
        saveContext()
    }

    // MARK: - SessionEntity CRUD (Per-DailyTask measurement sessions)

    @discardableResult
    func createSession(for dailyTask: DailyTaskEntity, start: Date = Date()) -> SessionEntity {
        let session = SessionEntity(context: context)
        session.id = UUID()
        session.session_uuid = session.id
        session.startTime = start
        session.createdAt = Date()
        session.updatedAt = Date()
        session.duration = 0
        session.dailyTask = dailyTask
        dailyTask.addToSessions(session)
        print("[Session] Created session \(session.id?.uuidString ?? "nil") for dailyTask \(dailyTask.id?.uuidString ?? "nil") start=\(start)")
        saveContext()
        return session
    }

    /// Ends an active session and updates the parent DailyTaskEntity.realTime.
    func endSession(_ session: SessionEntity, for dailyTask: DailyTaskEntity, end: Date = Date()) {
        guard let start = session.startTime else { return }
        session.endTime = end
        session.duration = Int64(end.timeIntervalSince(start))
        session.updatedAt = Date()

        // Ensure we only add once per session closure
        dailyTask.realTime = totalSessionDuration(for: dailyTask)
        print("[Session] Ended session \(session.id?.uuidString ?? "nil") start=\(start) end=\(end) duration=\(session.duration) total=\(dailyTask.realTime)")
        saveContext()
    }

    func fetchSessions(for dailyTask: DailyTaskEntity) -> [SessionEntity] {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "dailyTask == %@", dailyTask)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        do {
            let sessions = try context.fetch(request)
            print("[Session] Fetched \(sessions.count) sessions for dailyTask \(dailyTask.id?.uuidString ?? "nil")")
            return sessions
        } catch {
            print("Error fetching sessions: \(error.localizedDescription)")
            return []
        }
    }

    func deleteSession(_ session: SessionEntity) {
        let sessionId = session.id?.uuidString ?? "nil"
        context.delete(session)
        print("[Session] Deleted session \(sessionId)")
        saveContext()
    }

    /// Recalculate and return total measured seconds across all sessions.
    func totalSessionDuration(for dailyTask: DailyTaskEntity) -> Int64 {
        let sessions = fetchSessions(for: dailyTask)
        let total = sessions.reduce(Int64(0)) { partial, session in
            let duration: Int64
            if let start = session.startTime, let end = session.endTime {
                duration = Int64(end.timeIntervalSince(start))
            } else {
                duration = session.duration
            }
            return partial + max(0, duration)
        }
        dailyTask.realTime = total
        dailyTask.updatedAt = Date()
        print("[Session] totalSessionDuration dailyTask \(dailyTask.id?.uuidString ?? "nil") = \(total)")
        sessions.forEach { session in
            let sid = session.id?.uuidString ?? "nil"
            let start = session.startTime?.description ?? "nil"
            let end = session.endTime?.description ?? "nil"
            print("    • Session \(sid) start=\(start) end=\(end) duration=\(session.duration)")
        }
        return total
    }

    // MARK: - Category CRUD

    func fetchCategories() -> [CategoryEntity] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error.localizedDescription)")
            return []
        }
    }

    func createCategory(name: String, color: String, order: Int16) -> CategoryEntity {
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = name
        category.color = color
        category.order = order
        category.createdAt = Date()
        category.updatedAt = Date()
        saveContext()
        return category
    }

    func deleteCategory(_ category: CategoryEntity) {
        context.delete(category)
        saveContext()
    }

    // MARK: - Persistence Info

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
}
