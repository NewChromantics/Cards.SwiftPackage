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


func GetPokerPipMatrix(iconCount:Int) -> [Int]
{
	//	layout is 3 columns
	//	<4 all in center
	//	other wise edge and remainder in middle
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
}

struct PipLayout
{
	var columns : Int
	var maxRows : Int
	var positions : [CGPoint]
}

//	get normalised coords which are consistent, so can be cached
func GetPokerPipLayout(iconCount:Int) -> PipLayout
{
	let columnRows = GetPokerPipMatrix(iconCount: iconCount)

	let columnCount = columnRows.count
	let biggestRowCount = columnRows.max() ?? 1

	var pipCenters = [CGPoint]()
	
	//	todo: some predefined layouts for specific cards
	
	for columnIndex in 0..<columnRows.count
	{
		let rows = columnRows[columnIndex]
		for rowIndex in 0..<rows
		{
			//	calc center
			var x = CGFloat(columnIndex) / CGFloat(max(1,columnCount-1))

			//	todo: center column, align to middle, instead of top/bottom
			//			unless the outer columns are empty
			if columnIndex == 1 && columnRows[0] > 0
			{
				var y = /*rows==1 ? 0.5 : */CGFloat(rowIndex+1) / CGFloat(max(1,biggestRowCount))
				pipCenters.append( CGPoint(x:x,y:y) )
			}
			else
			{
				var x = CGFloat(columnIndex) / CGFloat(max(1,columnCount-1))
				var y = rows==1 ? 0.5 : CGFloat(rowIndex) / CGFloat(max(1,rows-1))
				pipCenters.append( CGPoint(x:x,y:y) )
			}
		}
	}

	let layout = PipLayout(columns: columnCount, maxRows: biggestRowCount, positions: pipCenters)
	return layout
}

private var PipLayoutCache = [Int:PipLayout]()

func GetCachedPokerPipLayout(iconCount:Int) -> PipLayout
{
	if let cache = PipLayoutCache[iconCount]
	{
		return cache
	}
	
	let Layout = GetPokerPipLayout(iconCount:iconCount)
	PipLayoutCache[iconCount] = Layout
	return Layout
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
		let columnRows = GetPokerPipMatrix(iconCount: iconCount)
		
		let iconSpacing = 2.0
		HStack(spacing:iconSpacing)
		{
			ForEach(columnRows.indices)
			{
				columnIndex in
				let rowCount = columnRows[columnIndex]
				VStack(spacing:iconSpacing)
				{
					let rows = max(0,rowCount)
					ForEach(0..<rows)
					{
						_ in
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

func Lerp(_ min:CGFloat,_ max:CGFloat,_ value:CGFloat) -> CGFloat
{
	return (value * (max-min)) + min
}

func NormalToRect(_ tx:CGFloat,_ ty:CGFloat,rect:[CGFloat]) -> CGPoint
{
	let x = Lerp(rect[0], rect[0]+rect[2], tx)
	let y = Lerp(rect[1], rect[1]+rect[3], ty)
	return CGPoint(x:x,y:y)
}			


struct CardIconStack : View
{
	var iconCount : Int
	var icon : Image
	var iconColour : Color
	
	var body: some View
	{
		let pipLayoutNormalised = GetCachedPokerPipLayout(iconCount: iconCount)

		Canvas(rendersAsynchronously: true)
		{
			context,canvasSize  in
			
			let columnCount = pipLayoutNormalised.columns
			let rowCount = pipLayoutNormalised.maxRows
			
			var resolvedIcon = context.resolve(icon)
			//	https://stackoverflow.com/a/76207661/355753
			//	for this to work, svg's need Resizing:Preserve Vector Data
			resolvedIcon.shading = .color(iconColour)

			let iconRatio = resolvedIcon.size.height / resolvedIcon.size.width
			let columnWidth = canvasSize.width / CGFloat(columnCount)
			let rowHeight = canvasSize.height / CGFloat(rowCount)
			
			//	fit icon to row or column
			var IconSize = CGSize(width: columnWidth, height: columnWidth * iconRatio)
			if ( IconSize.height > rowHeight )
			{
				IconSize = CGSize(width: rowHeight/iconRatio, height:rowHeight )
			}
			
			let IconPad = IconSize.width * 0.05
			let ImageSize = CGSize(width:IconSize.width-IconPad-IconPad,height:IconSize.height-IconPad-IconPad)

			var DrawRect = [0,0,canvasSize.width,canvasSize.height]
			let CanvasPadX = IconSize.width / 2.0
			let CanvasPadY = IconSize.height / 2.0
			DrawRect[0] += CanvasPadX
			DrawRect[1] += CanvasPadY
			DrawRect[2] -= CanvasPadX * 2.0
			DrawRect[3] -= CanvasPadY * 2.0
			
			pipLayoutNormalised.positions.forEach
			{
				center in
				let pos = NormalToRect( center.x, center.y, rect:DrawRect )
				
				//	calculate rect with padding
				let iconPos = CGPoint(x: pos.x-(ImageSize.width/2.0), y: pos.y-(ImageSize.height/2.0))
				let rect = CGRect(origin: iconPos, size: ImageSize)
				context.draw(resolvedIcon,in: rect)
			}
		}
	
		
	}
}


//	rank
public typealias CardRank = Int

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
	init(integerLiteral value: Int)
	{
		//self = CardRank(value)
		self = value
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
			case "t":	self.init(CardRank.t)
			case "j":	self.init(CardRank.jack)
			case "q":	self.init(CardRank.queen)
			case "k":	self.init(CardRank.king)
			case "a":	self.init(CardRank.ace)
			default:
				//	stop recursive call
				self = (value as NSString).integerValue
				//self = Int(stringLiteral: value)
		}
	}
}


public struct CardMeta : Transferable, Codable, Hashable, ExpressibleByStringLiteral
{
	public typealias StringLiteralType = String
	
	public static var transferRepresentation : some TransferRepresentation
	{
		CodableRepresentation(contentType:.text)
	}
	
	var value : CardRank
	var suit : String

	public init(stringLiteral: Self.StringLiteralType)
	{
		self.init(stringLiteral)
	}
	
	//	shorthand for QH (queen heart)
	public init(_ valueAndSuit:String)
	{
		if valueAndSuit.count != 2
		{
			//throw RuntimeError("CardMeta code needs to be 2 chars Value|Suit")
		}
		let v = String(valueAndSuit[0])
		self.value = CardRank(stringLiteral: v)
		self.suit = CardSuit.GetSuitFromCode(valueAndSuit[1])
	}
		
	
	public init(value: CardRank, suit: String)
	{
		self.value = value
		self.suit = suit
	}
	
	public init(_ value: Int, _ suit: String)
	{
		self.value = CardRank(integerLiteral:value)
		self.suit = suit
	}
}


//	add extensions to this...
//	does it need to be an enum?
extension CardSuit
{
	static func GetDefaultColourFor(suit:String) -> Color?
	{
		//	on ios, having an asset named same as an image crashes
		//	gr: the crash comes when using an image, but finds a colour
		let suitColourNameA = suit
		let suitColourNameB = "\(suit)_SuitColour"
		
		if let assetColour = UIColor(named:suitColourNameA)
		{
			return Color(assetColour)
		}
		if let assetColour = UIColor(named:suitColourNameB)
		{
			return Color(assetColour)
		}
		switch suit
		{
			case CardSuit.spade:	return Color.black
			case CardSuit.club:		return Color.black
			case CardSuit.heart:	return Color.red
			case CardSuit.diamond:	return Color.red
			default:		return nil
		}
	}
	
	static func GetSuitFromCode(_ char:Character) -> String
	{
		switch char
		{
			case "h":	return CardSuit.heart
			case "s":	return CardSuit.spade
			case "d":	return CardSuit.diamond
			case "c":	return CardSuit.club
			default:	return String(char)
		}
	}
}

public class CardSuit
{
	static public let heart = "suit.heart.fill"
	static public let spade = "suit.spade.fill"
	static public let club = "suit.club.fill"
	static public let diamond = "suit.diamond.fill"
	static public let allSuits = [heart,spade,club,diamond]
	
	static public var randomSuit : String
	{
		return allSuits.randomElement()!
	}
}

struct CardStyle
{
	var width : CGFloat = 80	//	in future use geometry reader
	
	var isTinyCard : Bool		{	height < (CardStyle.pipMinWidth*8)	}	//	gr: vertical matters more!
	
	static let standardHeightRatio = 1.4//1.4 is real card
	let heightRatio = CardStyle.standardHeightRatio
	var height : CGFloat {	width * heightRatio	}
	var cornerRadius : CGFloat { width * 0.09 }
	var paperBorder : CGFloat { width * 0.04 }
	var paperBackingBorder : CGFloat { width * 0.06 }
	//var pipMinWidth : CGFloat { isTinyCard ? width*0.5 : 8 }
	static var pipMinWidth = 8.0	//	needs to be at least 4/5 to stop coregraphics errors where it makes NaNs
	var pipWidth : CGFloat { max( CardStyle.pipMinWidth, isTinyCard ? width * 0.50 : width * 0.15 ) }
	var pipHeight : CGFloat { pipWidth }
	
	var innerBorderCornerRadius : CGFloat { width * 0.03 }
	//var innerBorderColour : Color { Color.blue }	//	for around queens etc
	var innerBorderColour : Color { Color.clear }
	var innerBorderPaddingHorizontal : CGFloat = 2
	var innerBorderPaddingVertical : CGFloat = 10
	
	init(fit:CGSize)
	{
		//	see if we need to make width shrink down to fit height
		let height = fit.width * heightRatio
		if height > fit.height
		{
			self.width = fit.height / heightRatio
		}
		else
		{
			self.width = fit.width
		}
	}
}

public struct CardView : View
{
	var enableDebug = false
	var debugString : String? = nil
	var cardMeta : CardMeta?
	var value : CardRank? { cardMeta?.value }
	var suit : String? { cardMeta?.suit }	//	sf symbol
	var faceUp : Bool
	var shadowsEnabled : Bool
	var isSolidCard : Bool { cardMode != .EmptySlot }
	var suitSystemImageName : String	{	return suit	?? "x.circle" }
	var pip : Image!//	{	GetPipImage()	}
	var cardMode : CardMode!//	{	GetCardMode()	}
	var backing : LinearGradient!//any ShapeStyle//	{	GetBacking()	}

	public init(cardMeta:CardMeta?,faceUp:Bool=true,z: CGFloat=0,shadows:Bool=true,debugString:String?=nil)
	{
		self.debugString = debugString
		self.cardMeta = cardMeta
		self.faceUp = faceUp
		self.z = z
		self.shadowsEnabled = shadows
		
		//	cache stuff
		self.pip = GetPipImage()
		self.cardMode = GetCardMode()
		self.backing = GetBacking()
	}
	
	
	enum CardMode
	{
		case EmptySlot
		case UnknownCard
		case Card
	}

	func GetCardMode() -> CardMode
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

	func GetPipImage() -> Image
	{
		let imageName = suitSystemImageName
		//	on ios (not macos), using UIImage(named:) will crash if there's a colour asset of the same name
		//	even if the symbol is a system image
		//	so if there's a matching asset colour, we have to bail out
		let assetColour = UIColor(named:imageName)
		if assetColour == nil 
		{
			if let assetImage = UIImage(named: imageName) ?? UIImage(symbolName: imageName, variableValue: 0.0)
			{
				return Image(uiImage:assetImage)
			}
		}
		return Image(systemName:suitSystemImageName)
	}


	
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
	

	func GetBacking() -> LinearGradient//some ShapeStyle
	{
		//	only UIKit colours are null if missing
		let gradientColours = ["BackingGradient0","BackingGradient1","BackingGradient2","BackingGradient3"].map
		{
			if let colour = UIColor(named:$0)
			{
				return Color(colour)
			}
			else
			{
				return Color.red
			}
		}
		return LinearGradient(colors:gradientColours, startPoint: .topLeading, endPoint: .bottomTrailing)//, center: .center, startRadius:15, endRadius:50)
	}
	var pipColour : Color	{	suitColour ?? Color.blue	}
	var paperColour : Color { cardMode == .EmptySlot ? Color.clear : (Color(UIColor(named:"Paper") ?? UIColor.white))	}
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
		let multiColour = false//suit == "rainbow"
		
		pip
			.resizable()
			.scaledToFit()
			.foregroundStyle(pipColour/*, accentColour*/)
			.symbolRenderingMode( multiColour ? .multicolor : .monochrome )
			//	when svgs get too small, coregraphics starts breaking with NaNs
			//	we get around this by having a min size (1 is too small!)
			//	ideally we make a mipped image for tiny cases
			.frame(minWidth: CardStyle.pipMinWidth,minHeight: CardStyle.pipMinWidth)
	}
	
	@ViewBuilder
	func cornerPipView(_ style:CardStyle,center:Bool=false) -> some View
	{
		//	pip
		HStack(alignment: center ? .center : .top)
		{
			VStack(alignment:.center, spacing:0)
			{
				Text( value?.description ?? "no value" )
					.foregroundStyle(pipColour)
					.lineLimit(1)
					.font(.system(size: style.pipHeight))
					.fontWeight(.bold)

				pipView
					.frame(width: style.pipWidth,height: style.pipHeight)
				
				if !center
				{
					Spacer()
				}
			}
			if !center
			{
				Spacer()
			}
		}
	}
	
	//	view for the center of the card
	//	either a bunch of pips, or a big image!
	@ViewBuilder
	func ValueView(_ style:CardStyle) -> some View
	{
		/*
		IconStack(iconCount:value ?? 0)
		{
			pipView
		}
		 */
		CardIconStack(iconCount: value ?? 0, icon: GetPipImage(), iconColour: pipColour )
			//.background(.yellow)	//	debug inner value area
			.padding([.leading,.trailing],style.innerBorderPaddingHorizontal)
			.padding([.top,.bottom],style.innerBorderPaddingVertical)
			//.background(.green)	//	debug inner value area
			.frame(maxWidth: .infinity,maxHeight: .infinity)
	}
	
	//	*nicely* handly polyfill for rounded rectangle
	@ViewBuilder
	func RoundedRect(cornerRadius:CGFloat,borderColour:Color,borderStyle:StrokeStyle,fill:Color?) -> some View
	{
		if #available(macOS 14.0,iOS 17.0, *)
		{
			RoundedRectangle(cornerRadius: cornerRadius)
				.fill( fill ?? Color.clear )
				.stroke(borderColour ?? Color.clear,style:borderStyle)
		}
		else
		{
			let x = RoundedRectangle(cornerRadius: cornerRadius)
			Rectangle()
				.background(x)
		}
	}
	
	@ViewBuilder
	func cardBody(/*_ style:CardStyle*/) -> some View
	{
		GeometryReader
		{
			geometry in
			let style = CardStyle(fit: geometry.size)

			VStack(spacing: 0)
			{
				if cardMode == .EmptySlot
				{
					RoundedRectangle(cornerRadius: style.cornerRadius)
						.stroke(emptySlotEdgeColour,style: emptySlotEdge)
					//Text("x")
				}
				else
				{
					RoundedRect(cornerRadius: style.cornerRadius, borderColour: paperEdgeColour, borderStyle: paperEdge, fill: paperColour)
						.overlay
						{
							var showFace = (flipRotation.animatableData < 90)
							if !showFace//cardMode == .UnknownCard
							{
								RoundedRectangle(cornerRadius: style.cornerRadius)
									.fill(backing)
									.padding(style.paperBackingBorder)
									//.frame(maxWidth: .infinity,maxHeight: .infinity)
							}
							else if style.isTinyCard
							{
								cornerPipView(style,center: true)
							}
							else // if faceUp
							{
								ZStack
								{
									ValueView(style)
										.padding([.leading,.trailing],style.pipWidth)
									cornerPipView(style)
									cornerPipView(style)
										.rotationEffect(.degrees(180))
								}
								.padding(style.paperBorder)
							}
							
						}
				}
			}
			.frame(maxWidth: .infinity,maxHeight: .infinity)
			/*
			.clipShape(
				RoundedRectangle(cornerRadius: style.cornerRadius)
			)
			 */
			//.animation(nil)	//	stops lerp between views so card face doesnt fade as it flips
		}
	}
	

	public var body: some View
	{
		let style = CardStyle(fit:CGSize(width:50,height:90))
		cardBody()
			.transition(.scale(1))
			.aspectRatio(CGSize(width:1,height:CardStyle.standardHeightRatio), contentMode: .fit)
			//.frame(width:style.width,height: style.height)
			.rotation3DEffect( .degrees(flipRotation), axis:(x:0,y:1,z:0), perspective:0.1 )
			.animation(.interpolatingSpring(duration:flipRotationDuration,bounce:0.3,initialVelocity: 7), value: flipRotation)
		//	add & depth shadow after rotation otherwise it rotates the offset&shadow
			.if(isSolidCard && shadowsEnabled)
			{
				$0
					.shadow(radius: shadowRadius,x:shadowOffsetX,y:shadowOffsetY)
			}
			.offset(x:posOffsetX,y:posOffsetY)
			.overlay
		{
			if enableDebug
			{
				let code = self.cardMeta.map{ "\($0.value) \($0.suit)" } ?? "null"
				let up = faceUp ? "UP" : ""
				Text("\(code) \(up)")
				let debugName = debugString ?? ""
				Text("\(code) \(up) \(uprev) \(debugName)")
					.font(.system(size:8))
					.background(.black)
					.foregroundStyle(.white)
			}
		}
		//	we dont set size here, only aspect ratio, this locks the geometry size for cardbody
			//.frame(width: style.width/*,height:style.height*/)
	}
}



//	this is a bit of a demo/test, rather than an actual usable card
public struct InteractiveCard : View
{
	@State public var cardMeta : CardMeta?
	@State public var z : CGFloat = 0
	@State public var faceUp = true
	@State public var isDropping = false
	
	public init(cardMeta: CardMeta?,faceUp: Bool=true)
	{
		//	when being forced to add an init to a view, init the state properly
		_cardMeta = State(initialValue: cardMeta)
		_faceUp = State(initialValue: faceUp)
	}
	
	//@State var droppingMeta : CardMeta? = nil
	public var droppingMeta : CardMeta?
	{
		if ( isDropping )
		{
			return CardMeta(value: 1, suit:"arrowshape.down.fill")
		}
		return nil
	}

	
	public var body : some View
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


@ViewBuilder
func RenderRowsOfCards(_ cards:[[CardMeta?]]) -> some View
{
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
	.padding(10)
	.background( Color( UIColor(named:"Felt") ?? UIColor.green ) )
	.preferredColorScheme(.light)
}


#Preview
{
	let cards2 = [
		[
			CardMeta("Ah"),
			CardMeta("2c"),
			CardMeta("3s"),
			CardMeta("4d"),
			CardMeta("5c"),
			CardMeta("6s"),
			CardMeta("7h"),
		],
		[
			CardMeta("8d"),
			CardMeta("9s"),
			CardMeta("Th"),
			CardMeta("Jc"),
			CardMeta("Qd"),
			CardMeta("Kh"),
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
	
	RenderRowsOfCards(cards2)
	RenderRowsOfCards(cards)
}

