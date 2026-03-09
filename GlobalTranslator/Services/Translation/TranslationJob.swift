import Foundation

struct TranslationJobSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let preview: String
    let providerID: String
    let status: TranslationJobStatus
    let createdAt: Date
}
