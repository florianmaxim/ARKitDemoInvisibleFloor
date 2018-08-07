//
//  ViewController.swift
//  ARKitDemoEnvironmentTexturing
//
//  Created by Florian on 03/08/2018.
//  Copyright © 2018 Florian. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var planeGeometry:SCNPlane!
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]() //Real world positions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.scene = SCNScene()
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = SCNLight.LightType.ambient
        ambientNode.light?.color = UIColor.black.withAlphaComponent(0.6)
        sceneView.scene.rootNode.addChildNode(ambientNode)
        
        // Create a directional light node with shadow
        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = SCNLight.LightType.directional
        
        directionalNode.light?.color = UIColor.black.withAlphaComponent(0.6)
        
        directionalNode.light?.shadowMode = .modulated
        directionalNode.light?.castsShadow = true
        //directionalNode.light?.shadowRadius = 5.0
        
        directionalNode.position = SCNVector3(x: 0,y: 4,z: 0)
        sceneView.scene.rootNode.addChildNode(directionalNode)
        
        sceneView.autoenablesDefaultLighting = false;
        
        addTapGestureToSceneView()
    }
    
    @objc func addToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        
        // Using automatically detected planes
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        // Using automatically detected feature points
        //let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        let containerNode = SCNNode()
        
        for n in 0...10 {
            
            // Create the sphere node and place in on the scene
            //let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
            
            let geometry = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0.005)
            
            let sphereNode = SCNNode(geometry: geometry)
            
            // Create the reflective material and apply it to the sphere
            let reflectiveMaterial = SCNMaterial()
            
            reflectiveMaterial.lightingModel = .physicallyBased
            
            reflectiveMaterial.metalness.contents = 1.0
            reflectiveMaterial.roughness.contents = 0
            
            reflectiveMaterial.shininess = 100
            reflectiveMaterial.transparency = 0.85
            
            sphereNode.geometry?.firstMaterial = reflectiveMaterial
            
            
            let radius = 0.125
            let angle = n * 20
            
            let rX = (radius * cos(Double(angle)))
            let rY = (radius * sin(Double(angle)))
            
            sphereNode.position = SCNVector3(rX,rY,0)
            
            //Animation
            var move = SCNAction.rotateBy(x: CGFloat(Float.random(in: 0.5 ..< 1)), y: CGFloat(Float.random(in: 0.5 ..< 1)), z: CGFloat(Float.random(in: 0.5 ..< 1)), duration: 1)
            move = SCNAction.repeatForever(move)
            sphereNode.runAction(move)
            
            containerNode.addChildNode(sphereNode)
            
        }
        
        containerNode.position = SCNVector3(x,y,z)
        
        //let ym = CGFloat( Float.random(in: 0.0 ..< 0.1) )
        
        var move = SCNAction.rotateBy(x: 0, y: 0, z: 5, duration: 8)
        move = SCNAction.repeatForever(move)
        
        containerNode.runAction(move)
        
        sceneView.scene.rootNode.addChildNode(containerNode)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = false
        //configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.white
        plane.materials.first?.lightingModel = .constant
        plane.materials.first?.writesToDepthBuffer = true
        plane.materials.first?.colorBufferWriteMask = []
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        planeNode.castsShadow = false
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
