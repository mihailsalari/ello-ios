////
///  ElloGraphQL.swift
//

import Alamofire
import PromiseKit
import SwiftyJSON


struct API {
    func subscribedCategories() -> Promise<[Category]> {
        let request = GraphQLRequest(
            endpointName: "categoryNav",
            parser: ManyParser<Category>(CategoryParser()).parse,
            fragments: """
                fragment imageProps on Image {
                  url
                  metadata { height width type size }
                }

                fragment tshirtImages on TshirtImageVersions {
                  large { ...imageProps }
                }
                """,
            body: """
                id
                name
                slug
                order
                allowInOnboarding
                isCreatorType
                level
                tileImage { ...tshirtImages }
                """
            )
        return request.execute()
    }

    func userPosts(username: String, before: String? = nil) -> Promise<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "userPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                (.string("username", username)),
                (.optionalString("before", before)),
            ],
            fragments: """
                fragment imageProps on Image {
                  url
                  metadata { height width type size }
                }

                fragment tshirtImages on TshirtImageVersions {
                  small { ...imageProps }
                  regular { ...imageProps }
                  large { ...imageProps }
                  original { ...imageProps }
                }

                fragment responsiveImages on ResponsiveImageVersions {
                  mdpi { ...imageProps }
                  ldpi { ...imageProps }
                  hdpi { ...imageProps }
                  xhdpi { ...imageProps }
                  optimized { ...imageProps }
                }

                fragment authorSummary on User {
                  id
                  username
                  name
                  currentUserState { relationshipPriority }
                  settings {
                    hasCommentingEnabled hasLovesEnabled hasRepostingEnabled hasSharingEnabled
                    isCollaborateable isHireable
                  }
                  avatar {
                    ...tshirtImages
                  }
                  coverImage {
                    ...responsiveImages
                  }
                }

                fragment contentProps on ContentBlocks {
                  linkUrl
                  kind
                  data
                  links { assets }
                }

                fragment assetProps on Asset {
                  id
                  attachment { ...responsiveImages }
                }

                fragment postContent on Post {
                  content { ...contentProps }
                }

                fragment postSummary on Post {
                  id
                  token
                  createdAt
                  summary { ...contentProps }
                  author { ...authorSummary }
                  assets { ...assetProps }
                  postStats { lovesCount commentsCount viewsCount repostsCount }
                  currentUserState { watching loved reposted }
                }
                """,
            body: """
                next isLastPage
                posts {
                    ...postSummary
                    ...postContent
                    repostContent { ...contentProps }
                    currentUserState { loved reposted watching }
                    repostedSource {
                        ...postSummary
                    }
                }
                """
            )
        return request.execute()
    }
}
