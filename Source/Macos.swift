/*
	ios <> macos compatibility.
	Use UIImage (ios) instead of NSImage(macos)
*/
import SwiftUI


#if !canImport(UIKit)
public typealias UIColor = NSColor
public typealias UIImage = NSImage
#endif

//	ios doesn't have a constructor for symbolName, it works via named:
//	macos has seperate constructors
#if canImport(UIKit)//ios
extension UIImage
{
	public convenience init?(symbolName:String,variableValue:CGFloat)
	{
		self.init(named:symbolName)
	}
}
#endif

#if !canImport(UIKit)

//	use same Image(uiImage:) constructor on macos & ios
extension Image
{
	public init(uiImage:UIImage)
	{
		self.init(nsImage:uiImage)
	}
}
#endif

