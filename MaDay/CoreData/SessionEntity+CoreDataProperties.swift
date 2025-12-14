import Foundation
import CoreData

extension SessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionEntity> {
        NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var duration: Int64
    @NSManaged public var endTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var version: Int64
    @NSManaged public var sourceDevice: String?
    @NSManaged public var dailyTask: DailyTaskEntity?
}

extension SessionEntity: Identifiable {}
