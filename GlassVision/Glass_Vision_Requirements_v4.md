# Glass Vision — AI-Agent-Ready Requirements Spec (v4)

## 1. Project Overview

**Title:** Glass Vision  
**Platform:** Apple Vision Pro  
**OS Target:** visionOS 26  
**App Mode:** Immersive Space
**Presentation Mode:** Mixed immersion only for MVP; do not use full immersion for gameplay

**Concept:**  
Glass Vision is a mixed-reality hidden-object game built for Apple Vision Pro. The player stands in their real room and uses a handheld antique-looking glass to reveal a hidden virtual world that is visible **only inside the circular lens opening**. The player searches that hidden world for target objects, confirms finds with **gaze + pinch**, and extracts discovered items into mixed reality where they are displayed on a pedestal.

This document is intended to be the **primary implementation spec for AI coding agents**. It should be treated as a build directive, not just a brainstorm.

---

## 2. Product Pillars

1. **Portal-first mixed reality**  
   The game must feel fundamentally different from a normal hidden-object game by making the hidden world exist only through the glass.

2. **Native Vision Pro interaction**  
   The core interaction should feel spatial, tactile, stable, and comfortable.

3. **Elegant magical presentation**  
   The experience should feel premium, antique, magical, and polished.

4. **Long-term extensibility**  
   The first implementation must be modular and data-driven so additional puzzles can be added without reworking core systems.

---

## 3. Core Fantasy

The player:
- launches the app,
- selects a puzzle or daily puzzle,
- enters an immersive space,
- sees a pedestal in front of them with an antique looking glass resting on it,
- picks up the looking glass by the handle,
- sees a hidden virtual world appear inside the circular opening,
- scans around the environment by physically moving the glass,
- finds and selects hidden objects using gaze + pinch,
- watches each discovered object get pulled out of the portal world and placed onto the pedestal as a trophy.

Outside the lens, the player continues seeing their real environment.

---

## 4. Final Product Decisions

These decisions are locked unless explicitly changed later.

### 4.1 App Title
- **Glass Vision**

### 4.2 Visual Direction
- **Antique magical**
- Premium brass / wood / aged metal style
- First puzzle should feel like a **wizard study**
- Tone should be **cozy, mysterious, and whimsical**, not horror and not photorealistic realism

### 4.3 Input / Selection
- Selection is **gaze + pinch**
- No hint system in MVP
- No countdown timer pressure during active play
- Completion time is tracked for stats / leaderboard readiness

### 4.4 Looking Glass Rules
- Portal is **active only while held**
- On release, the looking glass **snaps back to the pedestal**
- Must support holding in **either hand** from day one

### 4.5 UX Rules
- Checklist is pedestal-mounted by default
- Silhouettes are used for target presentation
- Found items visibly update on the checklist
- Found items are removed from the hidden world and appear on the pedestal

### 4.6 Production Direction
- Prioritize **clean architecture first**
- Use **placeholder assets first where needed**
- Prove interaction and gameplay loop before spending time on polish

### 4.7 Presentation Mode Decision
- MVP gameplay must run in an **ImmersiveSpace** using **mixed immersion** presentation
- Do **not** implement MVP gameplay as full immersion
- Do **not** rely on progressive/full immersion as the default gameplay path
- Outside the lens, the player must continue seeing passthrough / real surroundings
- A different immersion mode may be explored later for alternate experiences, but it is out of scope for MVP

---

## 5. MVP Scope

### 5.1 Must Have
- Menu flow with:
  - Daily Puzzle
  - Puzzle Select
- Immersive space entry
- Pedestal in front of player
- Grabbable looking glass
- Portal effect active only while held
- One authored puzzle environment: **Wizard Study**
- 10 target objects
- Silhouette checklist
- Gaze + pinch selection
- Extraction animation from portal world to pedestal
- Puzzle completion summary
- Data-driven puzzle format
- Local stat tracking for completion time
- Debug tools for portal and selection validation
- On-device feasibility gate proving: grab glass -> circular portal -> stable hidden world -> collectible through portal

### 5.2 Nice to Have
- Multiple puzzles
- Tutorial puzzle
- Decoy items
- Stronger VFX / audio polish
- Local best times
- Daily puzzle rotation logic

### 5.3 Explicitly Out of Scope
- SharePlay / multiplayer
- Full online leaderboard backend
- UGC editor
- Live content service
- Campaign narrative
- Multiple-room puzzle journeys

---

## 6. Required Player Flow

1. Launch app.
2. Choose:
   - Daily Puzzle
   - Puzzle Select
3. Enter immersive space.
4. Pedestal is placed comfortably in front of player.
5. Looking glass is visible on pedestal.
6. Player grabs looking glass.
7. Portal activates.
8. Hidden world is visible only through lens opening.
9. Player scans environment and references checklist.
10. Player gazes at valid target and pinches.
11. Valid item is collected and moved to pedestal.
12. Checklist updates.
13. Repeat until all 10 items are collected.
14. Completion summary appears.
15. Player can replay, return to menu, or choose next puzzle if available.

---

## 7. Spatial Setup Rules

### 7.1 Player Start Layout
At puzzle start:
- The player is oriented toward a pedestal placed at comfortable reach distance in front of them.
- Pedestal should be centered in the player’s forward field.
- Initial placement should avoid requiring immediate body turning or arm strain.

### Recommended ergonomic targets
- Pedestal center approximately 0.8m to 1.2m in front of player
- Main UI mounted at comfortable reading height
- Collection display near pedestal, not far off to the side

### 7.2 Hidden World Anchoring
This is locked for v1:
- The hidden portal world is anchored to the **player’s puzzle-start world origin**.
- It does **not** drift with the glass.
- It does **not** re-center dynamically while the puzzle is active.
- Pedestal and hidden world should share a stable common spatial frame derived at puzzle start.

### 7.3 Anchor Strategy
Implementation should create one stable root anchor for the puzzle session and parent both:
- the pedestal / gameplay presentation layer, and
- the hidden world target scene,

to a common runtime-controlled world-space frame.

Do **not** continuously rebuild this origin while the puzzle is active.

### 7.4 Physical Play Envelope
This is locked for MVP:
- The game is designed as a **standing, mostly-in-place experience**
- The player is expected to rotate naturally and take at most small comfort steps, not walk the room
- Puzzle authoring must assume the player’s feet remain approximately near their start position
- The pedestal remains in the forward presentation zone and is not placed behind the player

### 7.5 Authoring Bounds for Wizard Study
For the first puzzle, all authored target placements must stay within these comfort bounds relative to puzzle origin:
- radial distance: approximately **0.8 m to 2.2 m**
- preferred distance band for most targets: **1.0 m to 1.8 m**
- vertical band: approximately **0.6 m below eye level to 0.5 m above eye level**
- at least **70%** of targets should be discoverable without requiring the player to bend, crouch, or look steeply overhead
- no required target may be placed directly under the player, directly above the head, or farther than the comfort radius

### 7.6 Angular Coverage Rule
The environment may use broad angular coverage, but MVP content should be authored for comfort:
- the first puzzle may use up to **270°** of meaningful search coverage
- at least **60%** of required targets should live within the forward **180°** arc
- the player should never need to repeatedly spin in full circles to play efficiently

---

## 8. Looking Glass Specification

### 8.1 Object Description
The looking glass is the hero interaction object:
- circular frame,
- visible lens opening,
- handle,
- antique material treatment,
- comfortable size for one-handed use.

### 8.2 Required States
The looking glass state machine must include:
- `idleOnPedestal`
- `hoverAvailable`
- `grabbed`
- `portalActive`
- `releasedReturning`
- `disabledTransition`

Portal activation should only occur in `grabbed` / `portalActive`.

### 8.3 Required Behaviors
- Can be grabbed with either hand
- Pose follows held hand stably
- Portal activates on successful grab
- Portal deactivates immediately on release
- Release triggers return animation back to pedestal
- While returning, object cannot be re-grabbed until stable

### 8.4 Interaction Implementation Rule
The handle is the primary interaction target. The app should not depend on the entire frame being equally grabbable. Use a dedicated interaction collider for the handle so grab targeting is stable and predictable.

### 8.5 Acceptance Criteria
- User can grab the glass reliably in under 1 attempt on average
- Held motion feels visually stable with no obvious lag or swimming
- Release always deactivates portal
- Release always returns glass to pedestal
- Glass never gets stranded in space
- Glass cannot remain “active” while sitting on pedestal

---

## 9. Portal Rendering Requirements

### 9.0 Feasibility Gate
Before broad implementation begins, the agent must prove the core illusion on **physical Apple Vision Pro hardware**. Simulator results are not sufficient to clear this gate.

The feasibility slice is successful only if all are true:
1. user can grab the glass reliably,
2. the portal appears only inside a circular handheld lens region,
3. the hidden world remains visually stable in world space while the hand moves,
4. passthrough remains the dominant presentation outside the lens, and
5. at least one collectible can be targeted and collected through the portal.

If this gate is not met, the agent must stop broad feature work and iterate on portal/input implementation first.

### 9.1 Core Requirement
Only the interior of the circular lens opening reveals the hidden world.

Outside the lens:
- user sees passthrough / real environment,
- hidden world is not visible.

### 9.2 Preferred Technical Approach for v1
Use RealityKit’s portal system as the **first implementation path**.

Preferred setup:
1. Build the looking glass lens opening as a dedicated portal surface entity.
2. Give that entity:
   - a `ModelComponent` using the actual circular lens mesh,
   - a `PortalComponent` targeting the hidden-world root entity.
3. Keep the hidden-world root stable in puzzle/world space.
4. Parent the portal surface to the held looking glass so the portal opening follows the player’s hand.
5. Keep all hidden-world content as descendants of the portal target world, not mixed into the visible “real-side” hierarchy.

### 9.3 Portal Technical Constraints
- The portal shape must match the lens opening, not a large rectangular proxy, unless used temporarily for debugging.
- The portal surface and the decorative glass frame must be separate entities.
- The decorative frame may remain visible in the player’s real-space layer.
- The hidden world must not be directly visible outside the portal.
- Portal implementation must live in a dedicated subsystem, not spread through unrelated view code.

### 9.4 Approved Fallback Order
If the ideal portal implementation is blocked or unstable, use this fallback order:

#### Fallback A — Circular portal proof using simplified art
Keep the real portal implementation, but reduce visual complexity:
- simplified lens mesh,
- simplified hidden world,
- simplified lighting,
- minimal transparency usage.

#### Fallback B — Debug reveal mode
Temporarily use a non-final reveal system that still proves:
- hidden world stability,
- glass-relative reveal behavior,
- target visibility validation,
- end-to-end gameplay loop.

#### Fallback C — Development-only rectangular reveal
Only for debugging, allow a temporary rectangular or obviously non-final portal surface if needed to validate engine behavior before restoring the circular lens.

### 9.5 Explicit Non-Goals for v1 Portal
Do not spend MVP time on:
- objects physically crossing through the portal,
- bidirectional world transfer systems,
- dynamic portal relocation between unrelated spaces,
- advanced portal recursion,
- custom compositor-level rendering unless RealityKit portal behavior proves fundamentally insufficient.

### 9.6 Portal Acceptance Criteria
- When glass is not held, hidden world is not visible.
- When glass is held, hidden world appears only inside lens region.
- Moving the glass around reveals different parts of the world consistently.
- Portal does not visibly drift relative to hidden world.
- Turning body or moving hand does not break the illusion.
- Portal activation/deactivation never leaves stale content on screen.

---

## 10. Hidden Object Gameplay Rules

### 10.1 Puzzle Composition
Each puzzle contains:
- exactly 10 target items for MVP,
- optional decoys,
- one environment scene,
- one set of authored object placements.

### 10.2 Visibility / Fairness Rules
For the first puzzle:
- all 10 target items are present from the start,
- no staged unlocking,
- objects may be partially obscured, but still reasonably identifiable,
- no heavy animation that makes objects frustrating to select.

### 10.3 Object Persistence Rules
- Before collection: item exists in hidden world.
- After collection: item is removed from hidden world.
- After collection: item appears on pedestal as collected display item.
- Item cannot be collected twice.

### 10.4 Decoys
- Decoys are optional for MVP.
- Incorrect decoy selection should produce gentle invalid feedback.
- No penalty system in MVP.

---

## 11. First Puzzle Definition — Wizard Study

This is locked for the first implementation.

### 11.1 Puzzle Metadata
- Puzzle ID: `wizard_study_001`
- Display Name: `Wizard Study`
- Theme: `wizard_study`
- Difficulty: `normal`

### 11.2 Environment Tone
- Cozy magical study
- Warm lighting
- Shelves, books, candles, potion equipment, desk clutter, arcane props
- Slightly whimsical rather than dark or scary

### 11.3 First 10 Target Items
1. **Feather Quill**
2. **Hourglass**
3. **Crystal Ball**
4. **Potion Bottle**
5. **Spell Book**
6. **Key**
7. **Candle**
8. **Wand**
9. **Moon Charm**
10. **Tiny Dragon Figurine**

### 11.4 Placement Guidance
- Distribute items around the 360° space.
- Use varied vertical placement.
- Include a mix of near, mid, and farther distances.
- Ensure silhouettes are readable.
- Avoid placing too many small items in visually noisy shelf clusters.

### 11.5 Authoring Rule
The first pass may use placeholder meshes matching these silhouettes, but IDs and placements must be authored as if they are final gameplay objects.

---

## 12. Checklist / Target UI

### 12.1 Required Presentation
- Checklist lives on or directly above the pedestal.
- Visible by default during gameplay.
- Shows all 10 target items as silhouettes.
- Found items clearly transition to completed state.

### 12.2 Completed State
A found item should:
- become illuminated, filled, checked, or otherwise visibly complete,
- no longer appear as pending.

### 12.3 Optional Secondary Behavior
The checklist may support expand / inspect behavior later, but MVP should keep it simple and always available.

### 12.4 Acceptance Criteria
- Player can always tell what remains to be found.
- UI is readable from intended play position.
- Progress count updates immediately after collection.
- Completed silhouettes are visually unmistakable.

---

## 13. Selection / Eligibility Rules

This section is intentionally strict so agents do not invent inconsistent selection logic.

### 13.1 A target is collectible only if all conditions are true
1. Item belongs to current puzzle target list.
2. Item is not already found.
3. Item is currently visible through the portal.
4. Item is the current gaze-targeted candidate.
5. Pinch occurs while item remains eligible.
6. Collection lock has not already been triggered for that item.

### 13.2 Portal Visibility Rule
For MVP, use this rule:
- The item’s projected center must fall inside the portal circle.
- A configurable threshold of projected bounds overlap with the circle must also be met.

Default threshold target for first implementation:
- projected center inside circle,
- and approximately **50% or more** of projected screen-space bounds overlapping the portal region.

This threshold should be configurable in code for tuning.

### 13.3 Engine-Level Gaze Resolution Rule
Selection is a two-stage process:
1. Resolve a **portal interaction sample** from the player’s gaze / targeted interaction path. The portal surface may be the first obvious hit target, and that is acceptable.
2. Convert that sample into hidden-world candidate evaluation inside the portal subsystem. The collectible is chosen from eligible hidden-world targets, not from the portal frame mesh itself.

The portal frame, handle, and decorative glass geometry must never be treated as collectible candidates.

### 13.4 Hidden-World Occlusion Rule
A target is collectible only if it is not meaningfully occluded by hidden-world geometry at the sampled portal view position.
- Mere overlap with the lens circle is **not** sufficient.
- If the item’s center is inside the portal but the item is blocked by hidden-world props, shelves, books, or other authored geometry, the item is **not** eligible.
- Agents must perform an occlusion-aware visibility check inside the hidden world before confirming eligibility.

### 13.5 Candidate Resolution Rule
If multiple valid collectibles overlap:
- prefer the current gaze-resolved hidden-world candidate,
- if still ambiguous, prefer the object with greatest portal-overlap score,
- if still ambiguous, prefer the nearest valid object along the hidden-world query direction.

### 13.6 Pinch Confirmation Rule
- Pinch should trigger collection immediately when eligibility is valid.
- No dwell timer required in v1.
- Dwell may exist as a debug-tunable option, but default behavior is immediate pinch confirmation.

### 13.7 Invalid Selection Behavior
If pinch occurs but no valid collectible exists:
- do not collect anything,
- provide subtle invalid feedback,
- do not punish the player.

### 13.8 Interaction Detection Rule
Do not make collectible success depend exclusively on the portal mesh itself receiving taps. The collectible system should own eligibility resolution and treat gestures as confirmation input, not as the sole source of truth for target validity.

### 13.9 Acceptance Criteria
- One pinch collects at most one item.
- Invalid pinch never collects an item.
- Already found items cannot be recollected.
- Items near portal edge behave consistently.
- Eligibility logic is debuggable with overlays and logs.

---

## 14. Collection / Pedestal Rules

### 14.1 Required Behavior
On successful collection:
- item highlights,
- success feedback plays,
- item transitions out of hidden world,
- item animates to pedestal,
- item snaps into assigned collection slot,
- checklist updates.

### 14.2 Collection Display
- Collected items should remain visible on pedestal.
- Use fixed slots or a clean staged layout.
- Layout should visually fill up as progress grows.

### 14.3 Slotting Rule
Collection display slots must be deterministic and puzzle-data-backed. Do not auto-scatter collected items randomly in final MVP behavior.

### 14.4 Acceptance Criteria
- Every collected item appears on pedestal.
- Item is visually removed from hidden world.
- Slotting is stable and deterministic.
- Collected display never overlaps in a broken way.

---

## 15. Completion Rules

### 15.1 Completion Trigger
Puzzle completes immediately after 10th valid item is collected.

### 15.2 Completion Behavior
- Search state ends.
- Selection input is disabled.
- Completion summary appears.
- Completion time is recorded.
- Player is offered:
  - Replay
  - Return to Menu
  - Next Puzzle (when applicable)

### 15.3 Completion Summary Must Show
- Puzzle name
- 10 / 10 found
- Completion time
- Daily or library mode context

### 15.4 Replay Reset Rule
Replay must tear down and rebuild runtime puzzle state from authoritative puzzle data. Do not attempt to “manually un-collect” all live entities back into place as the main reset path.

### 15.5 Acceptance Criteria
- Completion triggers exactly once.
- Timer / stat stops correctly.
- No additional items can be collected after completion.
- Replay cleanly resets state.

---

## 16. Lifecycle, Interruptions, and Recovery

### 16.1 General Rule
The app must treat immersive-space dismissal, app inactivity, tracking changes, and world recenter events as first-class runtime events. The glass, portal, and puzzle runtime must never remain in an undefined state across transitions.

### 16.2 Immersive Space Exit / Dismissal
If the immersive space is dismissed for any reason:
- the portal deactivates immediately,
- the looking glass exits the held state immediately,
- no puzzle interaction continues while the space is not active,
- the runtime may either return to menu state or preserve resumable puzzle state, but the choice must be explicit and deterministic.

For MVP, the locked behavior is: **dismiss immersive space -> return to menu shell; active puzzle run is abandoned unless explicitly resumed later**.

### 16.3 App Background / Inactive State
When the app or active scene becomes inactive:
- suspend puzzle interaction,
- disable new collections,
- force portal to non-interactive state,
- stop time accumulation for the active run until the experience is valid again.

### 16.4 Tracking Interruption / Anchor Degradation
If world tracking or the stable puzzle anchor becomes unavailable, limited, or invalid:
- freeze collectible eligibility,
- deactivate the portal presentation if the illusion can no longer be trusted,
- present lightweight recovery UI or state,
- revalidate anchors before resuming interaction.

### 16.5 Recenter / Origin Shift Rule
MVP must treat world recenter as a controlled interruption.
- After recenter, the app must rebuild or remap the stable puzzle-space root in a deterministic way
- The hidden world and pedestal must remain mutually consistent after recovery
- The app must not leave the glass visually active against stale world coordinates

### 16.6 Glass Held During Transition
If the glass is held during dismissal, recenter, or interruption:
- drop the held state immediately at the runtime level,
- deactivate the portal,
- on recovery, return the glass to pedestal state rather than trying to restore a mid-air held transform.

## 17. Daily Puzzle and Puzzle Library

### 17.1 Daily Puzzle Mode
For MVP:
- daily puzzle resolves locally with **no backend**.
- the date basis is the player’s **current local calendar day on device**.
- the daily puzzle key should be generated from local year-month-day in the current system calendar and time zone.
- all runs started on the same local calendar date resolve to the same daily puzzle ID on that device.

Because MVP ships with exactly one authored puzzle, the locked behavior is:
- **Daily Puzzle** resolves to `wizard_study_001`.
- **Puzzle Select** also resolves to `wizard_study_001`.
- the two menu paths are different presentation paths into the same gameplay content until more puzzles exist.

### 17.2 Puzzle Select Mode
- User can select authored puzzles from library.
- Each puzzle should expose:
  - title,
  - theme,
  - difficulty,
  - thumbnail if available,
  - completion status if tracked locally.

### 17.3 Future Expansion Rule
When multiple puzzles exist later, Daily Puzzle may resolve by deterministic local date mapping across the authored puzzle set, but MVP must not pretend to support rotation it does not actually have.

---

## 18. Data Model / Content Pipeline

### 18.1 Content Rule
Puzzles must be data-driven, not hardcoded.

### 18.2 Recommended File Structure
Use one content definition file per puzzle.

Example:
- `Puzzles/wizard_study_001.json`
- `Scenes/WizardStudy.reality` or `Scenes/WizardStudy.usda`
- `Assets/Collectibles/...`

### 18.3 Puzzle Definition Schema
Each puzzle definition should include at minimum:
- `id`
- `displayName`
- `theme`
- `environmentSceneID`
- `difficulty`
- `targetItems`
- `decoyItems`
- `dailyAvailability`
- `audioProfile`
- `collectionSlotLayout`
- `spawnRootID`
- `portalProfileID`
- `statsProfileID`

Each target item should include:
- `itemID`
- `displayName`
- `assetID`
- `silhouetteAssetID`
- `worldTransform`
- `boundsProfile`
- `selectionPriority`
- `pedestalSlotID`
- `isDecoy`

### 18.4 Authoring Coordinate Rule
Target placements should be authored in the hidden world’s stable puzzle coordinate space.

Do not hardcode placements in gameplay logic unless as temporary placeholder bootstrap content.

### 18.5 Scene Binding Rule
Preferred content pipeline for MVP:
- authored scene contains named marker entities or authored target placeholders,
- runtime loads puzzle definition,
- runtime binds puzzle item records to authored scene nodes by stable IDs,
- runtime registers those bound entities with the collectible system.

This is preferred over burying gameplay truth inside arbitrary scene hierarchy assumptions.

### 18.6 Runtime Rule
At runtime:
- load puzzle definition,
- load environment scene,
- spawn or bind target items by ID,
- register all targets with selection system,
- initialize UI from puzzle data.

---

## 19. System Architecture Requirements

### 19.1 Required Major Systems
Separate the app into clear modules:
- App Flow Manager
- Menu / Puzzle Selection System
- Immersive Experience Coordinator
- Looking Glass Interaction System
- Portal Rendering System
- Puzzle Runtime / Game State Manager
- Collectible Registry
- Selection Validation System
- Collection Pedestal System
- UI / HUD System
- Audio Feedback System
- Puzzle Data Loader
- Daily Puzzle Resolver
- Stats / Leaderboard-Ready Layer
- Debug Overlay / Developer Tools

### 19.2 Architecture Rule
Gameplay truth must live in centralized runtime state, not scattered across entity state and UI state.

### 19.3 State Requirements
Runtime state should track at minimum:
- current mode,
- selected puzzle ID,
- puzzle start time,
- elapsed time,
- found item IDs,
- remaining item IDs,
- held glass state,
- current gaze target,
- current eligible target,
- completion state.

### 19.4 Engineering Constraints
These rules are locked for implementation quality:
- Do not encode gameplay truth only in RealityKit components.
- Do not make core gameplay depend on ad hoc view-local state.
- Avoid puzzle-specific branching in shared systems.
- All tuning values must be config-backed or centralized constants.
- Keep rendering concerns separate from gameplay truth.
- Build all systems so placeholder content can be swapped without architectural rewrites.
- Prefer deterministic reset / rebuild over incremental cleanup hacks.

### 19.5 Debug Requirements
Must include toggles for:
- portal circle visualization,
- projected collectible bounds,
- overlap score,
- gaze target display,
- eligible target display,
- force collect current target,
- force complete puzzle,
- jump to puzzle,
- show pedestal slot IDs.

---

## 20. Input and Interaction Technical Rules

### 20.1 Entity Input Requirements
Any entity intended to receive RealityKit-targeted gestures must have:
- valid collision shapes,
- input targeting enabled,
- appropriately sized interactive geometry.

### 20.2 Gesture Ownership Rule
Use targeted spatial gestures for RealityView interaction. However, gameplay confirmation should be interpreted by gameplay systems, not directly hardwired into individual mesh callbacks.

### 20.3 Hover / Focus Rule
Targets should support soft hover/focus affordances where useful, but hover visuals must never incorrectly imply collectibility when an item fails portal-visibility requirements.

### 20.4 Grab Reliability Rule
If the default manipulation experience causes unstable or overly broad grabbing, the implementation may switch to a custom grab interaction model that still feels natural, provided the player-facing behavior remains:
- easy handle pickup,
- smooth one-handed movement,
- reliable release,
- support for either hand.

---

## 21. Stats Requirements

### 21.1 Local Stats for MVP
Track at minimum:
- total puzzle completions,
- best completion time per puzzle,
- most recent completion time per puzzle,
- whether the daily puzzle was completed on a given local date.

### 21.2 Future Compatibility Rule
Stats storage should be local-first but shaped so an online leaderboard layer can be added later without redesigning puzzle completion events.

---

## 22. Audio Requirements

### 22.1 Must Have
- glass pickup
- portal activation
- invalid selection
- valid selection
- extraction
- completion

### 22.2 Desired
- soft magical ambient loop
- subtle target-centering feedback
- pedestal collection flourish

Audio implementation can remain lightweight in first pass, but event hooks should exist from day one.

---

## 23. Non-Functional Requirements

### 23.1 Performance
- Held glass must feel stable.
- Portal rendering must not visibly judder.
- Puzzle scene must run comfortably on Vision Pro.

### 23.1.1 Wizard Study MVP Content Budgets
These are hard authoring budgets for MVP so content does not undermine portal stability:
- exactly **10 required targets**.
- keep required targets to **one primary mesh/entity each** where practical.
- avoid large counts of independently animated props in the hidden world; decorative ambient animation should be sparse and optional.
- avoid particle-heavy effects inside the portal during core gameplay.
- avoid excessive transparent, refractive, or layered materials in the hidden world, especially near dense shelves or target clusters.
- prefer baked or simple lighting setups over dynamically expensive lighting stacks for MVP.
- treat the portal view as the highest-priority rendering budget; decorative scene complexity must yield before portal clarity and hand-held stability.

### 23.2 Reliability
- No duplicate collection.
- No soft-lock on drop / release.
- No stale completion state.
- No active portal while glass is idle.

### 23.3 Maintainability
- New puzzles should be addable by content definition.
- Core systems must be reusable.
- Agents should avoid puzzle-specific special cases in runtime logic.

---

## 24. Build Order Rules for AI Agents

Agents must follow this implementation order unless blocked by a technical dependency.

### Phase 1 — Core Shell
- App flow
- Menu flow
- Immersive space entry
- Pedestal placement

### Phase 2 — Looking Glass Interaction
- Spawn glass
- Grab / hold / release state machine
- Snap-back return behavior

### Phase 3 — Portal Prototype
- Stable hidden world anchor
- Lens-aligned portal rendering prototype
- Validate reveal behavior

### Phase 4 — One Collectible End-to-End
- Register one test collectible
- Gaze + pinch selection
- Eligibility math
- Collect to pedestal

### Phase 5 — Full Puzzle Loop
- Load full Wizard Study puzzle
- All 10 items
- Checklist
- Progress tracking
- Completion summary

### Phase 6 — Content / Feedback Polish
- Audio hooks
- VFX polish
- Better assets
- Better slotting / presentation

Agents should **not** spend significant time on polish before the full 10-item gameplay loop works.

---

## 25. Validation and Test Plan

### 25.1 Minimum Manual Test Matrix
Test all of the following before calling MVP complete:
- grab with left hand,
- grab with right hand,
- repeated pick up / release cycles,
- collect near center of lens,
- collect near lens edge,
- invalid pinch on non-target,
- invalid pinch on already found item,
- replay after completion,
- switch from daily puzzle flow to puzzle select flow,
- restart app and verify local stat persistence.

### 25.2 Debug Acceptance
If a portal or selection bug occurs, developers must be able to answer:
- what entity was targeted,
- whether the entity was eligible,
- overlap score,
- whether item was already found,
- whether portal state was active,
- what collection slot was assigned.

---

## 26. Definition of Done

The MVP is considered done when all of the following are true:

1. User can launch app and choose Daily Puzzle or Puzzle Select.
2. User enters immersive space and sees pedestal in front of them.
3. User can pick up the looking glass with either hand.
4. Portal activates only while held.
5. Hidden world is visible only through the lens region.
6. Wizard Study puzzle loads successfully.
7. Checklist shows 10 silhouettes.
8. User can find and collect each of the 10 target items with gaze + pinch.
9. Collected items appear on pedestal.
10. Checklist updates correctly.
11. Completion triggers exactly once after final item.
12. Completion time is recorded.
13. Replay resets puzzle correctly.
14. Debug tools exist for portal / target / overlap validation.
15. Code structure is modular enough for a second puzzle to be added without rewriting core gameplay.

---

## 27. Risks / Watchouts

1. **Portal rendering feasibility** is the largest technical risk.
2. Selection near lens edge may require tuning.
3. Small objects may need silhouette exaggeration for readability.
4. Hidden world authoring must avoid visual clutter that destroys search fairness.
5. Runtime / authored scene integration must stay clean and data-driven.
6. Transparency-heavy materials inside or near the portal may complicate rendering behavior and should be minimized in MVP.

---

## 28. Temporary Implementation Assumptions

If a detail is not yet fully art-directed, assume:
- placeholder assets are acceptable,
- wizard study is warm and whimsical,
- checklist remains visible on pedestal,
- immediate pinch confirmation is correct,
- no penalties for wrong pinches,
- all 10 items are active from the start,
- first pass uses local content only,
- architecture quality matters more than short-term hacks.

---

## 29. Final Intent

Glass Vision should feel like a premium spatial hidden-object experience built specifically for Apple Vision Pro. The player should feel like they are holding an antique magical artifact that reveals another world layered into their real room. The app must prove this portal fantasy clearly, deliver a satisfying find-and-collect loop, and establish a clean technical foundation for future puzzles and leaderboard features.
