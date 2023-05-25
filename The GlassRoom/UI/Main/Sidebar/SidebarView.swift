//
//  SidebarView.swift
//  The GlassRoom
//
//  Created by Kai Quan Tay on 13/5/23.
//

import SwiftUI
import GlassRoomTypes

struct SidebarView: View {
    @Binding var selection: GeneralCourse?
    @ObservedObject var coursesManager: GlobalCoursesDataManager = .global

    @State var renamedGroup: String?

    var body: some View {
        SidebarOutlineView(
            selectedCourse: $selection,
            renamedGroup: $renamedGroup,
            courses: coursesManager.courses
        )
        .overlay {
            if coursesManager.courses.isEmpty {
                VStack {
                    Text("No Courses")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if coursesManager.loading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(maxWidth: .infinity)
                    .padding(10)
            }
        }
        .sheet(item: $renamedGroup) { item in
            RenameCourseGroupView(groupString: item)
        }
    }
}

extension Course: Identifiable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension String: Identifiable {
    public var id: String { self }
}

struct SidebarCourseView: View {
    var course: GeneralCourse

    @ObservedObject var coursesManager: GlobalCoursesDataManager = .global
    @ObservedObject var configuration: GlobalCoursesDataManager.CoursesConfiguration =
        GlobalCoursesDataManager.global.configuration

    var body: some View {
        ZStack {
            content
        }
    }

    @ViewBuilder
    var content: some View {
        switch course {
        case .course(let string):
            if let course = coursesManager.courseIdMap[string] {
                let postsManager = CoursePostsDataManager.loadedManagers[string]
                HStack {
                    configuration.colorFor(course.id)
                        .frame(width: 6)
                        .cornerRadius(3)
                        .padding(.vertical, 3)
                    VStack {
                        HStack {
                            Text(configuration.nameFor(course.name))
                                .lineLimit(1)
                            Spacer()
                        }
                        if let description = course.description {
                            HStack {
                                Text(description)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                Spacer()
                            }
                        }
                    }
                }
                .opacity((postsManager == nil || postsManager!.postDataIsEmpty) ? 0.4 : 1)
            } else {
                Text("Invalid Course")
            }
        case .allTeaching, .allEnrolled:
            let title = course == .allTeaching ? "Teaching" : "Enrolled"
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 5)
            .disabled(true)
        case .group(let string):
            if string == CourseGroup.archiveId {
                HStack {
                    Text("Archive")
                        .bold()
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 5)
                .disabled(true)
            } else if let group = configuration.groupIdMap[string] {
                HStack {
                    Image(systemName: "folder.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .offset(x: 3)
                        .foregroundColor(.accentColor)
                        .disabled(true)
                    VStack {
                        HStack {
                            Text(group.groupName)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            } else {
                Text("Invalid course group")
            }
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selection: .constant(nil))
    }
}
