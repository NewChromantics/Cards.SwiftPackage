import SwiftUI


public protocol CardViewModifer : ViewModifier
{
	init(card:CardMeta)
}


public struct EmptyCardViewModifer : CardViewModifer
{
	public init(card:CardMeta) 
	{
	}
	
	public func body(content: Content) -> some View
	{
		content
	}
}
