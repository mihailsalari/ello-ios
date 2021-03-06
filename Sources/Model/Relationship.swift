////
///  Relationship.swift
//

import SwiftyJSON


let RelationshipVersion = 1

@objc(Relationship)
final class Relationship: Model {

    let id: String
    let ownerId: String
    let subjectId: String

    var owner: User? { return getLinkObject("owner") }
    var subject: User? { return getLinkObject("subject") }

    init(
        id: String,
        ownerId: String,
        subjectId: String
        ) {
        self.id = id
        self.ownerId = ownerId
        self.subjectId = subjectId
        super.init(version: RelationshipVersion)
    }

    required init(coder: NSCoder) {
        let decoder = Coder(coder)
        self.id = decoder.decodeKey("id")
        self.ownerId = decoder.decodeKey("ownerId")
        self.subjectId = decoder.decodeKey("subjectId")
        super.init(coder: coder)
    }

    override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(id, forKey: "id")
        coder.encodeObject(ownerId, forKey: "ownerId")
        coder.encodeObject(subjectId, forKey: "subjectId")
        super.encode(with: coder.coder)
    }

    class func fromJSON(_ data: [String: Any]) -> Relationship {
        let json = JSON(data)

        let relationship = Relationship(
            id: json["id"].stringValue,
            ownerId: json["links"]["owner"]["id"].stringValue,
            subjectId: json["links"]["subject"]["id"].stringValue
        )

        relationship.mergeLinks(json["links"].dictionaryObject)

        return relationship
    }
}

extension Relationship: JSONSaveable {
    var uniqueId: String? { return "Relationship-\(id)" }
    var tableId: String? { return id }
}
