//
//  StudyRoom.swift
//  CICompanion
//
//  Created by Emma on 4/19/26.
//

struct StudyRoomResponse: Decodable {
    let slots: [StudyRoomSlot]
    let bookings: [String]
    let isPreCreatedBooking: Bool
    let windowEnd: Bool
}

struct StudyRoomSlot: Decodable {
    let start: String
    let end: String
    let itemId: Int
    let checksum: String
    let className: String?
}
