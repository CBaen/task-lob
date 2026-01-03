# PocketBase Setup

PocketBase is our backend - a single executable that provides database, auth, and real-time subscriptions.

## Installation

1. Download PocketBase from: https://pocketbase.io/docs/
2. Extract to this folder
3. Run: `./pocketbase serve`
4. Admin UI: http://127.0.0.1:8090/_/

## First Time Setup

1. Start PocketBase
2. Go to http://127.0.0.1:8090/_/
3. Create admin account
4. Import the schema below

## Schema

Import `schema.json` via the Admin UI (Settings > Import collections)

Or create collections manually:

### users (extends built-in auth)
Already exists. We'll extend with:
- `display_name` (text)
- `role` (text) - for future team roles

### workspaces
Team/company workspace.
- `name` (text, required)
- `owner` (relation → users)
- `website_url` (url)
- `created` (autodate)

### tasks
The core task model.
- `raw_input` (text) - original voice/text
- `lob_session` (relation → lob_sessions)
- `position_in_lob` (number)
- `classification` (select: task, self_service, reminder, venting)
- `urgency` (select: normal, urgent, deadline)
- `deadline` (date)
- `system_name` (text) - learned system
- `summary` (text)
- `current_state` (text)
- `desired_outcome` (text)
- `missing_info` (json) - array of questions
- `sender` (relation → users)
- `owner` (relation → users)
- `court_user` (relation → users)
- `court_reason` (text)
- `status` (select: draft, sent, active, blocked, done)
- `ai_research` (json)
- `ai_suggested_plan` (json)
- `context_injected` (json)
- `resolution_notes` (text)
- `workspace` (relation → workspaces)
- `created` (autodate)
- `updated` (autodate)

### threads
Task conversation history.
- `task` (relation → tasks)
- `type` (select: message, status_change, court_flip, system, research)
- `actor` (relation → users, nullable for system/ai)
- `actor_type` (select: user, ai, system)
- `content` (text)
- `created` (autodate)

### lob_sessions
Groups tasks that came from a single input.
- `raw_input` (text)
- `sender` (relation → users)
- `workspace` (relation → workspaces)
- `created` (autodate)

### company_brain
The learning memory.
- `workspace` (relation → workspaces)
- `memory_type` (select: system, person, product, vocabulary, routing, resolution, website, timeline)
- `key` (text) - what this is about
- `value` (json) - details
- `confidence` (number) - 0.0 to 1.0
- `learned_from` (relation → tasks, multiple)
- `times_confirmed` (number)
- `times_used` (number)
- `last_used` (date)
- `created` (autodate)
- `updated` (autodate)

### resolutions
What fixes worked.
- `workspace` (relation → workspaces)
- `problem_pattern` (text)
- `solution` (text)
- `system_name` (text)
- `resolved_by` (relation → users)
- `task` (relation → tasks)
- `times_suggested` (number)
- `times_worked` (number)
- `created` (autodate)

### website_cache
Cached website content for Company Brain.
- `workspace` (relation → workspaces)
- `url` (url)
- `page_title` (text)
- `content_summary` (text)
- `keywords` (json) - array
- `last_crawled` (date)
- `created` (autodate)
- `updated` (autodate)

## API Rules

Set these in PocketBase Admin:

### tasks
- List/View: @request.auth.id != "" && workspace.owner = @request.auth.id
- Create: @request.auth.id != ""
- Update: @request.auth.id != "" && (sender = @request.auth.id || owner = @request.auth.id)

### threads
- List/View: @request.auth.id != "" && task.workspace.owner = @request.auth.id
- Create: @request.auth.id != ""

(Similar patterns for other collections - users can access their workspace's data)

## Real-time

PocketBase supports real-time subscriptions out of the box.
Flutter app will subscribe to task updates for live "Court" changes.
