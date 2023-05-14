//
//  CenterSplitView.swift
//  The GlassRoom
//
//  Created by Kai Quan Tay on 13/5/23.
//

import SwiftUI
import GlassRoomAPI

struct CenterSplitView: View {
    @Binding var selectedCourse: GeneralCourse?
    @Binding var selectedPost: CoursePost?

    @State var courseAnnouncementManager: CourseAnnouncementsDataManager?
    @State var courseCourseWorksManager: CourseCourseWorksDataManager?

    @State var currentPage: CourseDisplayOption = .allPosts

    var body: some View {
        ZStack {
            if selectedCourse != nil {
                switch currentPage {
                case .allPosts:
                    if let courseAnnouncementManager, let courseCourseWorksManager {
                        MultiCoursePostListView(selectedPost: $selectedPost,
                                                announcements: .init(array: [courseAnnouncementManager]),
                                                courseWorks: .init(array: [courseCourseWorksManager]))
                    } else {
                        notImplementedYet
                    }
                case .announcements:
                    if let courseAnnouncementManager {
                        CourseAnnouncementsAdaptorView(selectedPost: $selectedPost,
                                                       announcementManager: courseAnnouncementManager)
                    } else {
                        notImplementedYet
                    }
                case .courseWork:
                    if let courseCourseWorksManager {
                        CourseCourseWorksAdaptorView(selectedPost: $selectedPost,
                                                     courseWorksManager: courseCourseWorksManager)
                    } else {
                        notImplementedYet
                    }
                }
            } else {
                ZStack {
                    Text("No Course Selected")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .top) {
            CenterSplitViewToolbarTop(currentPage: $currentPage)
        }
        .onChange(of: selectedCourse) { _ in
            reloadAnnouncements()
        }
        .onAppear {
            reloadAnnouncements()
        }
    }

    var notImplementedYet: some View {
        ZStack {
            Text("Not Implemented Yet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
        }
        .frame(maxHeight: .infinity)
    }
    
    func reloadAnnouncements() {
        guard let selectedCourse else { return }
        switch selectedCourse {
        case .course(let course):
            let selectedCourseId = course.id
            let announcementManager = CourseAnnouncementsDataManager.getManager(for: selectedCourseId)
            self.courseAnnouncementManager = announcementManager
            if announcementManager.courseAnnouncements.isEmpty {
                announcementManager.loadList(bypassCache: true)
            }
            let courseWorkManager = CourseCourseWorksDataManager.getManager(for: selectedCourseId)
            self.courseCourseWorksManager = courseWorkManager
            if courseWorkManager.courseWorks.isEmpty {
                courseWorkManager.loadList(bypassCache: true)
            }

            // TODO: Intelligently refresh
        default: return
        }
    }

    enum CourseDisplayOption: String, CaseIterable {
        case allPosts = "All Posts"
        case announcements = "Announcements"
        case courseWork = "Course Works"
    }
}

struct CenterSplitView_Previews: PreviewProvider {
    static var previews: some View {
        CenterSplitView(selectedCourse: .constant(nil), selectedPost: .constant(nil))
    }
}
