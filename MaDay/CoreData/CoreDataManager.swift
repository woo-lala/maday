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
                   descriptionText: String? = nil) -> TaskEntity {
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
                   descriptionText: String? = nil) {
        if let title = title { task.title = title }
        if let category = category { task.category = category }
        if let defaultGoalTime = defaultGoalTime { task.defaultGoalTime = defaultGoalTime }
        if let defaultChecklist = defaultChecklist { task.defaultChecklist = defaultChecklist }
        if let color = color { task.color = color }
        if let descriptionText = descriptionText { task.descriptionText = descriptionText }
        task.updatedAt = Date()
        
        saveContext()
    }

    func deleteTask(_ task: TaskEntity) {
        context.delete(task)
        saveContext()
    }

    // MARK: - DailyTaskEntity CRUD (Snapshot)

    func createDailyTask(from template: TaskEntity, date: Date) -> DailyTaskEntity {
        let dailyTask = DailyTaskEntity(context: context)
        dailyTask.id = UUID()
        dailyTask.date = date
        dailyTask.createdAt = Date()
        dailyTask.updatedAt = Date()
        
        // Snapshot: Copy values from template
        dailyTask.goalTime = template.defaultGoalTime
        dailyTask.realTime = 0
        dailyTask.isCompleted = false
        dailyTask.priority = 0
        dailyTask.descriptionText = template.descriptionText ?? ""
        
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
        
        // Sort: Incomplete first, by Priority desc, then CreatedAt
        request.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching daily tasks: \(error.localizedDescription)")
            return []
        }
    }

    func updateDailyTask(_ dailyTask: DailyTaskEntity, 
                        realTime: Int64? = nil,
                        isCompleted: Bool? = nil,
                        checklistState: [Bool]? = nil,
                        descriptionText: String? = nil,
                        priority: Int16? = nil) {
        if let realTime = realTime { dailyTask.realTime = realTime }
        if let isCompleted = isCompleted { dailyTask.isCompleted = isCompleted }
        if let checklistState = checklistState { dailyTask.checklistState = checklistState }
        if let descriptionText = descriptionText { dailyTask.descriptionText = descriptionText }
        if let priority = priority { dailyTask.priority = priority }
        
        dailyTask.updatedAt = Date()
        saveContext()
    }

    func deleteDailyTask(_ dailyTask: DailyTaskEntity) {
        context.delete(dailyTask)
        saveContext()
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
