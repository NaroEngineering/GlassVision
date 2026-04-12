//
//  GlassVisionRuntime.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import Combine
import Foundation
import RealityKit
import SwiftUI
import simd

@MainActor
final class GlassVisionRuntime: ObservableObject {
    enum AttachmentID {
        static let checklist = "checklist_attachment"
        static let debug = "debug_attachment"
        static let completion = "completion_attachment"
    }

    enum LookingGlassState: String {
        case idleOnPedestal
        case hoverAvailable
        case grabbed
        case portalActive
        case releasedReturning
        case disabledTransition
    }

    enum RuntimeMode {
        case unconfigured
        case playing
        case completed
        case suspended
        case failed
    }

    struct DebugOptions {
        var showPortalCircle = false
        var showProjectedBounds = false
        var showGazeTarget = true
        var showEligibleTarget = false
        var showPedestalSlotIDs = false
    }

    struct ChecklistItem: Identifiable {
        let id: String
        let displayName: String
        let symbolName: String
        let isFound: Bool
    }

    private struct TargetRuntime {
        let definition: TargetItemDefinition
        let root: Entity
        let visual: Entity
        let highlight: Entity
        let debugBounds: Entity
        let baseScale: SIMD3<Float>
    }

    private struct TargetEvaluation {
        let targetID: String
        let portalSideName: String
        let overlapScore: Float
        let centerInsidePortal: Bool
        let passedOcclusion: Bool
        let minimumPortalOverlap: Float
        let depth: Float
        let radialDistance: Float
        let selectionPriority: Int

        var requiredOverlap: Float {
            max(minimumPortalOverlap - 0.15, 0.3)
        }

        var isPortalEligible: Bool {
            centerInsidePortal && overlapScore >= requiredOverlap
        }
    }

    private var sceneSubscriptions: [EventSubscription] = []
    private var subscribedSceneID: ObjectIdentifier?
    private var sessionAnchor = AnchorEntity(world: .zero)
    private var root = Entity()
    private var presentationRoot = Entity()
    private var pedestalRoot = Entity()
    private var portalWorld = Entity()
    private var hiddenWorldRoot = Entity()
    private var checklistAnchor = Entity()
    private var debugAnchor = Entity()
    private var completionAnchor = Entity()

    private var glassRoot = Entity()
    private var glassHandleHitTarget = Entity()
    private var portalDisk = ModelEntity()
    private var portalDiskBack = ModelEntity()
    private var portalDebugRing = ModelEntity()
    private var attachmentConfigured = false
    private var didAddRoot = false
    private var currentSessionID: UUID?
    private var currentContext: PuzzleLaunchContext?
    private weak var appModel: AppModel?
    private var deferredRebuildContext: PuzzleLaunchContext?
    private weak var deferredRebuildAppModel: AppModel?
    private var deferredRebuildScheduled = false
    private var targetEntities: [String: TargetRuntime] = [:]
    private var collectionSlotEntities: [String: Entity] = [:]
    private var scene: RealityKit.Scene?
    private var completionWasRecorded = false
    private var isSceneActive = true
    private var interactionLocked = false
    private var isGlassHeld = false
    private var portalRadius: Float = 0.13
    private let portalActivationDistanceThreshold: Float = 0.055
    private let glassAutoDockDistanceThreshold: Float = 0.06
    private let pinchDebounceInterval: TimeInterval = 0.25
    private let collectedDisplayScaleFactor: Float = 0.1
    private var homeGlassTransform = Transform.identity
    private let audioFeedback = AudioFeedbackController()
    private var lastPinchEventDate: Date = .distantPast
    private var pendingArmedTargetID: String?
    private var pendingArmedTargetStartDate: Date = .distantPast
    private var armedTargetID: String?
    private var armedTargetDate: Date = .distantPast
    private var lastSelectionLogDate: Date = .distantPast
    private var lastSelectionLogToken = ""
    private var lastPortalSideLog = ""
    private let armedTargetGracePeriod: TimeInterval = 0.8
    private let portalSideStickDuration: TimeInterval = 0.25
    private var stickyPortalSideName: String?
    private var stickyPortalSideDate: Date = .distantPast

    @Published var runtimeMode: RuntimeMode = .unconfigured
    @Published var glassState: LookingGlassState = .idleOnPedestal
    @Published var puzzle: PuzzleDefinition?
    @Published var foundItemIDs: Set<String> = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentGazeTargetID: String?
    @Published var currentEligibleTargetID: String?
    @Published var currentEligibility: PortalEligibilitySnapshot?
    @Published var lastTargetedEntityName = "None"
    @Published var lastAssignedSlotID = "-"
    @Published var latestFeedbackMessage = "Pick up the glass to reveal the hidden world."
    @Published var trackingStateText = "Tracked"
    @Published var lastAudioCueName = "None"
    @Published var debugOptions = DebugOptions()

    var checklistItems: [ChecklistItem] {
        (puzzle?.targetItems ?? []).map { item in
            ChecklistItem(
                id: item.itemID,
                displayName: item.displayName,
                symbolName: symbolName(for: item.silhouetteAssetID),
                isFound: foundItemIDs.contains(item.itemID)
            )
        }
    }

    var foundCount: Int {
        foundItemIDs.count
    }

    var requiredCount: Int {
        puzzle?.targetItems.count ?? 0
    }

    var launchPathTitle: String {
        currentContext?.launchPath.title ?? "Puzzle Select"
    }

    var currentGazeTargetName: String {
        targetEntities[currentGazeTargetID ?? ""]?.definition.displayName ?? "None"
    }

    var currentEligibleTargetName: String {
        targetEntities[currentEligibleTargetID ?? ""]?.definition.displayName ?? "None"
    }

    var currentArmedTargetName: String {
        targetEntities[armedTargetID ?? ""]?.definition.displayName ?? "None"
    }

    var currentOverlapText: String {
        String(format: "%.2f", Double(currentEligibility?.overlapScore ?? 0.0))
    }

    var isPortalVisible: Bool {
        glassState == .portalActive && runtimeMode == .playing
    }

    var completionTitle: String {
        puzzle?.displayName ?? "Wizard Study"
    }

    func configureIfNeeded(
        content: inout RealityViewContent,
        attachments: RealityViewAttachments,
        appModel: AppModel
    ) async {
        if !didAddRoot {
            sessionAnchor = AnchorEntity(world: .zero)
            sessionAnchor.name = "glass_vision_session_anchor"
            root.name = "glass_vision_session_root"
            sessionAnchor.addChild(root)
            content.add(sessionAnchor)
            didAddRoot = true
        } else if sessionAnchor.scene == nil {
            content.add(sessionAnchor)
        }

        self.appModel = appModel
        isSceneActive = appModel.sceneIsActive
        scene = root.scene
        ensureSceneSubscriptions(content: &content)
        configureAttachments(attachments)

        if currentSessionID != appModel.activeLaunchContext?.id {
            rebuild(for: appModel.activeLaunchContext, using: appModel)
        } else {
            updateAttachmentVisibility()
        }
    }

    func update(
        content: inout RealityViewContent,
        attachments: RealityViewAttachments,
        appModel: AppModel
    ) {
        self.appModel = appModel
        scene = root.scene ?? scene
        isSceneActive = appModel.sceneIsActive
        ensureSceneSubscriptions(content: &content)
        configureAttachments(attachments)

        if currentSessionID != appModel.activeLaunchContext?.id {
            scheduleDeferredRebuild(for: appModel.activeLaunchContext, using: appModel)
        }

        updateAttachmentVisibility()
        updateDebugGeometryVisibility()
    }

    func handlePinchConfirmationFromGaze() {
        lastTargetedEntityName = "Air Pinch"
        guard runtimeMode == .playing, isPortalVisible, !interactionLocked else {
            logPinchState(reason: "rejected: portal-not-ready", targetedEntity: nil)
            latestFeedbackMessage = "The portal is not ready for collection."
            playAudioCue(.invalidSelection)
            return
        }

        guard let candidateID = bestPinchCandidateID() else {
            logPinchState(reason: "rejected: no-best-candidate", targetedEntity: nil)
            latestFeedbackMessage = "Center a valid target in the lens, then pinch."
            playAudioCue(.invalidSelection)
            return
        }

        logPinchState(reason: "collect-from-gaze", targetedEntity: nil, candidateID: candidateID)
        collectTarget(id: candidateID, animated: true)
    }

    func handlePinchConfirmation(on targetedEntity: Entity?) {
        guard shouldProcessPinchEvent() else {
            logPinchState(reason: "ignored: debounce", targetedEntity: targetedEntity)
            return
        }

        if let targetedEntity, let targetedID = targetID(from: targetedEntity) {
            lastTargetedEntityName = targetedEntity.name

            guard runtimeMode == .playing, isPortalVisible, !interactionLocked else {
                logPinchState(reason: "rejected: target-tap-portal-not-ready", targetedEntity: targetedEntity)
                latestFeedbackMessage = "The portal is not ready for collection."
                playAudioCue(.invalidSelection)
                return
            }

            if foundItemIDs.contains(targetedID) {
                logPinchState(reason: "rejected: target-already-found", targetedEntity: targetedEntity, candidateID: targetedID)
                latestFeedbackMessage = "That item is already collected."
                playAudioCue(.invalidSelection)
                return
            }

            guard let candidateID = bestPinchCandidateID() else {
                logPinchState(reason: "rejected: no-eligible-candidate", targetedEntity: targetedEntity)
                latestFeedbackMessage = "Center a visible target in the lens, then pinch."
                playAudioCue(.invalidSelection)
                return
            }

            let resolvedID = candidateID == targetedID ? targetedID : candidateID
            let reason = candidateID == targetedID ? "collect-from-target-tap" : "collect-from-target-fallback"
            logPinchState(reason: reason, targetedEntity: targetedEntity, candidateID: resolvedID)
            collectTarget(id: resolvedID, animated: true)
            return
        }

        if let targetedEntity, isPortalEntity(targetedEntity), let candidateID = bestPinchCandidateID() {
            lastTargetedEntityName = targetedEntity.name
            logPinchState(reason: "collect-from-portal-tap", targetedEntity: targetedEntity, candidateID: candidateID)
            collectTarget(id: candidateID, animated: true)
            return
        }

        logPinchState(reason: "fallthrough-to-gaze", targetedEntity: targetedEntity)
        handlePinchConfirmationFromGaze()
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        let newActiveState = scenePhase == .active
        isSceneActive = newActiveState

        if newActiveState {
            if runtimeMode == .suspended, trackingStateText != "Untracked" {
                resumePlayableInteraction(withMessage: "Tracking restored. Pick up the glass to continue.")
            }
        } else {
            suspendInteraction(reason: "Scene inactive")
        }
    }

    func handleImmersiveDismissal() {
        suspendInteraction(reason: "Immersive space dismissed")
        sceneSubscriptions.removeAll()
        subscribedSceneID = nil
        scene = nil
    }

    func reloadCurrentPuzzle() {
        guard let currentContext else {
            return
        }
        rebuild(for: currentContext, using: appModel)
    }

    func forceCollectCurrentTarget() {
        guard let currentEligibleTargetID else {
            return
        }
        collectTarget(id: currentEligibleTargetID, animated: true)
    }

    func forceCompletePuzzle() {
        guard runtimeMode == .playing else {
            return
        }

        for item in puzzle?.targetItems ?? [] where !foundItemIDs.contains(item.itemID) {
            collectTarget(id: item.itemID, animated: false)
        }
    }

    private func installSubscriptions(content: inout RealityViewContent) {
        sceneSubscriptions.append(
            content.subscribe(to: SceneEvents.Update.self, on: nil, componentType: nil) { [weak self] event in
                self?.scene = event.scene
                self?.tick(deltaTime: event.deltaTime)
            }
        )

        sceneSubscriptions.append(
            content.subscribe(to: SceneEvents.TrackingStateUpdate.self, on: nil, componentType: nil) { [weak self] event in
                self?.handleTrackingStateUpdate(event.current)
            }
        )

        sceneSubscriptions.append(
            content.subscribe(to: ManipulationEvents.WillBegin.self, on: nil, componentType: nil) { [weak self] event in
                self?.handleManipulationWillBegin(for: event.entity)
            }
        )

        sceneSubscriptions.append(
            content.subscribe(to: ManipulationEvents.WillRelease.self, on: nil, componentType: nil) { [weak self] event in
                self?.handleManipulationWillRelease(for: event.entity)
            }
        )

        sceneSubscriptions.append(
            content.subscribe(to: ManipulationEvents.WillEnd.self, on: nil, componentType: nil) { [weak self] event in
                self?.handleManipulationWillEnd(for: event.entity)
            }
        )
    }

    private func ensureSceneSubscriptions(content: inout RealityViewContent) {
        guard let currentScene = root.scene else {
            return
        }
        let currentSceneID = ObjectIdentifier(currentScene)
        guard subscribedSceneID != currentSceneID else {
            return
        }

        sceneSubscriptions.removeAll()
        installSubscriptions(content: &content)
        subscribedSceneID = currentSceneID
    }

    private func scheduleDeferredRebuild(for context: PuzzleLaunchContext?, using appModel: AppModel) {
        deferredRebuildContext = context
        deferredRebuildAppModel = appModel

        guard !deferredRebuildScheduled else {
            return
        }
        deferredRebuildScheduled = true

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            // Publish-heavy runtime resets must happen outside RealityView.update callbacks.
            await Task.yield()

            self.deferredRebuildScheduled = false
            let queuedContext = self.deferredRebuildContext
            self.deferredRebuildContext = nil
            let queuedAppModel = self.deferredRebuildAppModel
            self.deferredRebuildAppModel = nil
            self.rebuild(for: queuedContext, using: queuedAppModel)
        }
    }

    private func rebuild(for context: PuzzleLaunchContext?, using appModel: AppModel?) {
        clearHierarchy()
        currentSessionID = context?.id
        currentContext = context
        completionWasRecorded = false
        foundItemIDs.removeAll()
        elapsedTime = 0
        currentGazeTargetID = nil
        currentEligibleTargetID = nil
        currentEligibility = nil
        pendingArmedTargetID = nil
        pendingArmedTargetStartDate = .distantPast
        armedTargetID = nil
        armedTargetDate = .distantPast
        interactionLocked = false
        isGlassHeld = false
        lastAssignedSlotID = "-"
        lastTargetedEntityName = "None"
        trackingStateText = "Tracked"
        lastAudioCueName = "None"
        runtimeMode = .unconfigured
        glassState = .disabledTransition

        guard let context else {
            latestFeedbackMessage = "Choose a puzzle from the menu."
            return
        }

        guard let model = appModel ?? self.appModel,
              let loadedPuzzle = model.repository.loadPuzzle(id: context.puzzleID) else {
            latestFeedbackMessage = "The puzzle data could not be loaded."
            runtimeMode = .failed
            return
        }

        puzzle = loadedPuzzle

        presentationRoot = Entity()
        presentationRoot.name = "presentation_root"
        root.addChild(presentationRoot)

        portalWorld = Entity()
        portalWorld.name = "portal_world"
        portalWorld.components.set(WorldComponent())
        root.addChild(portalWorld)

        hiddenWorldRoot = Entity()
        hiddenWorldRoot.name = "hidden_world_root"
        portalWorld.addChild(hiddenWorldRoot)

        buildPedestal()
        buildGlass()
        buildEnvironment()
        buildTargets()

        runtimeMode = isSceneActive ? .playing : .suspended
        glassState = runtimeMode == .playing ? .hoverAvailable : .disabledTransition
        glassHandleHitTarget.isEnabled = runtimeMode == .playing
        latestFeedbackMessage = "Pick up the glass and scan the room for hidden objects."
        updateAttachmentVisibility()
        updateDebugGeometryVisibility()
    }

    private func buildPedestal() {
        pedestalRoot = GeneratedAssetFactory.makePedestal()
        presentationRoot.addChild(pedestalRoot)

        checklistAnchor = Entity()
        checklistAnchor.name = "checklist_anchor"
        // Keep checklist comfortably off to the side so it doesn't block the pedestal.
        checklistAnchor.position = [-0.62, 1.02, 0.18]
        pedestalRoot.addChild(checklistAnchor)

        debugAnchor = Entity()
        debugAnchor.name = "debug_anchor"
        debugAnchor.position = [0.64, 1.0, 0.02]
        pedestalRoot.addChild(debugAnchor)

        completionAnchor = Entity()
        completionAnchor.name = "completion_anchor"
        completionAnchor.position = [0, 1.28, -0.22]
        pedestalRoot.addChild(completionAnchor)

        collectionSlotEntities.removeAll()
        for slot in puzzle?.collectionSlotLayout ?? [] {
            let marker = GeneratedAssetFactory.makeCollectionSlotMarker(slotID: slot.slotID)
            marker.position = slot.position
            marker.orientation = simd_quatf(
                ix: slot.rotation.x,
                iy: slot.rotation.y,
                iz: slot.rotation.z,
                r: slot.rotation.w
            )
            marker.scale = slot.scale
            pedestalRoot.addChild(marker)
            collectionSlotEntities[slot.slotID] = marker
        }
    }

    private func buildGlass() {
        let assembly = GeneratedAssetFactory.makeLookingGlass(portalRadius: portalRadius)
        glassRoot = assembly.root
        glassHandleHitTarget = assembly.handleHitTarget
        portalDisk = assembly.portalDiskFront
        portalDiskBack = assembly.portalDiskBack
        portalDebugRing = assembly.debugRing
        homeGlassTransform = assembly.homeTransform
        portalDisk.components.set(PortalComponent(target: portalWorld))
        portalDiskBack.components.set(PortalComponent(target: portalWorld))
        setPortalEnabled(false)
        glassRoot.transform = homeGlassTransform
        pedestalRoot.addChild(glassRoot)
    }

    private func buildEnvironment() {
        hiddenWorldRoot.addChild(GeneratedAssetFactory.makeWizardStudyEnvironment())
    }

    private func buildTargets() {
        targetEntities.removeAll()

        for item in puzzle?.targetItems ?? [] {
            let root = Entity()
            root.name = "target:\(item.itemID)"
            root.transform = item.worldTransform.transform
            root.components.set(
                CollisionComponent(
                    shapes: [.generateSphere(radius: max(item.boundsProfile.radius * 1.35, 0.08))],
                    filter: CollisionFilter(group: GeneratedAssetFactory.hiddenTargetGroup, mask: .all)
                )
            )
            root.components.set(InputTargetComponent())
            applyHoverEffectRecursively(to: root)

            let visual = GeneratedAssetFactory.makeTargetVisual(for: item.assetID)
            visual.name = "visual:\(item.itemID)"
            applyHoverEffectRecursively(to: visual)
            normalizeVisualScale(visual, boundsRadius: item.boundsProfile.radius)
            root.addChild(visual)

            let highlight = GeneratedAssetFactory.makeSelectionBracket(radius: item.boundsProfile.radius)
            highlight.name = "highlight:\(item.itemID)"
            highlight.isEnabled = false
            root.addChild(highlight)

            let debugBounds = GeneratedAssetFactory.makeDebugBounds(radius: item.boundsProfile.radius)
            debugBounds.name = "debug_bounds:\(item.itemID)"
            debugBounds.isEnabled = false
            root.addChild(debugBounds)

            hiddenWorldRoot.addChild(root)
            targetEntities[item.itemID] = TargetRuntime(
                definition: item,
                root: root,
                visual: visual,
                highlight: highlight,
                debugBounds: debugBounds,
                baseScale: root.scale
            )
        }
    }

    private func configureAttachments(_ attachments: RealityViewAttachments) {
        if let checklistEntity = attachments.entity(for: AttachmentID.checklist), checklistEntity.parent == nil {
            checklistAnchor.addChild(checklistEntity)
            checklistEntity.position = .zero
        }

        if let debugEntity = attachments.entity(for: AttachmentID.debug), debugEntity.parent == nil {
            debugAnchor.addChild(debugEntity)
            debugEntity.position = .zero
        }

        if let completionEntity = attachments.entity(for: AttachmentID.completion), completionEntity.parent == nil {
            completionAnchor.addChild(completionEntity)
            completionEntity.position = .zero
        }

        attachmentConfigured = true
        updateAttachmentVisibility()
    }

    private func updateAttachmentVisibility() {
        guard attachmentConfigured else {
            return
        }

        checklistAnchor.isEnabled = runtimeMode == .playing || runtimeMode == .suspended
        debugAnchor.isEnabled = runtimeMode == .playing || runtimeMode == .suspended
        completionAnchor.isEnabled = runtimeMode == .completed
    }

    private func updateDebugGeometryVisibility() {
        portalDebugRing.isEnabled = debugOptions.showPortalCircle && isPortalVisible

        for (itemID, target) in targetEntities {
            target.debugBounds.isEnabled = debugOptions.showProjectedBounds && !foundItemIDs.contains(itemID)
        }
    }

    private func setPortalEnabled(_ enabled: Bool) {
        portalDisk.isEnabled = enabled
        portalDiskBack.isEnabled = enabled
    }

    private func tick(deltaTime: TimeInterval) {
        guard didAddRoot else {
            return
        }

        if runtimeMode == .playing, isSceneActive {
            elapsedTime += deltaTime
        }

        updatePortalState()
        updateGlassInteractivityState()
        updateCurrentTargets()
        updateTargetHighlighting()
        updateDebugGeometryVisibility()
    }

    private func updatePortalState() {
        guard runtimeMode == .playing, isSceneActive, glassRoot.parent != nil else {
            setPortalEnabled(false)
            return
        }
        if glassState != .portalActive {
            glassState = .portalActive
        }
        setPortalEnabled(true)
    }

    private func updateCurrentTargets() {
        guard runtimeMode == .playing, isPortalVisible, let portalReferences = currentPortalReferences() else {
            currentGazeTargetID = nil
            currentEligibleTargetID = nil
            currentEligibility = PortalEligibilitySnapshot(
                targetID: nil,
                targetName: nil,
                overlapScore: 0,
                centerInsidePortal: false,
                passedOcclusion: false,
                isAlreadyFound: false,
                portalActive: portalDisk.isEnabled
            )
            return
        }

        let candidates = targetEntities.values.flatMap { target in
            portalReferences.compactMap { portalReference in
                evaluateTarget(id: target.definition.itemID, portalReference: portalReference)
            }
        }

        let gazeCandidate = candidates
            .filter(\.centerInsidePortal)
            .sorted {
                if $0.passedOcclusion != $1.passedOcclusion {
                    return $0.passedOcclusion && !$1.passedOcclusion
                }
                if $0.radialDistance == $1.radialDistance {
                    if $0.depth == $1.depth {
                        return $0.selectionPriority > $1.selectionPriority
                    }
                    return $0.depth < $1.depth
                }
                return $0.radialDistance < $1.radialDistance
            }
            .first

        currentGazeTargetID = gazeCandidate?.targetID

        let eligibleCandidate = candidates
            .filter(\.isPortalEligible)
            .sorted {
                if $0.passedOcclusion != $1.passedOcclusion {
                    return $0.passedOcclusion && !$1.passedOcclusion
                }
                if $0.overlapScore == $1.overlapScore {
                    if $0.radialDistance == $1.radialDistance {
                        if $0.depth == $1.depth {
                            return $0.selectionPriority > $1.selectionPriority
                        }
                        return $0.depth < $1.depth
                    }
                    return $0.radialDistance < $1.radialDistance
                }
                return $0.overlapScore > $1.overlapScore
            }
            .first

        let resolvedCandidate = resolveStableCandidate(
            candidates: candidates,
            eligibleCandidate: eligibleCandidate,
            gazeCandidate: gazeCandidate
        )
        updateArmedTarget(using: resolvedCandidate)

        currentEligibleTargetID = resolvedCandidate?.targetID
        currentEligibility = PortalEligibilitySnapshot(
            targetID: resolvedCandidate?.targetID,
            targetName: targetEntities[resolvedCandidate?.targetID ?? ""]?.definition.displayName,
            overlapScore: resolvedCandidate?.overlapScore ?? 0,
            centerInsidePortal: resolvedCandidate?.centerInsidePortal ?? false,
            passedOcclusion: resolvedCandidate?.passedOcclusion ?? false,
            isAlreadyFound: resolvedCandidate.map { foundItemIDs.contains($0.targetID) } ?? false,
            portalActive: portalDisk.isEnabled
        )
        logPortalSide(using: resolvedCandidate)

        logSelectionSnapshot(
            gazeCandidate: gazeCandidate,
            eligibleCandidate: eligibleCandidate,
            resolvedCandidate: resolvedCandidate,
            candidateCount: candidates.count
        )
    }

    private func currentPortalReferences() -> [(entity: ModelEntity, sampleOrigin: SIMD3<Float>)]? {
        guard portalDisk.parent != nil else {
            return nil
        }

        var references: [(entity: ModelEntity, sampleOrigin: SIMD3<Float>)] = [
            (portalDisk, portalDisk.position(relativeTo: nil))
        ]
        if portalDiskBack.parent != nil {
            references.append((portalDiskBack, portalDiskBack.position(relativeTo: nil)))
        }
        return references
    }

    private func logPortalSide(using candidate: TargetEvaluation?) {
        let selectedSide = candidate?.portalSideName ?? "none"
        guard selectedSide != lastPortalSideLog else {
            return
        }
        lastPortalSideLog = selectedSide
        print("[GlassVision][PortalSide] selected=\(selectedSide)")
    }

    private func evaluateTarget(
        id targetID: String,
        portalReference: (entity: ModelEntity, sampleOrigin: SIMD3<Float>)
    ) -> TargetEvaluation? {
        guard let target = targetEntities[targetID], !foundItemIDs.contains(targetID) else {
            return nil
        }

        let targetPosition = target.root.position(relativeTo: nil)
        let localPosition = portalReference.entity.convert(position: targetPosition, from: nil)
        let planeProjections: [(radial: Float, depth: Float)] = [
            (simd_length(SIMD2(localPosition.x, localPosition.y)), abs(localPosition.z)),
            (simd_length(SIMD2(localPosition.x, localPosition.z)), abs(localPosition.y)),
            (simd_length(SIMD2(localPosition.y, localPosition.z)), abs(localPosition.x))
        ]
        let bestProjection = planeProjections.min { $0.radial < $1.radial } ?? (0, 0.001)
        let radialDistance = bestProjection.radial
        let centerInside = radialDistance <= (portalRadius * 1.2)
        let depth = max(bestProjection.depth, 0.001)

        let projectedRadius = max(target.definition.boundsProfile.radius * 0.36 / max(depth, 0.25), 0.016)
        let overlap = normalizedOverlap(
            portalRadius: portalRadius,
            distanceFromCenter: radialDistance,
            projectedRadius: projectedRadius
        )

        let occlusionClear = isVisibleThroughPortal(
            targetItemID: target.definition.itemID,
            from: portalReference.sampleOrigin,
            to: targetPosition
        )

        return TargetEvaluation(
            targetID: target.definition.itemID,
            portalSideName: portalReference.entity.name,
            overlapScore: overlap,
            centerInsidePortal: centerInside,
            passedOcclusion: occlusionClear,
            minimumPortalOverlap: target.definition.boundsProfile.minimumPortalOverlap,
            depth: depth,
            radialDistance: radialDistance,
            selectionPriority: target.definition.selectionPriority
        )
    }

    private func isVisibleThroughPortal(targetItemID: String, from start: SIMD3<Float>, to end: SIMD3<Float>) -> Bool {
        guard let scene else {
            return true
        }

        let hits = scene.raycast(
            from: start,
            to: end,
            query: .nearest,
            mask: [GeneratedAssetFactory.hiddenTargetGroup, GeneratedAssetFactory.hiddenOccluderGroup],
            relativeTo: nil
        )

        guard let firstHit = hits.first else {
            return true
        }

        return targetID(from: firstHit.entity) == targetItemID
    }

    private func normalizedOverlap(
        portalRadius: Float,
        distanceFromCenter: Float,
        projectedRadius: Float
    ) -> Float {
        let overlapDistance = portalRadius + projectedRadius - distanceFromCenter
        let normalized = overlapDistance / max(projectedRadius * 2, 0.0001)
        return max(0, min(1, normalized))
    }

    private func collectTarget(id: String, animated: Bool) {
        guard let target = targetEntities[id], !foundItemIDs.contains(id) else {
            return
        }

        foundItemIDs.insert(id)
        pendingArmedTargetID = nil
        pendingArmedTargetStartDate = .distantPast
        armedTargetID = nil
        armedTargetDate = .distantPast
        lastAssignedSlotID = target.definition.pedestalSlotID
        latestFeedbackMessage = "Collected \(target.definition.displayName)."
        playAudioCue(.validSelection, entity: target.root)

        target.root.isEnabled = false
        spawnCollectedDisplay(from: target, animated: animated)
        updateCurrentTargets()

        if foundItemIDs.count == requiredCount {
            completePuzzle()
        }
    }

    private func spawnCollectedDisplay(from target: TargetRuntime, animated: Bool) {
        guard let slotEntity = collectionSlotEntities[target.definition.pedestalSlotID] else {
            return
        }

        playAudioCue(.extraction, entity: slotEntity)

        let display = target.visual.clone(recursive: true)
        display.name = "collected:\(target.definition.itemID)"
        presentationRoot.addChild(display)

        let startPosition = target.root.position(relativeTo: nil)
        display.position = presentationRoot.convert(position: startPosition, from: nil)
        display.orientation = target.root.orientation(relativeTo: presentationRoot)

        let slotPosition = slotEntity.position(relativeTo: presentationRoot)
        let slotTransform = Transform(
            scale: slotEntity.scale * collectedDisplayScaleFactor,
            rotation: slotEntity.orientation(relativeTo: presentationRoot),
            translation: slotPosition + SIMD3<Float>(0, debugOptions.showPedestalSlotIDs ? 0.05 : 0.03, 0)
        )

        if animated {
            display.move(to: slotTransform, relativeTo: presentationRoot, duration: 0.55, timingFunction: .easeInOut)
        } else {
            display.transform = slotTransform
        }
    }

    private func completePuzzle() {
        guard runtimeMode == .playing, let currentContext, let puzzle else {
            return
        }

        runtimeMode = .completed
        glassState = .idleOnPedestal
        setPortalEnabled(false)
        interactionLocked = true
        latestFeedbackMessage = "Puzzle complete."
        playAudioCue(.completion, entity: completionAnchor)
        glassRoot.move(to: homeGlassTransform, relativeTo: pedestalRoot, duration: 0.35, timingFunction: .easeInOut)

        if !completionWasRecorded {
            let summary = CompletionSummary(
                puzzleID: puzzle.id,
                puzzleName: puzzle.displayName,
                launchPath: currentContext.launchPath,
                elapsedTime: elapsedTime,
                foundCount: foundItemIDs.count,
                dailyKey: currentContext.dailyKey
            )
            appModel?.recordCompletion(summary)
            completionWasRecorded = true
        }

        updateAttachmentVisibility()
    }

    private func handleTrackingStateUpdate(_ state: SceneEvents.TrackingStateUpdate.State) {
        switch state {
        case .tracked:
            trackingStateText = "Tracked"
            if runtimeMode == .suspended, isSceneActive {
                resumePlayableInteraction(withMessage: "Tracking restored. Pick up the glass to continue.")
            }
        case .orientationTracked:
            trackingStateText = "Limited"
            // Limited orientation tracking is still usable; do not force a suspend.
            if runtimeMode == .playing {
                latestFeedbackMessage = "Tracking limited. Continue scanning with slower movement."
            }
        case .untracked:
            trackingStateText = "Untracked"
            suspendInteraction(reason: "Tracking lost")
        @unknown default:
            trackingStateText = "Unknown"
            suspendInteraction(reason: "Tracking unavailable")
        }
    }

    private func handleManipulationWillBegin(for entity: Entity) {
        guard isGlassManipulationEntity(entity), runtimeMode == .playing, isSceneActive, !interactionLocked else {
            return
        }

        isGlassHeld = true
        glassState = .grabbed
        playAudioCue(.glassPickup, entity: glassRoot)
        glassState = .portalActive
        playAudioCue(.portalActivation, entity: portalDisk)
        latestFeedbackMessage = "Portal active. Center a target in the lens, then pinch."
    }

    private func handleManipulationWillRelease(for entity: Entity) {
        guard isGlassManipulationEntity(entity) else {
            return
        }
        isGlassHeld = false

        let currentPosition = glassRoot.position(relativeTo: pedestalRoot)
        let distanceFromHome = simd_length(currentPosition - homeGlassTransform.translation)

        if runtimeMode == .playing,
           isSceneActive,
           !interactionLocked,
           distanceFromHome > glassAutoDockDistanceThreshold {
            glassState = .portalActive
            setPortalEnabled(true)
            latestFeedbackMessage = "Portal active. Gaze a target in the lens, then pinch with your free hand."
            return
        }

        returnGlassToPedestal(animated: true)
    }

    private func handleManipulationWillEnd(for entity: Entity) {
        guard isGlassManipulationEntity(entity) else {
            return
        }
    }

    private func returnGlassToPedestal(animated: Bool) {
        interactionLocked = true
        isGlassHeld = false
        pendingArmedTargetID = nil
        pendingArmedTargetStartDate = .distantPast
        armedTargetID = nil
        armedTargetDate = .distantPast
        glassState = .releasedReturning
        setPortalEnabled(false)
        latestFeedbackMessage = "Portal closed."
        currentGazeTargetID = nil
        currentEligibleTargetID = nil

        if animated {
            glassRoot.move(to: homeGlassTransform, relativeTo: pedestalRoot, duration: 0.35, timingFunction: .easeInOut)
        } else {
            glassRoot.transform = homeGlassTransform
        }

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(animated ? 380 : 20))
            guard let self else { return }
            self.glassState = self.runtimeMode == .playing ? .hoverAvailable : .idleOnPedestal
            self.interactionLocked = false
        }
    }

    private func suspendInteraction(reason: String) {
        if runtimeMode == .completed {
            return
        }
        isGlassHeld = false
        runtimeMode = .suspended
        latestFeedbackMessage = reason
        returnGlassToPedestal(animated: false)
    }

    private func resumePlayableInteraction(withMessage message: String) {
        runtimeMode = .playing
        interactionLocked = false
        isGlassHeld = false
        pendingArmedTargetID = nil
        pendingArmedTargetStartDate = .distantPast
        armedTargetID = nil
        armedTargetDate = .distantPast
        glassState = .hoverAvailable
        setPortalEnabled(false)
        currentGazeTargetID = nil
        currentEligibleTargetID = nil
        currentEligibility = nil
        latestFeedbackMessage = message
    }

    private func updateGlassInteractivityState() {
        let canInteractWithGlass = runtimeMode == .playing && isSceneActive && !interactionLocked
        glassHandleHitTarget.isEnabled = canInteractWithGlass
    }

    private func shouldProcessPinchEvent() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastPinchEventDate) > pinchDebounceInterval else {
            return false
        }
        lastPinchEventDate = now
        return true
    }

    private func isGlassManipulationEntity(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let candidate = current {
            if candidate === glassRoot || candidate === glassHandleHitTarget {
                return true
            }
            current = candidate.parent
        }
        return false
    }

    private func bestPinchCandidateID() -> String? {
        guard let candidateID = currentEligibleTargetID, !foundItemIDs.contains(candidateID) else {
            guard let armedTargetID, !foundItemIDs.contains(armedTargetID) else {
                return nil
            }
            let age = Date().timeIntervalSince(armedTargetDate)
            return age <= armedTargetGracePeriod ? armedTargetID : nil
        }
        return candidateID
    }

    private func updateArmedTarget(using gazeCandidate: TargetEvaluation?) {
        if let gazeCandidate {
            armedTargetID = gazeCandidate.targetID
            armedTargetDate = Date()
            pendingArmedTargetID = gazeCandidate.targetID
            pendingArmedTargetStartDate = armedTargetDate
        } else if Date().timeIntervalSince(armedTargetDate) > armedTargetGracePeriod {
            armedTargetID = nil
            pendingArmedTargetID = nil
            pendingArmedTargetStartDate = .distantPast
        }
    }

    private func resolveStableCandidate(
        candidates: [TargetEvaluation],
        eligibleCandidate: TargetEvaluation?,
        gazeCandidate: TargetEvaluation?
    ) -> TargetEvaluation? {
        let now = Date()
        if let stickyPortalSideName,
           now.timeIntervalSince(stickyPortalSideDate) <= portalSideStickDuration {
            let stickyEligible = candidates
                .filter { $0.portalSideName == stickyPortalSideName && $0.isPortalEligible }
                .sorted(by: compareEligibleCandidates)
                .first
            if let stickyEligible {
                stickyPortalSideDate = now
                return stickyEligible
            }

            let stickyGaze = candidates
                .filter { $0.portalSideName == stickyPortalSideName && $0.centerInsidePortal }
                .sorted(by: compareGazeCandidates)
                .first
            if let stickyGaze {
                stickyPortalSideDate = now
                return stickyGaze
            }
        }

        let resolved = eligibleCandidate ?? gazeCandidate
        stickyPortalSideName = resolved?.portalSideName
        stickyPortalSideDate = now
        return resolved
    }

    private func compareGazeCandidates(_ lhs: TargetEvaluation, _ rhs: TargetEvaluation) -> Bool {
        if lhs.passedOcclusion != rhs.passedOcclusion {
            return lhs.passedOcclusion && !rhs.passedOcclusion
        }
        if lhs.radialDistance == rhs.radialDistance {
            if lhs.depth == rhs.depth {
                return lhs.selectionPriority > rhs.selectionPriority
            }
            return lhs.depth < rhs.depth
        }
        return lhs.radialDistance < rhs.radialDistance
    }

    private func compareEligibleCandidates(_ lhs: TargetEvaluation, _ rhs: TargetEvaluation) -> Bool {
        if lhs.passedOcclusion != rhs.passedOcclusion {
            return lhs.passedOcclusion && !rhs.passedOcclusion
        }
        if lhs.overlapScore == rhs.overlapScore {
            if lhs.radialDistance == rhs.radialDistance {
                if lhs.depth == rhs.depth {
                    return lhs.selectionPriority > rhs.selectionPriority
                }
                return lhs.depth < rhs.depth
            }
            return lhs.radialDistance < rhs.radialDistance
        }
        return lhs.overlapScore > rhs.overlapScore
    }

    private func updateTargetHighlighting() {
        for (itemID, target) in targetEntities {
            if foundItemIDs.contains(itemID) {
                target.root.scale = target.baseScale
                setHighlight(target.highlight, color: .clear, enabled: false)
                continue
            }

            if itemID == currentEligibleTargetID {
                target.root.scale = target.baseScale * SIMD3<Float>(repeating: 1.12)
                setHighlight(target.highlight, color: .init(red: 0.12, green: 0.92, blue: 0.72, alpha: 0.95), enabled: true)
            } else if itemID == currentGazeTargetID {
                target.root.scale = target.baseScale * SIMD3<Float>(repeating: 1.06)
                setHighlight(target.highlight, color: .init(red: 0.98, green: 0.82, blue: 0.28, alpha: 0.9), enabled: true)
            } else {
                target.root.scale = target.baseScale
                setHighlight(target.highlight, color: .clear, enabled: false)
            }
        }
    }

    private func normalizeVisualScale(_ visual: Entity, boundsRadius: Float) {
        let bounds = visual.visualBounds(relativeTo: visual)
        let extents = bounds.extents
        let longestSide = max(extents.x, max(extents.y, extents.z))
        guard longestSide > 0.0001 else {
            return
        }

        let targetDiameter = max(boundsRadius * 2.6, 0.16)
        let scaleFactor = min(max(targetDiameter / longestSide, 0.7), 4.8)
        visual.scale *= SIMD3<Float>(repeating: scaleFactor)
    }

    private func applyHoverEffectRecursively(to entity: Entity) {
        entity.components.set(HoverEffectComponent())
        for child in entity.children {
            applyHoverEffectRecursively(to: child)
        }
    }

    private func logPinchState(reason: String, targetedEntity: Entity?, candidateID: String? = nil) {
        let targetedName = targetedEntity?.name ?? "nil"
        let overlapText = String(format: "%.3f", Double(currentEligibility?.overlapScore ?? 0.0))
        let occlusionText = currentEligibility?.passedOcclusion == true ? "clear" : "blocked"
        let age = Date().timeIntervalSince(armedTargetDate)
        let armedAgeText = armedTargetID == nil ? "n/a" : String(format: "%.3fs", age)
        let message = """
        [GlassVision][Pinch] reason=\(reason) targeted=\(targetedName) candidate=\(candidateID ?? "nil") gaze=\(currentGazeTargetID ?? "nil") eligible=\(currentEligibleTargetID ?? "nil") armed=\(armedTargetID ?? "nil") armedAge=\(armedAgeText) overlap=\(overlapText) occlusion=\(occlusionText) portalVisible=\(isPortalVisible) runtime=\(String(describing: runtimeMode)) state=\(glassState.rawValue) feedback=\"\(latestFeedbackMessage)\"
        """
        print(message)
    }

    private func logSelectionSnapshot(
        gazeCandidate: TargetEvaluation?,
        eligibleCandidate: TargetEvaluation?,
        resolvedCandidate: TargetEvaluation?,
        candidateCount: Int
    ) {
        let now = Date()
        let gazeID = gazeCandidate?.targetID ?? "nil"
        let eligibleID = eligibleCandidate?.targetID ?? "nil"
        let resolvedID = resolvedCandidate?.targetID ?? "nil"
        let token = "\(gazeID)|\(eligibleID)|\(resolvedID)|\(candidateCount)"
        let shouldLog = token != lastSelectionLogToken || now.timeIntervalSince(lastSelectionLogDate) > 0.6
        guard shouldLog else {
            return
        }

        lastSelectionLogToken = token
        lastSelectionLogDate = now

        let gazeSummary = formatCandidateLog(gazeCandidate)
        let eligibleSummary = formatCandidateLog(eligibleCandidate)
        let resolvedSummary = formatCandidateLog(resolvedCandidate)
        print("[GlassVision][Select] candidates=\(candidateCount) gaze=\(gazeSummary) eligible=\(eligibleSummary) resolved=\(resolvedSummary)")
    }

    private func formatCandidateLog(_ candidate: TargetEvaluation?) -> String {
        guard let candidate else {
            return "nil"
        }
        let overlap = String(format: "%.2f", Double(candidate.overlapScore))
        let radial = String(format: "%.3f", Double(candidate.radialDistance))
        let depth = String(format: "%.3f", Double(candidate.depth))
        let required = String(format: "%.2f", Double(candidate.requiredOverlap))
        let occlusion = candidate.passedOcclusion ? "clear" : "blocked"
        return "\(candidate.targetID){side=\(candidate.portalSideName),overlap=\(overlap),required=\(required),center=\(candidate.centerInsidePortal),occlusion=\(occlusion),radial=\(radial),depth=\(depth)}"
    }

    private func clearHierarchy() {
        for child in Array(root.children) {
            child.removeFromParent()
        }
        targetEntities.removeAll()
        collectionSlotEntities.removeAll()
        puzzle = nil
        scene = root.scene ?? scene
    }

    private func targetID(from entity: Entity) -> String? {
        if entity.name.hasPrefix("target:") {
            return String(entity.name.dropFirst("target:".count))
        }

        var currentParent = entity.parent
        while let parent = currentParent {
            if parent.name.hasPrefix("target:") {
                return String(parent.name.dropFirst("target:".count))
            }
            currentParent = parent.parent
        }

        return nil
    }

    private func isPortalEntity(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let candidate = current {
            if candidate === portalDisk || candidate === portalDiskBack {
                return true
            }
            current = candidate.parent
        }
        return false
    }

    private func setHighlight(_ entity: Entity, color: UIColor, enabled: Bool) {
        if let modelEntity = entity as? ModelEntity, var model = modelEntity.components[ModelComponent.self] {
            model.materials = [GeneratedAssetFactory.unlitMaterial(color)]
            modelEntity.components.set(model)
        }
        for child in entity.children {
            if let modelChild = child as? ModelEntity, var model = modelChild.components[ModelComponent.self] {
                model.materials = [GeneratedAssetFactory.unlitMaterial(color)]
                modelChild.components.set(model)
            }
        }
        entity.isEnabled = enabled
    }

    private func symbolName(for silhouetteAssetID: String) -> String {
        switch silhouetteAssetID {
        case "feather_quill", "feather":
            return "feather"
        case "hourglass":
            return "hourglass"
        case "crystal_ball", "sparkles":
            return "sparkles"
        case "potion_bottle", "drop.fill":
            return "drop.fill"
        case "spell_book", "book.closed.fill":
            return "book.closed.fill"
        case "key", "key.fill":
            return "key.fill"
        case "candle", "flame.fill":
            return "flame.fill"
        case "wand", "wand.and.stars":
            return "wand.and.stars"
        case "moon_charm", "moon.stars.fill":
            return "moon.stars.fill"
        case "tiny_dragon_figurine", "sparkle":
            return "sparkle"
        default:
            return "circle.fill"
        }
    }

    private func playAudioCue(_ cue: AudioFeedbackController.Cue, entity: Entity? = nil) {
        audioFeedback.play(cue, on: entity)
        lastAudioCueName = cue.debugLabel
    }
}
