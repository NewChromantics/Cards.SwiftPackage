import SwiftUI
import Spatial

//	add .if modifier
extension View {
	/// Applies the given transform if the given condition evaluates to `true`.
	/// - Parameters:
	///   - condition: The condition to evaluate.
	///   - transform: The transform to apply to the source `View`.
	/// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
	@ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}




extension StringProtocol
{
	subscript(offset: Int) -> Character { self[index(startIndex, offsetBy: offset)] }
	subscript(range: Range<Int>) -> SubSequence {
		let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
		return self[startIndex..<index(startIndex, offsetBy: range.count)]
	}
	subscript(range: ClosedRange<Int>) -> SubSequence {
		let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
		return self[startIndex..<index(startIndex, offsetBy: range.count)]
	}
	subscript(range: PartialRangeFrom<Int>) -> SubSequence { self[index(startIndex, offsetBy: range.lowerBound)...] }
	subscript(range: PartialRangeThrough<Int>) -> SubSequence { self[...index(startIndex, offsetBy: range.upperBound)] }
	subscript(range: PartialRangeUpTo<Int>) -> SubSequence { self[..<index(startIndex, offsetBy: range.upperBound)] }
}



//	https://www.swiftbysundell.com/articles/switching-between-swiftui-hstack-vstack/
struct IconStack<Content: View>: View
{
	//var horizontalAlignment = HorizontalAlignment.center
	//var verticalAlignment = VerticalAlignment.top
	//var spacing: CGFloat?
	var iconCount : Int
	@ViewBuilder var content: () -> Content
	
	var body: some View
	{
		//	layout is 3 columns
		//	<4 all in center
		//	other wise edge and remainder in middle
		let columnRows : [Int] = {
			if iconCount == 1
			{
				return [1]
			}
			else if iconCount < 4
			{
				return [0,iconCount,0]
			}
			else if iconCount > 6 || (iconCount%2)==1
			{
				//	when odd number
				//	put more on the outside but even up
				var side = iconCount/3
				var remain = (iconCount - side - side) % iconCount
				if remain >= side && remain > 1
				{
					remain -= 2
					side += 1
				}
				return [side,remain,side]
			}
			else
			{
				let side = iconCount/2
				let remain = (iconCount - side - side) % iconCount
				return [side,remain,side]
			}
		}()
		
		let iconSpacing = 2.0
		
		HStack(spacing:iconSpacing)
		{
			ForEach(columnRows, id:\.self)
			{
				rowCount in
				VStack(spacing:iconSpacing)
				{
					let rows = max(0,rowCount)
					ForEach(0..<rows)
					{_ in
						content()
							//	fill column so items dont bunch in middle
							.frame(maxHeight: .infinity)
							//.background(.blue)
					}
					if rows == 0
					{
						//Text("x")
						Spacer()
					}
				}
				//	forces equal width
				.frame(minWidth: 0, maxWidth: .infinity)
				//.background(.yellow)
			}
		}
		//.frame(minWidth: 0, maxWidth: .infinity)
	}
}



//	rank
typealias CardRank = Int

extension CardRank
{
	static let t = CardRank(10)
	static let jack = CardRank(11)
	static let queen = CardRank(12)
	static let king = CardRank(13)
	static let ace = CardRank(1)
}

extension CardRank : ExpressibleByIntegerLiteral
{
	init(integerLiteral value: Int) {
		self = CardRank(value)
	}
}

//	we can't use CustomStringConvertible, but we can just override .description
extension CardRank //: CustomStringConvertible
{
	var description: String
	{
		switch self
		{
			case .jack:	return "J"
			case .queen:	return "Q"
			case .king:	return "K"
			case .ace:	return "A"
			default:	return String(self)
		}
	}
}

extension CardRank : ExpressibleByStringLiteral
{
	public init(stringLiteral value: String) /*throws*/
	{
		switch value
		{
			case "T":	self.init(CardRank.t)
			case "J":	self.init(CardRank.jack)
			case "Q":	self.init(CardRank.queen)
			case "K":	self.init(CardRank.king)
			case "A":	self.init(CardRank.ace)
			//default:	return nil
			default:	self = 0
		}
	}
}


struct CardMeta : Transferable, Codable, /*Identifiable,*/ Hashable
{
	//	in case we want 2 cards with the same rank&suit
	//	dont make the id the rank&suit
	var id = UUID()
	
	static var transferRepresentation : some TransferRepresentation
	{
		CodableRepresentation(contentType:.text)
	}
	
	var value : CardRank
	var suit : String


	//	shorthand for QH (queen heart)
	init(_ valueAndSuit:String)
	{
		if valueAndSuit.count != 2
		{
			//throw RuntimeError("CardMeta code needs to be 2 chars Value|Suit")
		}
		let v = String(valueAndSuit[0])
		self.value = CardRank(stringLiteral: v)
		self.suit = String(valueAndSuit[1])
	}
		
	
	init(value: CardRank, suit: String)
	{
		self.value = value
		self.suit = suit
	}
	
	init(_ value: Int, _ suit: String)
	{
		self.value = CardRank(integerLiteral:value)
		self.suit = suit
	}
}

#if !canImport(UIKit)
typealias UIColor = NSColor
#endif

//	add extensions to this...
//	does it need to be an enum?
extension CardSuit
{
	static func GetDefaultColourFor(suit:String) -> Color?
	{
		if let assetColour = UIColor(named:suit)
		{
			return Color(assetColour)
		}
		return nil
	}
}

class CardSuit
{
	static let heart = "suit.heart.fill"
	static let spade = "suit.spade.fill"
	static let club = "suit.club.fill"
	static let diamond = "suit.diamond.fill"
}



struct CardStyle
{

}



struct CardView : View
{
	var cardMeta : CardMeta?
	var value : CardRank? { cardMeta?.value }
	var suit : String? { cardMeta?.suit }	//	sf symbol
	var faceUp : Bool = true

	enum CardMode
	{
		case EmptySlot
		case UnknownCard
		case Card
	}
	var cardMode : CardMode
	{
		if cardMeta == nil
		{
			return .EmptySlot
		}
		else if !faceUp
		{
			return .UnknownCard
		}
		else
		{
			return .Card
		}
	}
	var isSolidCard : Bool { cardMode != .EmptySlot }

	var suitSystemImageName : String	{	return suit	?? "x.circle" }
	var pip : Image 	{ Image(systemName:suitSystemImageName)	}
	

	let width : CGFloat = 80	//	in future use geometry reader
	let heightRatio = 1.4//1.4 is real card
	var height : CGFloat {	width * heightRatio	}
	var cornerRadius : CGFloat { width * 0.09 }
	var paperBorder : CGFloat { width * 0.04 }
	var paperBackingBorder : CGFloat { width * 0.06 }
	var pipMinWidth : CGFloat { 8 }
	var pipWidth : CGFloat { max( pipMinWidth, width * 0.15) }
	var pipHeight : CGFloat { pipWidth }
	
	var innerBorderCornerRadius : CGFloat { width * 0.03 }
	//var innerBorderColour : Color { Color.blue }	//	for around queens etc
	var innerBorderColour : Color { Color.clear }
	var innerBorderPadding : CGFloat = 4

	
	var z : CGFloat = 0
	var zXMult : CGFloat { 0.2 }
	var zYMult : CGFloat { 1.0 }
	var minz = 1.5
	var depth : CGFloat { max(minz,z)	}
	var shadowOffsetX : CGFloat { depth * 1.0 * zXMult }
	var shadowOffsetY : CGFloat { depth * 1.0 * zYMult }
	var posOffsetX : CGFloat { depth * -zXMult }
	var posOffsetY : CGFloat { depth * -zYMult }
	var shadowSofteness : CGFloat	{ 0.30	}//0..1
	var shadowRadius : CGFloat	{ depth / (10.0 * (1.0-shadowSofteness) ) }


	var backing : some ShapeStyle
	{
		return LinearGradient(colors: [Color("BackingGradient0"),Color("BackingGradient1"),Color("BackingGradient2"),Color("BackingGradient3")], startPoint: .topLeading, endPoint: .bottomTrailing)//, center: .center, startRadius:15, endRadius:50)
	}
	var pipColour : Color	{	suitColour ?? Color.blue	}
	var paperColour : Color { cardMode == .EmptySlot ? Color.clear : Color("Paper")	}
	var paperEdge = StrokeStyle(lineWidth: 0.5)
	var paperEdgeColour = Color.gray
	var emptySlotEdge = StrokeStyle(lineWidth: 1.0, dash: [3,5], dashPhase: 0 )
	var emptySlotEdgeColour = Color.black
	
	var suitColour : Color? { return (suit != nil) ? CardSuit.GetDefaultColourFor(suit:suit!) : nil }
	
	var flipRotation : CGFloat {faceUp ? 0 : 180}
	var flipRotationDuration = 1.0

	
	@ViewBuilder
	var pipView : some View
	{
		//	special case :)
		let multiColour = suit == "rainbow"
		
		pip
			.resizable()
			.scaledToFit()
			.foregroundStyle(pipColour/*, accentColour*/)
			.symbolRenderingMode( multiColour ? .multicolor : .monochrome )
	}
	
	var cornerPipView : some View
	{
		//	pip
		HStack(alignment: .top)
		{
			VStack(alignment:.center, spacing:0)
			{
				Text( value?.description ?? "no value" )
					.foregroundStyle(pipColour)
					.lineLimit(1)
					.font(.system(size: pipHeight))
					.fontWeight(.bold)

				pipView
					.frame(width: pipWidth,height: pipHeight)
				
				Spacer()
			}
			Spacer()
		}
	}
	
	//	view for the center of the card
	//	either a bunch of pips, or a big image!
	@ViewBuilder
	var ValueView : some View
	{
		IconStack(iconCount:value ?? 0)
		{
			pipView
		}
		.padding(innerBorderPadding)
		//.background(.green)
		.frame(maxWidth: .infinity,maxHeight: .infinity)
		//.background(.yellow)
		//.border(.blue)
		/*
		.overlay(
			RoundedRectangle(cornerRadius: innerBorderCornerRadius)
				.stroke( innerBorderColour, lineWidth: borderWidth)
		)
		 */
		.padding(innerBorderPadding)

	}
	
	@ViewBuilder
	func cardBody() -> some View
	{
		VStack(spacing: 0)
		{
			if cardMode == .EmptySlot
			{
				Spacer()
			}
			else
			{
				Rectangle()
				.fill(paperColour)
				.overlay
				{
					var showFace = (flipRotation.animatableData < 90)
					if !showFace//cardMode == .UnknownCard
					{
						RoundedRectangle(cornerRadius: cornerRadius)
							.fill(backing)
							.padding(paperBackingBorder)
					}
					else // if faceUp
					{
						ZStack
						{
							ValueView
								.padding(pipWidth)
							cornerPipView
							cornerPipView
								.rotationEffect(.degrees(180))
						}
						.padding(paperBorder)
					}
				}
			}
		}
		//.animation(nil)	//	stops lerp between views
	}
	

	var body: some View
	{
		cardBody()
		.clipShape(
			RoundedRectangle(cornerRadius: cornerRadius)
		)
		//.padding(paperBorder)
		//.background(paperColour)
		.clipShape(
			RoundedRectangle(cornerRadius: cornerRadius)
		)
		.frame(width:width,height: height)
		.rotation3DEffect( .degrees(flipRotation), axis:(x:0,y:1,z:0), perspective:0.1 )
		.animation(.interpolatingSpring(duration:flipRotationDuration,bounce:0.3,initialVelocity: 7), value: flipRotation)
		//	add & depth shadow after rotation otherwise it rotates the offset&shadow
		.if(isSolidCard)
		{
			$0
				.shadow(radius: shadowRadius,x:shadowOffsetX,y:shadowOffsetY)
				.overlay(
					RoundedRectangle(cornerRadius: cornerRadius)
						.stroke(paperEdgeColour,style:paperEdge)
				)
		}
		.if(!isSolidCard)
		{
			$0
				.overlay(
					RoundedRectangle(cornerRadius: cornerRadius)
						.stroke(emptySlotEdgeColour,style: emptySlotEdge)
				)
		}
		.offset(x:posOffsetX,y:posOffsetY)

	}
}



//	this is a bit of a demo/test, rather than an actual usable card
struct InteractiveCard : View
{
	@State var cardMeta : CardMeta?
	@State var z : CGFloat = 0
	@State var faceUp = true

	//@State var droppingMeta : CardMeta? = nil
	var droppingMeta : CardMeta?
	{
		if ( isDropping )
		{
			return CardMeta(value: 1, suit:"arrowshape.down.fill")
		}
		return nil
	}
	@State var isDropping = false

	
	var body: some View
	{
		let draggable = ( cardMeta != nil )
		let droppable = !draggable
		var renderCard = droppingMeta ?? cardMeta
		var up = isDropping ? true : faceUp
		
		CardView(cardMeta:renderCard, faceUp:up, z:z )
			//.fixedSize()	//	https://notes.alinpanaitiu.com/How-I-made-my-SwiftUI-calendar-app-3x-faster no real speedup
			.animation(.interactiveSpring, value: z)
			.if(!draggable)
			{
				$0.dropDestination(for: CardMeta.self)
				{
					droppingData, position in
					print("dropping data \(position)")

					//	happens if type different to for:
					if droppingData.isEmpty
					{
						return false
					}
					self.cardMeta = droppingData[0]
					//	todo: wipe source
					//			we cant really access this, which reveals that we want to store the
					//			layout in seperate state
					return false
				}
				isTargeted:
				{
					isDropping = $0
					//isDropTargeted = $0
					//return true
				}
			}
			.if(draggable)
			{
				$0
					.draggable(cardMeta!)
				{
					CardView(cardMeta: cardMeta,faceUp:faceUp, z:0)
				}
				.onHover
				{
					over in
					self.z = over ? 10 : 0
				}
				.onLongPressGesture(minimumDuration: 1)
				{
					print("Long pressed!")
				}
				onPressingChanged:
				{
					over in
					self.z = over ? 10 : 0
				}
				.onTapGesture
				{
					self.faceUp = !self.faceUp
				}
			}
		
	}
	
	//func process(titles: [String]) { ... }
	//func animateDrop(at: CGPoint) { ... }
}


#Preview {
	let cards2 = [
		[
			CardMeta(value:7,suit: CardSuit.heart),
			CardMeta(value:2,suit: CardSuit.spade),
		]
	]
	let cards = [
		[
			CardMeta(value:1,suit: "bolt.fill"),
			CardMeta(value:2,suit: CardSuit.spade),
			nil,
			CardMeta(value:3,suit: CardSuit.diamond),
			CardMeta(value:1,suit: "moon.fill"),
			nil,
			CardMeta(value:5,suit: "star.fill"),
			CardMeta(value:6,suit: CardSuit.club),
		],
		[
			CardMeta(value:7,suit: CardSuit.club),
			nil,
			CardMeta(value:8,suit: "arrowshape.left.fill"),
			CardMeta(value:9,suit: CardSuit.heart),
			CardMeta(value:.queen,suit: "baseball.fill"),
			nil,
			nil,
			CardMeta(value:13,suit: "leaf.fill"),
		//CardMeta("TH")
		],
		[
			nil,
			CardMeta(value:14,suit: "cloud.drizzle.fill"),
			CardMeta(value:15,suit: "sun.max.fill"),
			CardMeta(value:16,suit: "powerplug.portrait.fill"),
			CardMeta(value:3,suit: "sun.max.fill"),
			CardMeta(value:20,suit: "rainbow"),
			CardMeta(value:1,suit: "rainbow"),
			nil,
		],
		[
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil
		]
	]
	 
	
	let spacing = 5.0
	VStack(spacing:spacing)
	{
		ForEach(Array(cards.enumerated()), id:\.element)
		{
			rowIndex,cardRow in
			HStack(spacing:spacing)
			{
				ForEach(Array(cardRow.enumerated()), id:\.element)
				{
					colindex,CardRank in
					let z = Int.random(in: 0...20)
					let faceUp = Int.random(in: 0...4) != 0
					//InteractiveCard(cardMeta: CardRank, z:CGFloat(z))
					InteractiveCard(cardMeta: CardRank,faceUp:faceUp)
				}
			}
		}
	}
	.padding(50)
	.background(Color("Felt"))
	.preferredColorScheme(.light)
}

