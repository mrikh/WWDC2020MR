import Foundation
import SpriteKit

public class ScoreLabelViewModel{

    private var scoreLabel : SKLabelNode?

    public var start = false{
        didSet{
            if start{
                startTimer()
            }else{
                stopTimer()
            }
        }
    }

    private var currentScore = 0
    private var timer : Timer?

    public convenience init(label : SKLabelNode?) {
        self.init()
        scoreLabel = label
    }

    public func resetScore(){
        currentScore = 0
        scoreLabel?.text = "Score : \(currentScore)"
    }

    public func getCurrentScore() -> Int{
        return currentScore
    }

    @objc func timerUpdate(){
        currentScore += 1
        scoreLabel?.text = "Score : \(currentScore)"
    }

    public func increaseScore(){

        currentScore += 1
    }

    //MARK:- Private
    private func startTimer(){

        if timer == nil{
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        }
    }

    private func stopTimer(){

        timer?.invalidate()
        timer = nil
    }
}
