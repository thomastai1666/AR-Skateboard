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

//References and Sources
//https://developer.apple.com/documentation/arkit/tracking_and_visualizing_planes?language=objc
//https://3dwarehouse.sketchup.com/model/8cce68d3f0e42e43dda82f1bd87e9e6a/Penny-Board?hl=en

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var lightNodes = [SCNNode]()
    var feedbackGenerator : UIImpactFeedbackGenerator? = nil
    var debugMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/newscene.scn")!
        
        // Show statistics such as fps and timing information
        if(debugMode){
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        }
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        //Create new feedback generator
        feedbackGenerator = UIImpactFeedbackGenerator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //Change configuration options
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic

        // Run the view's session
        sceneView.session.run(configuration)
        
        //add scene lighting
        let lightNode = createLightNode()
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
        //Create new skateboard node from scene
        let SBScene = SCNScene(named: "art.scnassets/pennyboard.scn")!
        let SBNode = SBScene.rootNode.childNode(withName: "Skateboard", recursively: false)!
        
        //Position and scale down
        SBNode.position = position
        SBNode.scale = SCNVector3(0.005, 0.005, 0.005)
        feedbackGenerator?.impactOccurred()
        
        //Add to scene and scale up
        sceneView.scene.rootNode.addChildNode(SBNode)
        let scaleAction = SCNAction.scale(by: 100, duration: 0.5)
        let action = SCNAction.group([scaleAction])
        SBNode.runAction(action)
    }
    
    func createLightNode() -> SCNNode {
        //Create light source
        let light = SCNLight()
        light.type = .omni
        light.intensity = 2000
        light.temperature = 5000
        light.castsShadow = true
        
        //Add to scene
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(5,10,0)
        
        //Add to array for updates
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //ARKit add anchors for detected planes
        guard let planeAnchor = anchor as? ARPlaneAnchor else{ return}
        
        //Create new SCNPlane
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        //Show plane if in debug mode
        if(debugMode){
            plane.materials.first?.diffuse.contents = UIColor.init(white: 0, alpha: 0.5)
        }
        else{
            plane.materials.first?.diffuse.contents = UIColor.init(white: 0, alpha: 0)
        }
        
        //Add plane to scene
        let planenode = SCNNode(geometry: plane)
        planenode.simdPosition = planeAnchor.center
        planenode.eulerAngles.x = -.pi / 2
        node.addChildNode(planenode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
        
        planeNode.simdPosition = planeAnchor.center
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
