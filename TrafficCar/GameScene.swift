
import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  let playerCar = SKSpriteNode(imageNamed: "car1")
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  let playerCarMovePointsPerSec: CGFloat = 480.0
  var velocity = CGPoint.zero
  let playableRect: CGRect
  var lastTouchLocation: CGPoint?
  let playerCarRotateRadiansPerSec:CGFloat = 4.0 * π
  let playerCarAnimation: SKAction
  let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
    "hitCat.wav", waitForCompletion: false)
  let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
    "hitCatLady.wav", waitForCompletion: false)
  var invincible = false
  let carMovePointsPerSec:CGFloat = 480.0
  var lives = 3
  var gameOver = false
  let cameraNode = SKCameraNode()
  let cameraMovePointsPerSec: CGFloat = 200.0
  var points = 0

  let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
  let coinsLabel = SKLabelNode(fontNamed: "Chalkduster")
    
  override init(size: CGSize) {
    let maxAspectRatio:CGFloat = 16.0/9.0
    let playableHeight = size.width / maxAspectRatio
    let playableMargin = (size.height-playableHeight)/2.0
    playableRect = CGRect(x: 0, y: playableMargin,
                          width: size.width,
                          height: playableHeight)
    
    // 1
    var textures:[SKTexture] = []
    // 2
    for i in 1...4 {
      textures.append(SKTexture(imageNamed: "playerCar\(i)"))
    }
    // 3
    textures.append(textures[2])
    textures.append(textures[1])

    // 4
    playerCarAnimation = SKAction.animate(with: textures,
      timePerFrame: 0.1)
  
    super.init(size: size)
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func debugDrawPlayableArea() {
    let shape = SKShapeNode()
    let path = CGMutablePath()
    path.addRect(playableRect)
    shape.path = path
    shape.strokeColor = SKColor.red
    shape.lineWidth = 4.0
    shape.setScale(0.5)
    addChild(shape)
  }
  
  override func didMove(to view: SKView) {

    playBackgroundMusic(filename: "backgroundlevelone.mp3")
  
    for i in 0...1 {
      let background = backgroundNode()
      background.anchorPoint = CGPoint.zero
      background.position =
        CGPoint(x: CGFloat(i)*background.size.width, y: 0)
      background.name = "background"
      background.zPosition = -1
      addChild(background)
    }
    
    playerCar.position = CGPoint(x: 400, y: 400)
    playerCar.zPosition = 100
    playerCar.setScale(0.65)
    addChild(playerCar)
    
   
    
    run(SKAction.repeatForever(
      SKAction.sequence([SKAction.run() { [weak self] in
                      self?.spawnCar()
                    },
                    SKAction.wait(forDuration: 2.0)])))
    
    run(SKAction.repeatForever(
    SKAction.sequence([SKAction.run() { [weak self] in
                    self?.spawnPoliceCar()
                  },
                  SKAction.wait(forDuration: 6.0)])))
    
  run(SKAction.repeatForever(
  SKAction.sequence([SKAction.run() { [weak self] in
                      self?.spawnCoin()
                    },
                    SKAction.wait(forDuration: 5.0)])))
    addChild(cameraNode)
    camera = cameraNode
    cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
    
    livesLabel.text = "Lives: X"
    livesLabel.fontColor = SKColor.black
    livesLabel.fontSize = 100
    livesLabel.zPosition = 150
    livesLabel.horizontalAlignmentMode = .left
    livesLabel.verticalAlignmentMode = .bottom
    livesLabel.position = CGPoint(
        x: -playableRect.size.width/2 + CGFloat(20),
        y: -playableRect.size.height/2 + CGFloat(20))
    cameraNode.addChild(livesLabel)
    
    coinsLabel.text = "Coins: 0"
    coinsLabel.fontColor = SKColor.black
    coinsLabel.fontSize = 100
    coinsLabel.zPosition = 150
    coinsLabel.horizontalAlignmentMode = .right
    coinsLabel.verticalAlignmentMode = .bottom
    coinsLabel.position = CGPoint(
        x: playableRect.size.width/2 + CGFloat(10),
        y: -playableRect.size.height/2 + CGFloat(20))
    cameraNode.addChild(coinsLabel)
    
  }
  
  override func update(_ currentTime: TimeInterval) {
  
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    move(sprite: playerCar, velocity: velocity)
    boundsCheckPlayerCar()
    //checkCollisions()
    //moveTrain()
    moveCamera()
    livesLabel.text = "Lives: \(lives)"
    
    if lives <= 0 && !gameOver {
      gameOver = true
      backgroundMusicPlayer.stop()
      
      // 1
      let gameOverScene = GameOverScene(size: size, won: false)
      gameOverScene.scaleMode = scaleMode
      // 2
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      // 3
      view?.presentScene(gameOverScene, transition: reveal)
    }
    if(points >= 2 && !gameOver){
        gameOver = true
        backgroundMusicPlayer.stop()
        let myScene = GameSceneTwo(size: size)
        myScene.scaleMode = scaleMode
        let reveal = SKTransition.doorway(withDuration: 1.5)
        view?.presentScene(myScene, transition: reveal)
    }
        
  }
  
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),y: velocity.y * CGFloat(dt))
    sprite.position += amountToMove
  }
  
  func movePlayerCarToward(location: CGPoint) {
    let offset = location - playerCar.position
    let direction = offset.normalized()
    velocity = direction * playerCarMovePointsPerSec
  }
  
  func sceneTouched(touchLocation:CGPoint) {
    lastTouchLocation = touchLocation
    movePlayerCarToward(location: touchLocation)
  }

  override func touchesBegan(_ touches: Set<UITouch>,
      with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }

  override func touchesMoved(_ touches: Set<UITouch>,
      with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  func boundsCheckPlayerCar() {
    let bottomLeft = CGPoint(x: cameraRect.minX+200, y: cameraRect.minY)
    let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
    
    if playerCar.position.x <= bottomLeft.x {
      playerCar.position.x = bottomLeft.x
      velocity.x = abs(velocity.x)
    }
    if playerCar.position.x >= topRight.x {
      playerCar.position.x = topRight.x
      velocity.x = -velocity.x
    }
    if playerCar.position.y <= bottomLeft.y {
      playerCar.position.y = bottomLeft.y
      velocity.y = -velocity.y
    }
    if playerCar.position.y >= topRight.y {
      playerCar.position.y = topRight.y
      velocity.y = -velocity.y
    }
  }
  
  func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
    let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
    let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
    sprite.zRotation += shortest.sign() * amountToRotate
  }
  
  func spawnCar() {
    let car = SKSpriteNode(imageNamed: "car2")
    car.position = CGPoint(
      x: cameraRect.maxX + car.size.width/2,
      y: CGFloat.random(
        min: cameraRect.minY + car.size.height/2,
        max: cameraRect.maxY - car.size.height/2))
    car.zPosition = 50
    car.name = "car"
    car.setScale(0.5)
    addChild(car)
    
    let actionMove =
      SKAction.moveBy(x: -(size.width + car.size.width), y: 0, duration: 2.0)
    let actionRemove = SKAction.removeFromParent()
    car.run(SKAction.sequence([actionMove, actionRemove]))
  }
    
    func spawnPoliceCar() {
      let policeCar = SKSpriteNode(imageNamed: "police")
      policeCar.position = CGPoint(
        x: cameraRect.maxX + policeCar.size.width/2,
        y: CGFloat.random(
          min: cameraRect.minY + policeCar.size.height/2,
          max: cameraRect.maxY - policeCar.size.height/2))
      policeCar.zPosition = 50
      policeCar.name = "policecar"
        policeCar.setScale(0.8)
      addChild(policeCar)
      
      let actionMove =
        SKAction.moveBy(x: -(size.width + policeCar.size.width), y: 0, duration: 2.0)
      let actionRemove = SKAction.removeFromParent()
      policeCar.run(SKAction.sequence([actionMove, actionRemove]))
    }
  


  func playerCarHit(car: SKSpriteNode) {
    invincible = true
    let blinkTimes = 5.0
    let duration = 3.0
    let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
      let slice = duration / blinkTimes
      let remainder = Double(elapsedTime).truncatingRemainder(
        dividingBy: slice)
      node.isHidden = remainder > slice / 2
    }
    let setHidden = SKAction.run() { [weak self] in
      self?.playerCar.isHidden = false
      self?.invincible = false
    }
    playerCar.run(SKAction.sequence([blinkAction, setHidden]))
    
    run(enemyCollisionSound)
    
    lives -= 1
  }
    func playerPoliceCarHit(policecar: SKSpriteNode) {
      invincible = true
        let blinkTimes = 5.0
      let duration = 3.0
      let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
        let slice = duration / blinkTimes
        let remainder = Double(elapsedTime).truncatingRemainder(
          dividingBy: slice)
        node.isHidden = remainder > slice / 2
      }
      let setHidden = SKAction.run() { [weak self] in
        self?.playerCar.isHidden = false
        self?.invincible = false
      }
      playerCar.run(SKAction.sequence([blinkAction, setHidden]))
      run(enemyCollisionSound)
      points = points - 1
      lives -= 1
      coinsLabel.text = "Coins: \(points)"
    }

  func checkCollisions() {
    var hitCoins: [SKSpriteNode] = []
    enumerateChildNodes(withName: "coin") { node, _ in
      let coins = node as! SKSpriteNode
      if coins.frame.intersects(self.playerCar.frame) {
        hitCoins.append(coins)
      }
    }
    for coin in hitCoins {
      playerCarHit(coin: coin)
    }

    if invincible {
      return
    }
   
    var hitCars: [SKSpriteNode] = []
    enumerateChildNodes(withName: "car") { node, _ in
      let car = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20).intersects(
        self.playerCar.frame) {
        hitCars.append(car)
      }
    }
    for car in hitCars {
      playerCarHit(car: car)
    }
    
    
    var hitPoliceCars: [SKSpriteNode] = []
    enumerateChildNodes(withName: "policecar") { node, _ in
      let policecar = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20).intersects(
        self.playerCar.frame) {
        hitPoliceCars.append(policecar)
      }
    }
    for policecar in hitPoliceCars {
      playerPoliceCarHit(policecar: policecar)
    }
  }
  
  override func didEvaluateActions() {
    checkCollisions()
  }
  
   
  
  
  func backgroundNode() -> SKSpriteNode {
    // 1
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"

    // 2
    let background1 = SKSpriteNode(imageNamed: "background3")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    // 3
    let background2 = SKSpriteNode(imageNamed: "background3")
    background2.anchorPoint = CGPoint.zero
    background2.position =
      CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)

    // 4
    backgroundNode.size = CGSize(
      width: background1.size.width + background2.size.width,
      height: background1.size.height)
    return backgroundNode
  }
  
  func moveCamera() {
    let backgroundVelocity =
      CGPoint(x: cameraMovePointsPerSec, y: 0)
    //increase speed level two
    let amountToMove = backgroundVelocity * CGFloat(dt) * 5
    cameraNode.position += amountToMove
    
    enumerateChildNodes(withName: "background") { node, _ in
      let background = node as! SKSpriteNode
      if background.position.x + background.size.width <
          self.cameraRect.origin.x {
        background.position = CGPoint(
          x: background.position.x + background.size.width*2,
          y: background.position.y)
      }
    }
    
  }
  
  var cameraRect : CGRect {
    let x = cameraNode.position.x - size.width/2
        + (size.width - playableRect.width)/2
    let y = cameraNode.position.y - size.height/2
        + (size.height - playableRect.height)/2
    return CGRect(
      x: x,
      y: y,
      width: playableRect.width,
      height: playableRect.height)
  }
  //coins
    func spawnCoin() {
      // 1
      let coin = SKSpriteNode(imageNamed: "coin")
      coin.name = "coin"
      coin.position = CGPoint(
        x: CGFloat.random(min: cameraRect.minX,
                          max: cameraRect.maxX),
        y: CGFloat.random(min: cameraRect.minY,
                          max: cameraRect.maxY))
      coin.zPosition = 50
        coin.setScale(2)
      addChild(coin)
      // 2
      let appear = SKAction.scale(to: 2.0, duration: 0.5)
      coin.zRotation = -π / 16.0
      let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
      let rightWiggle = leftWiggle.reversed()
      let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
      
      let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
      let scaleDown = scaleUp.reversed()
      let fullScale = SKAction.sequence(
        [scaleUp, scaleDown, scaleUp, scaleDown])
      let group = SKAction.group([fullScale, fullWiggle])
      let groupWait = SKAction.repeat(group, count: 10)
      
      let disappear = SKAction.scale(to: 0, duration: 0.5)
      let removeFromParent = SKAction.removeFromParent()
      let actions = [appear, groupWait, disappear, removeFromParent]
      coin.run(SKAction.sequence(actions))
    }
    func playerCarHit(coin: SKSpriteNode) {
      coin.removeAllActions()
        coin.removeFromParent()
        coin.removeAllChildren()
      points = points + 1
     coinsLabel.text = "Coins: \(points)"
      run(catCollisionSound)
    }
    func playerPoliceCarHit(coin: SKSpriteNode) {
      coin.removeAllActions()
        coin.removeFromParent()
        coin.removeAllChildren()
      points = points - 1
     coinsLabel.text = "Coins: \(points)"
      run(catCollisionSound)
    }

}



























/*
class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//richu") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
*/
