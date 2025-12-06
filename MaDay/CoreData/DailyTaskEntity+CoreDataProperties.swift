import Foundation
import CoreData


extension DailyTaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyTaskEntity> {
        return NSFetchRequest<DailyTaskEntity>(entityName: "DailyTaskEntity")
    }

    @NSManaged public var checklistState: [Bool]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var goalTime: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var priority: Int16
    @NSManaged public var realTime: Int64
    @NSManaged public var updatedAt: Date?
    @NSManaged public var task: TaskEntity?

}

extension DailyTaskEntity : Identifiable {

}
