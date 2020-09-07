//
//  Created by Vladimir Burdukov on 9/6/20.
//

public enum BlockingSubscriberError: Error {
    case timeout
    case moreThanOneElement
    case noElements
}
