import Foundation
import CoreData

extension DailyTaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyTaskEntity> {
        NSFetchRequest<DailyTaskEntity>(entityName: "DailyTaskEntity")
    }

    @NSManaged public var checklistState: [Bool]?
    @NSManaged public var checklistTexts: [String]?
    @NSManaged public var categoryId: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var goalTime: Int64
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int16
    @NSManaged public var priority: Int16
    @NSManaged public var realTime: Int64
    @NSManaged public var title: String?
    @NSManaged public var usesChecklist: Bool
    @NSManaged public var updatedAt: Date?
    @NSManaged public var task: TaskEntity?
    @NSManaged public var sessions: NSSet?
}

// MARK: Generated accessors for sessions
extension DailyTaskEntity {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: SessionEntity)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: SessionEntity)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}

extension DailyTaskEntity: Identifiable {}
