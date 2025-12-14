import Foundation
import CoreData

extension CategoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var order: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var synced: Bool
    @NSManaged public var deletedAt: Date?
    @NSManaged public var tasks: NSSet?
}

// MARK: Generated accessors for tasks
extension CategoryEntity {
    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: TaskEntity)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: TaskEntity)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)
}

extension CategoryEntity: Identifiable {}
