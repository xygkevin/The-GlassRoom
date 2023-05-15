//
//  CoursePostsDataManager.swift
//  The GlassRoom
//
//  Created by Kai Quan Tay on 15/5/23.
//

import Foundation
import GlassRoomAPI

class CoursePostsDataManager: ObservableObject {
    @Published private(set) var courseAnnouncements: [CourseAnnouncement] = []
    @Published private(set) var courseCourseWorks: [CourseWork] = []
    @Published private(set) var courseCourseMaterials: [CourseWorkMaterial] = []

    var postData: [CoursePost] {
        self.courseAnnouncements.map({ .announcement($0) })
            .mergedWith(other: courseCourseWorks.map({ .courseWork($0) })) { lhs, rhs in
                lhs.id == rhs.id
            } isBefore: { lhs, rhs in
                lhs.creationDate > rhs.creationDate
            }
            .mergedWith(other: courseCourseMaterials.map({ .courseMaterial($0) })) { lhs, rhs in
                lhs.id == rhs.id
            } isBefore: { lhs, rhs in
                lhs.creationDate > rhs.creationDate
            }
    }

    let courseId: String

    var loading: Bool {
        announcementsLoading || courseWorksLoading
    }
    var hasNextPage: Bool {
        announcementsNextPageToken != nil || courseWorksNextPageToken != nil
    }

    @Published private(set) var announcementsLoading: Bool = false
    @Published private(set) var courseWorksLoading: Bool = false
    @Published private(set) var courseMaterialsLoading: Bool = false

    @Published private(set) var announcementsNextPageToken: String?
    @Published private(set) var courseWorksNextPageToken: String?
    @Published private(set) var courseMaterialsNextPageToken: String?

    init(courseId: String) {
        self.courseId = courseId

        CoursePostsDataManager.loadedManagers[courseId] = self
    }

    func loadList(bypassCache: Bool = false) {
        announcementsLoading = true
        courseWorksLoading = true
        courseMaterialsLoading = true

        // use cache first either way to look faster
        let cachedAnnouncements = readAnnouncementsCache()
        let cachedCourseWorks = readCourseWorksCache()
        let cachedCourseMaterials = readCourseMaterialsCache()

        if bypassCache {
            if !cachedAnnouncements.isEmpty { courseAnnouncements = cachedAnnouncements }
            if !cachedCourseWorks.isEmpty { courseCourseWorks = cachedCourseWorks }
            if !cachedCourseMaterials.isEmpty { courseCourseMaterials = cachedCourseMaterials }
            refreshAnnouncementsList()
            refreshCourseWorksList()
            refreshCourseMaterialsList()
        } else {
            // load from cache first, if that fails load from the list.
            if cachedAnnouncements.isEmpty {
                refreshAnnouncementsList()
            } else {
                self.courseAnnouncements = cachedAnnouncements
                announcementsLoading = false
            }
            if cachedCourseWorks.isEmpty {
                refreshCourseWorksList()
            } else {
                self.courseCourseWorks = cachedCourseWorks
                courseWorksLoading = false
            }
            if cachedCourseMaterials.isEmpty {
                refreshCourseMaterialsList()
            } else {
                self.courseCourseMaterials = cachedCourseMaterials
                courseMaterialsLoading = false
            }
        }
    }

    func refreshList(requestNextPageIfExists: Bool = false) {
        announcementsLoading = true
        courseWorksLoading = true
        courseMaterialsLoading = true

        refreshAnnouncementsList(requestNextPageIfExists: requestNextPageIfExists)
        refreshCourseWorksList(requestNextPageIfExists: requestNextPageIfExists)
        refreshCourseMaterialsList(requestNextPageIfExists: requestNextPageIfExists)
    }

    func clearCache(courseId: String) {
        FileSystem.write([CourseAnnouncement](), to: "\(courseId)_courseAnnouncements.json")
        FileSystem.write([CourseWork](), to: "\(courseId)_courseWorks.json")
        FileSystem.write([CourseWorkMaterial](), to: "\(courseId)_courseMaterials.json")
    }

    // MARK: Static functions
    static private(set) var loadedManagers: [String: CoursePostsDataManager] = [:]

    static func getManager(for courseId: String) -> CoursePostsDataManager {
        if let manager = loadedManagers[courseId] {
            return manager
        }
        return .init(courseId: courseId)
    }
}

// MARK: Per-type functions
extension CoursePostsDataManager {
    // MARK: Announcements
    func readAnnouncementsCache() -> [CourseAnnouncement] {
        // if the file exists in CourseCache
        if FileSystem.exists(file: "\(courseId)_courseAnnouncements.json"),
           let cacheItems = FileSystem.read([CourseAnnouncement].self, from: "\(courseId)_courseAnnouncements.json") {
            return cacheItems
        }
        return []
    }

    func writeAnnouncementsCache() {
        FileSystem.write(courseAnnouncements, to: "\(courseId)_courseAnnouncements.json") { error in
            print("Error writing: \(error.localizedDescription)")
        }
    }

    func refreshAnnouncementsList(nextPageToken: String? = nil, requestNextPageIfExists: Bool = false) {
        GlassRoomAPI.GRCourses.GRAnnouncements.list(params: .init(courseId: courseId),
                                                    query: .init(announcementStates: nil,
                                                                 orderBy: nil,
                                                                 pageSize: nil,
                                                                 pageToken: nextPageToken),
                                                    data: VoidStringCodable()
        ) { response in
            switch response {
            case .success(let success):
                self.courseAnnouncements.mergeWith(other: success.announcements,
                                                   isSame: { $0.id == $1.id },
                                                   isBefore: { $0.creationDate > $1.creationDate })
                if let token = success.nextPageToken, requestNextPageIfExists {
                    self.refreshAnnouncementsList(nextPageToken: token,
                                                  requestNextPageIfExists: requestNextPageIfExists)
                } else {
                    DispatchQueue.main.async {
                        self.announcementsNextPageToken = success.nextPageToken
                        self.announcementsLoading = false
                        self.writeAnnouncementsCache()
                    }
                }
            case .failure(let failure):
                print("Failure: \(failure.localizedDescription)")
                self.announcementsLoading = false
            }
        }
    }

    // MARK: Course Works
    func readCourseWorksCache() -> [CourseWork] {
        // if the file exists in CourseCache
        if FileSystem.exists(file: "\(courseId)_courseWorks.json"),
           let cacheItems = FileSystem.read([CourseWork].self, from: "\(courseId)_courseWorks.json") {
            return cacheItems
        }
        return []
    }

    func writeCourseWorksCache() {
        FileSystem.write(courseCourseWorks, to: "\(courseId)_courseWorks.json") { error in
            print("Error writing: \(error.localizedDescription)")
        }
    }

    func refreshCourseWorksList(nextPageToken: String? = nil, requestNextPageIfExists: Bool = false) {
        GlassRoomAPI.GRCourses.GRCourseWork.list(params: .init(courseId: courseId),
                                                 query: .init(courseWorkStates: [.published],
                                                              orderBy: nil,
                                                              pageSize: nil,
                                                              pageToken: nextPageToken),
                                                 data: .init()
        ) { response in
            switch response {
            case .success(let success):
                DispatchQueue.main.async {
                    self.courseCourseWorks.mergeWith(other: success.courseWork,
                                                     isSame: { $0.id == $1.id },
                                                     isBefore: { $0.creationDate > $1.creationDate })
                }
                if let token = success.nextPageToken, requestNextPageIfExists {
                    self.refreshCourseWorksList(nextPageToken: token, requestNextPageIfExists: requestNextPageIfExists)
                } else {
                    DispatchQueue.main.async {
                        self.courseWorksNextPageToken = success.nextPageToken
                        self.courseWorksLoading = false
                        self.writeCourseWorksCache()
                    }
                }
            case .failure(let failure):
                print("Failure: \(failure.localizedDescription)")
                DispatchQueue.main.async {
                    self.courseWorksLoading = false
                }
            }
        }
    }

    // MARK: Course materials
    func readCourseMaterialsCache() -> [CourseWorkMaterial] {
        // if the file exists in CourseCache
        if FileSystem.exists(file: "\(courseId)_courseMaterials.json"),
           let cacheItems = FileSystem.read([CourseWorkMaterial].self, from: "\(courseId)_courseMaterials.json") {
            return cacheItems
        }
        return []
    }

    func writeCourseMaterialsCache() {
        FileSystem.write(courseCourseMaterials, to: "\(courseId)_courseMaterials.json") { error in
            print("Error writing: \(error.localizedDescription)")
        }
    }

    func refreshCourseMaterialsList(nextPageToken: String? = nil, requestNextPageIfExists: Bool = false) {
        GlassRoomAPI.GRCourses.GRCourseWorkMaterials.list(
            params: .init(courseId: courseId),
            query: .init(courseWorkMaterialStates: [.published],
                         orderBy: nil,
                         pageSize: nil,
                         pageToken: nil,
                         materialLink: nil,
                         materialDriveId: nil),
            data: .init()
        ) { response in
            switch response {
            case .success(let success):
                DispatchQueue.main.async {
                    self.courseCourseMaterials.mergeWith(other: success.courseWorkMaterial,
                                                         isSame: { $0.id == $1.id },
                                                         isBefore: { $0.creationDate > $1.creationDate })
                }
                if let token = success.nextPageToken, requestNextPageIfExists {
                    self.refreshCourseMaterialsList(nextPageToken: token, requestNextPageIfExists: requestNextPageIfExists)
                } else {
                    DispatchQueue.main.async {
                        print("REARCHED FINAL PAGE")
                        self.courseMaterialsNextPageToken = success.nextPageToken
                        self.courseMaterialsLoading = false
                        self.writeCourseMaterialsCache()
                    }
                }
            case .failure(let failure):
                print("Failure: \(failure.localizedDescription)")
                DispatchQueue.main.async {
                    self.courseMaterialsLoading = false
                }
            }
        }
    }
}
