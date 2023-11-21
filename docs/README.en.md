![cover](cover.jpg)

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-ffffff) ![iPadOS 17.0+](https://img.shields.io/badge/iPadOS-17.0%2B-ffffff) ![visionOS 1.0+](https://img.shields.io/badge/visionOS-1.0%2B-ffffff) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-F05138) ![gRPC](https://img.shields.io/badge/gRPC-proto3-2ca1aa)

![wakatime](https://wakatime.com/badge/user/271fef5a-1d0a-45c6-a8f0-9fb67a1417b6/project/c213100d-56fa-45ff-8ade-7c744cf7f708.svg) + ![wakatime](https://wakatime.com/badge/user/271fef5a-1d0a-45c6-a8f0-9fb67a1417b6/project/018b704b-24a1-4f1c-ae04-fae191ff7dc8.svg)

**100% NATIVE**, multi-platform, collaborative reference manager based on SwiftUI.

[简体中文](../README.md) | **English**

## Core Features

- [x] Reference Management
  - [x] Add paper via DOI/URL
  - [x] Export citations in BibTeX, GB/T 7714, and other formats
- [x] Cross-platform, cross-device access
  - [x] View paper on Mac, iPad and Apple Vision Pro
  - [x] Use Apple Pencil on iPad to markup PDF
  - [x] Data synchronization across devices
- [x] Collaborative reading
  - [x] **Real-time synchronization** of rich-text notes
  - [x] **Real-time synchronization** of paper annotations
- [x] AI-assisted reading
  - [x] Translation
  - [x] Paper explaining, summarization, and rewriting
  - [x] Cite paper content while chatting with GPT and retaining context

For more details, please refer to the [Feature List](#Feature%20List).


## Supported Platforms

- macOS 14.0+
- iPadOS 17.0+
- visionOS 1.0+

## Development Requirements

- macOS 14.0+
- Xcode 15.0+ **(Or Xcode beta with visionOS SDK if you want to run on visionOS)**
- [protoc、protoc-gen-swift、protoc-gen-grpc-swift](https://github.com/grpc/grpc-swift#getting-the-protoc-plugins)

### Preparation

1. Clone the entire repo, including [paperpilot-common](https://github.com/Nagico/paperpilot-common) submodule

   ```shell
   git clone --recursive https://github.com/LSX-s-Software/PaperPilotApp.git
   ```

2. Rename the `team.xcconfig.template` file in the project root directory to `team.xcconfig` and fill in your `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER`.

3. Install [protoc、protoc-gen-swift、protoc-gen-grpc-swift](https://github.com/grpc/grpc-swift#getting-the-protoc-plugins), and make sure it can be used in Shell

4. **Run Xcode (Or Xcode beta) using Shell command**

   Since running Xcode directly can cause it to not inherit environment variables registered in the shell, the SwiftProtobuf plugin won't be able to find the `protoc` command during compilation. Therefore, it is necessary to run Xcode in the shell using the following command:

   ```shell
   open /Applications/Xcode.app
   ```

5. Open the project settings in Xcode and modify the `DEVELOPMENT_TEAM` and `PRODUCT_BUNDLE_IDENTIFIER` in the project targets other than `PaperPilot`.

6. Done.

## Feature List

### Projects

- Local Projects
  - No registration required
  - Offline use
  - Convert local projects into remote projects
- Remote Projects
  - Partial offline functionality
  - Automatically sync project changes, automatically resolve conflicts
  - Invite others to join projects via invitation code or link
  - Join projects created by others by entering an invitation code
  - View invitation information on the website and open Paper Pilot by URL Scheme
  - Share links with [Open Graph Protocol](https://ogp.me/) support
  - View project member list
  - Quit joined projects

### Papers

- Retrieve paper information and PDF files via URL/DOI
- Add papers from local files
- Import PDF files through drag and drop, system share sheet, etc.
- Paper List
  - Display paper title, authors, publication year, publication, event, add date, tags, read status, etc.
  - Customizable list (hide, rearrange columns, adjust column width)
  - Customizable sorting
  - Batch set read/unread status, delete papers
  - Copy paper information
  - Delete PDF files of papers to free up space
- Batch export citations in BibTeX, GB/T 7714, JSON, and CSV formats

### Paper Reader

- PDF Navigator
  - Switch navigator modes
    - PDF Outline
    - PDF Thumbnails
    - Bookmarks
    - Hide
  - Highlight the navigator based on the current page
  - Jump to a specific page through the navigator
- PDF Reader
  - Vector rendering
  - Text selection
  - Switch reading modes
    - Single page
    - Continuous single page
    - Double page
    - Continuous double page
  - Zoom
  - Link navigation
- Annotations
  - **Real-time synchronization**
  - Multiple annotation types
    - Highlight
    - Underline
    - [iPad only] Draw annotations with finger or Apple Pencil
  - Switch annotation colors
- Notes
  - **Real-time synchronization**
  - Automatically resolve conflicts
  - Rich-text (using Markdown format)
  - Adjust font size
- Search
  - Search within PDF
  - Customizable search options (case sensitivity)
  - Display search result list
  - Highlight search results in PDF
- Bookmarks
- Paper text translation
  - Automatic language detection
  - Automatically remove PDF line breaks
- Reading Timer

### AI Features

- **AI-assisted reading**
  - Paper explaining, translation, summarization, rewriting
  - Quote paper content in chat
  - Free-form chat
  - Retain the most recent 10 conversations as context

### Users

- Register and log in
- Customizable avatar

### Settings

- Display server status
- View local file space usage
- Clean local files
- Clear all data

### System Adaptations

- Follow Apple's Human Interface Guidelines and the system's interface styles
- List right-click/long-press menu (aka. context menu)
- Size-adjustable and hidable sidebar
- Perform common operations via macOS's menu bar and shortcuts
- Add papers and PDF files via drag-and-drop
- Support opening the paper reader in the same or new window on iPadOS
- Use PencilKit on iPadOS to support drawing annotations with Apple Pencil
- Use Ornament on visionOS to display detailed paper information
- Support searching projects and papers via Spotlight
- Support importing PDF files via the system's share sheet
- Launch via URL Scheme
- Dark mode
- Use SwiftData for data persistence
- Internationalization (i18n)
  
  - [x] English
  
  - [x] Simplified Chinese

### Others

- Asynchronous execution for time-consuming operations, with progress bar/activity indicator shown
- Play transition animations when controls appear/disappear
