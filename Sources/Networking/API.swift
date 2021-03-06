////
///  ElloGraphQL.swift
//

import Alamofire
import PromiseKit
import SwiftyJSON


struct API {
    static var sharedManager: RequestManager = ElloManager()

    enum PageHeaderKind {
        case category(String)
        case artistInvites
        case editorials
        case generic

        var apiKind: String {
            switch self {
            case .category: return "CATEGORY"
            case .editorials: return "EDITORIAL"
            case .artistInvites: return "ARTIST_INVITE"
            case .generic: return "GENERIC"
            }
        }

        var slug: String? {
            switch self {
            case let .category(slug): return slug
            default: return nil
            }
        }
    }

    func globalPostStream(filter: CategoryFilter, before: String? = nil) -> GraphQLRequest<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "globalPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                .enum("StreamKind", "kind", filter.graphQL),
                .optionalString("before", before),
            ],
            body: Fragments.postStreamBody
            )
        return request
    }

    func categoryPostStream(categorySlug: String, filter: CategoryFilter, before: String? = nil) -> GraphQLRequest<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "categoryPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                .enum("StreamKind", "kind", filter.graphQL),
                .string("slug", categorySlug),
                .optionalString("before", before),
            ],
            body: Fragments.postStreamBody
            )
        return request
    }

    func categoryAdmins(categorySlug: String) -> GraphQLRequest<(moderators: [User], curators: [User])> {
        let request = GraphQLRequest(
            endpointName: "category",
            parser: { (json: JSON) -> (moderators: [User], curators: [User]) in
                guard let categoryUsers = json["categoryUsers"].array else { throw Parser.Error.parsingError }

                let userParser = UserParser()
                var moderators: [User] = []
                var curators: [User] = []
                for role in categoryUsers {
                    let user = userParser.parse(json: role["user"])
                    if role["role"].string == "MODERATOR" {
                        moderators.append(user)
                    }
                    else if role["role"].string == "CURATOR" {
                        curators.append(user)
                    }
                }

                return (moderators: moderators, curators: curators)
            },
            variables: [
                .string("slug", categorySlug),
            ],
            body: Fragments.categoryAdminsBody
            )
        return request
    }

    func subscribedPostStream(filter: CategoryFilter, before: String? = nil) -> GraphQLRequest<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "subscribedPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                .enum("StreamKind", "kind", filter.graphQL),
                .optionalString("before", before),
            ],
            body: Fragments.postStreamBody
            )
        return request
    }

    func allCategories() -> GraphQLRequest<[Category]> {
        let request = GraphQLRequest(
            endpointName: "allCategories",
            parser: ManyParser<Category>(CategoryParser()).parse,
            body: Fragments.categoriesBody
            )
        return request
    }

    func subscribedCategories() -> GraphQLRequest<[Category]> {
        let request = GraphQLRequest(
            endpointName: "categoryNav",
            parser: ManyParser<Category>(CategoryParser()).parse,
            body: Fragments.categoriesBody
            )
        return request
    }

    func pageHeaders(kind: PageHeaderKind) -> GraphQLRequest<[PageHeader]> {
        let request = GraphQLRequest(
            endpointName: "pageHeaders",
            parser: ManyParser<PageHeader>(PageHeaderParser()).parse,
            variables: [
                .enum("PageHeaderKind", "kind", kind.apiKind),
                .optionalString("slug", kind.slug),
            ],
            body: Fragments.pageHeaderBody
            )
        return request
    }

    func postDetail(token: Token, username: String?) -> GraphQLRequest<Post> {
        let request = GraphQLRequest(
            endpointName: "post",
            parser: OneParser<Post>(PostParser()).parse,
            variables: [
                token.toVariable(token: "token"),
                .optionalString("username", username),
            ],
            body: Fragments.postBody
        )
        return request
    }

    func userDetail(token: Token) -> GraphQLRequest<User> {
        let request = GraphQLRequest(
            endpointName: "findUser",
            parser: OneParser<User>(UserParser()).parse,
            variables: [
                token.toVariable(token: "username")
            ],
            body: Fragments.userBody
        )
        return request
    }

    func userPosts(username: String, before: String? = nil) -> GraphQLRequest<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "userPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                .string("username", username),
                .optionalString("before", before),
            ],
            body: Fragments.postStreamBody
            )
        return request
    }

    func userLoves(username: String, before: String? = nil) -> GraphQLRequest<(PageConfig, [Love])> {
        let request = GraphQLRequest(
            endpointName: "userLoveStream",
            parser: PageParser<Love>("loves", LoveParser()).parse,
            variables: [
                .string("username", username),
                .optionalString("before", before),
            ],
            body: Fragments.loveStreamBody
            )
        return request
    }
}
