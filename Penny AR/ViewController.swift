//
//  ViewController.swift
//  Penny AR
//
//  Created by Thomas Tai on 8/2/19.
//  Copyright © 2019 Thomas Tai. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var lightNodes = [SCNNode]()
    var feedbackGenerator : UIImpactFeedbackGenerator? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/newscene.scn")!
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        
        //Create new feedback generator
        feedbackGenerator = UIImpactFeedbackGenerator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //check for horizontal plane
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
        
        //add scene lighting
        let lightNode = getLightNode()
        self.sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        feedbackGenerator?.prepare()
        guard let touch = touches.first else{return}
        let result = sceneView.hitTest(touch.location(in: sceneView), types: ARHitTestResult.ResultType.featurePoint)
        guard let hitResult = result.last else{return}
        let hitTransform = SCNMatrix4(hitResult.worldTransform)
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        createSkateboard(position: hitVector)
    }
    
    func createSkateboard(position: SCNVector3){
        let SBScene = SCNScene(named: "art.scnassets/pennyboard.scn")!
        let SBNode = SBScene.rootNode.childNode(withName: "SketchUp", recursively: false)!
        SBNode.position = position
        SBNode.scale = SCNVector3(0.00001, 0.00001, 0.00001)
        sceneView.scene.rootNode.addChildNode(SBNode)
        feedbackGenerator?.impactOccurred()
        let scaleAction = SCNAction.scale(by: 100, duration: 0.5)
        //let rotateAction = SCNAction.rotateBy(x: 0, y: .pi/2, z: 0, duration: 0.5)
        let action = SCNAction.group([scaleAction])
        SBNode.runAction(action)
    }
    
    func getLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 2000
        light.temperature = 5000
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0,10,0)
        
        lightNodes.append(lightNode)
        
        return lightNode
    }
    func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate
                else { return }
            
            let ambientIntensity = lightEstimate.ambientIntensity
            let ambientColorTemperature = lightEstimate.ambientColorTemperature
            
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.intensity = ambientIntensity
                light.temperature = ambientColorTemperature
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateLightNodesLightEstimation()
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
