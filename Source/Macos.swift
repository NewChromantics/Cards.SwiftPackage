/*
	ios <> macos compatibility.
	Use UIImage (ios) instead of NSImage(macos)
*/
import SwiftUI

#if canImport(UIKit)//ios
#else
typealias UIImage = NSImage
#endif


#if canImport(UIKit)//ios
#else

//	use same Image(uiImage:) constructor on macos & ios
extension Image
{
	init(uiImage:UIImage)
	{
		self.init(nsImage:uiImage)
	}
}
#endif

