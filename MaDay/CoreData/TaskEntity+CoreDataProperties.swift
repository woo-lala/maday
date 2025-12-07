import Foundation
import CoreData


extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var categoryId: UUID?
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var defaultChecklist: [String]?
    @NSManaged public var defaultGoalTime: Int64
    @NSManaged public var descriptionText: String?
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var usesChecklist: Bool
    @NSManaged public var dailyTasks: NSSet?
    @NSManaged public var category: CategoryEntity?

}

// MARK: Generated accessors for dailyTasks
extension TaskEntity {

    @objc(addDailyTasksObject:)
    @NSManaged public func addToDailyTasks(_ value: DailyTaskEntity)

    @objc(removeDailyTasksObject:)
    @NSManaged public func removeFromDailyTasks(_ value: DailyTaskEntity)

    @objc(addDailyTasks:)
    @NSManaged public func addToDailyTasks(_ values: NSSet)

    @objc(removeDailyTasks:)
    @NSManaged public func removeFromDailyTasks(_ values: NSSet)

}

extension TaskEntity : Identifiable {

}
