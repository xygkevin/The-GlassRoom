//
//  SidebarOutlineMenu.swift
//  The GlassRoom
//
//  Created by Kai Quan Tay on 13/5/23.
//

import SwiftUI
import GlassRoomAPI

/// A subclass of `NSMenu` implementing the contextual menu for the project navigator
final class SidebarOutlineMenu: NSMenu {
    var outlineView: SidebarOutlineViewController

    var item: Any?

    init(sender: SidebarOutlineViewController) {
        outlineView = sender
        super.init(title: "Options")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the menu for the selected item and hides it if no item is provided.
    override func update() {
        removeAllItems()
        setupMenu()
    }
    
    /// Creates a `NSMenuItem` depending on the given arguments
    /// - Parameters:
    ///   - title: The title of the menu item
    ///   - action: A `Selector` or `nil` of the action to perform.
    ///   - key: A `keyEquivalent` of the menu item. Defaults to an empty `String`
    /// - Returns: A `NSMenuItem` which has the target `self`
    private func menuItem(_ title: String, action: Selector?, key: String = "") -> NSMenuItem {
        let mItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mItem.target = self

        return mItem
    }

    /// Setup the menu and disables certain items when `isFile` is false
    /// - Parameter isFile: A flag indicating that the item is a file instead of a directory
    private func setupMenu() {
        guard let item = item as? GeneralCourse else { return }
        switch item {
        case .group(_):
            items = [
                menuItem("Rename Group", action: #selector(renameGroup)),
                menuItem("Remove Group", action: #selector(deleteGroup)),
                menuItem("Archive Group", action: #selector(archive))
            ]
        default:
            items = [
                menuItem("Archive Course", action: #selector(archive))
            ]
        }
    }

    @objc
    func renameGroup() {
        guard let item = item as? GeneralCourse else { return }
        switch item {
        case .group(let string):
            outlineView.renamedGroup?.wrappedValue = string
        default: return
        }
    }

    @objc
    func deleteGroup() {
        guard let item = item as? GeneralCourse else { return }
        switch item {
        case .group(let string):
            outlineView.courseGroups.removeAll(where: { $0.id == string })
            outlineView.updateGroups?(outlineView.courseGroups)
        default: return
        }
    }

    @objc
    func archive() {
        guard let item = item as? GeneralCourse else { return }
        switch item {
        case .group(let string):
            // archive all courses in the group
            print("Archiving group \(string)")
        case .course(let string):
            // archive that course
            print("Archiving course \(string)")
            let config = GlobalCoursesDataManager.global.configuration
            if config.archive == nil {
                config.archive = .init(
                    id: CourseGroup.archiveId,
                    groupName: CourseGroup.archiveId,
                    groupType: .enrolled,
                    courses: [string])
            } else {
                config.archive?.courses.append(string)
                config.objectWillChange.send()
            }
            config.saveToFileSystem()
        default: return
        }
    }
}
