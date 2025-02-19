import SwiftUI



struct LambdaViewModifier : ViewModifier
{
	var lambda : ((CardMeta,any View) -> AnyView)?
	var card : CardMeta
	
	func body(content: Content) -> some View 
	{
		Group
		{
			if let lambda
			{
				lambda(card, content)
			}
			else
			{
				content
			}
		}
	}
}


extension View 
{
	public func optionalOnTapGesture(enabled: Bool, count: Int = 1, perform action: @escaping () -> Void) -> some View 
	{
		Group 
		{
			if enabled 
			{
				self.onTapGesture(count: count, perform: action)
			}
			else 
			{
				self
			}
		}
	}
}


public struct CardPile : View 
{
	var debugName : String?
	let cardDeckNamespace : Namespace.ID
	var cards : [CardMeta]
	public var allCardsFaceUp : Bool
	public var allCardsPipOnly : Bool
	var cardZSpacing : CGFloat
	var maxRaisedCards = 10.0
	var maxCardYOffset : CGFloat
	{
		cardZSpacing * maxRaisedCards
	}

	/*@ViewBuilder */var cardOverlay : ((CardMeta) -> AnyView)?

	public init(cardDeckNamespace: Namespace.ID, cards: [CardMeta],debugName:String?=nil,allCardsFaceUp:Bool=false,allCardsPipOnly:Bool=false,cardZSpacing:CGFloat=0.9,cardOverlay:((CardMeta) -> AnyView)?=nil)
	{
		self.debugName = debugName
		self.cardDeckNamespace = cardDeckNamespace
		self.cards = cards
		self.allCardsFaceUp = allCardsFaceUp
		self.allCardsPipOnly = allCardsPipOnly
		self.cardOverlay = cardOverlay
		self.cardZSpacing = cardZSpacing
	}

	func getZOffset(cardIndex:Int) -> CGFloat
	{
		var z = CGFloat(cardIndex) * cardZSpacing
		z = min( maxCardYOffset, z )
		return -z
	}
	
	
	public var body: some View 
	{
		ZStack
		{
			ForEach(Array(zip(cards.indices, cards)), id: \.1.hashValue)
			//ForEach(cards,id:\.hashValue)
			{
				index,card in
				CardView(cardMeta: card, faceUp: allCardsFaceUp, pipOnly: allCardsPipOnly, debugString:self.debugName)
					.overlay
				{
					/*
					 Text("\(card.hashValue)")
					 .background(.black)
					 .font(.system(size:8))
					 */
				}
				.matchedGeometryEffect(id: card.hashValue, in: cardDeckNamespace)
				.offset(x:0,y:getZOffset(cardIndex:index))
			}
			if cards.count == 0
			{
				CardView(cardMeta: nil,debugString: self.debugName)
			}
		}
		.overlay
		{
			VStack
			{
				if let firstCard = cards.first
				{
					if let cardOverlay
					{
						cardOverlay(firstCard) 
					}
				}
			}
		}
	}
}

public struct CardBoard : View 
{
	@Binding public var selectedCards : [CardMeta]
	var selectedCardZ = 20.0
	var selectAnimation = Animation.spring(duration:0.1)
	var maxSelectedCards : Int
	var hasSelectedCardBinding : Bool
	{
		maxSelectedCards > 0
	}

	var debugName : String? = nil
	let cardDeckNamespace : Namespace.ID
	public var cards : [CardMeta]
	public var explicitCardSpaces : Int? = nil
	public var allCardsFaceUp : Bool = true
	public var allCardsPipOnly : Bool = false
	public var cardModifier : ((CardMeta,any View) -> AnyView)?

	public init(cardDeckNamespace: Namespace.ID, cards: [CardMeta], explicitCardSpaces: Int? = nil,allCardsFaceUp:Bool=true,allCardsPipOnly:Bool=false,debugName:String?=nil,selectedCards:Binding<[CardMeta]>?=nil,maxSelectedCards:Int=Int.max,cardModifier:((CardMeta,any View) -> AnyView)?=nil) 
	{
		self.debugName = debugName
		self.cardDeckNamespace = cardDeckNamespace
		self.cards = cards
		self.explicitCardSpaces = explicitCardSpaces
		self.allCardsFaceUp = allCardsFaceUp
		self.allCardsPipOnly = allCardsPipOnly
		self.cardModifier = cardModifier
		self._selectedCards = selectedCards ?? Binding.constant([])
		self.maxSelectedCards = selectedCards != nil ? maxSelectedCards : 0
	}
	
	func isCardSelected(_ card:CardMeta) -> Bool
	{
		return selectedCards.firstIndex(of: card) != nil
	}
	
	func ToggleCardSelection(_ card:CardMeta)
	{
		let isSelected = isCardSelected(card)
		var newList : [CardMeta]
		if isSelected // remove from list
		{
			newList = selectedCards.filter{$0 != card}
		}
		else // add to list
		{
			newList = selectedCards + [card]
		}

		//	don't exceed max
		let cull = max( 0, newList.count-maxSelectedCards )
		if cull > 0
		{
			newList.removeSubrange(0..<cull)
		}
		
		withAnimation(selectAnimation)
		{
			selectedCards = newList
		}
	}
	
	public var body: some View 
	{
		VStack
		{
			GeometryReader
			{
				geo in
				let style = CardStyle(fit:geo.size)
				var cardWidth = style.width
				var squashedCardWidth = geo.size.width / CGFloat(cards.count)
				var overlapPx = max(-6,cardWidth - squashedCardWidth)
				
				//	look! we dont have to offset or a custom stack!
				HStack(spacing:-overlapPx)
				{
					ForEach(cards,id:\.hashValue)
					{
						card in
						let isSelected = isCardSelected(card)
						let z = isSelected ? selectedCardZ : 0
						CardView(cardMeta: card, faceUp: allCardsFaceUp, pipOnly: allCardsPipOnly, z:z, debugString:debugName)
							.matchedGeometryEffect(id: card.hashValue, in: cardDeckNamespace)
							.modifier( LambdaViewModifier(lambda: cardModifier, card: card ) )
							.optionalOnTapGesture(enabled:hasSelectedCardBinding)
							{
								ToggleCardSelection(card)
							}
					}
					/*
					if cards.count < explicitCardSpaces ?? 0
					{
						ForEach( cards.count...explicitCardSpaces )
						{
							CardView(cardMeta:nil)
						}
					}	
					*/
				}
				.overlay
				{
					//Text("px \(overlapPx)").background(.black)
				}
								
			}
		}
		//.padding(10)
		.frame(maxWidth:.infinity)
		/*
		.background(
			Rectangle()
				.stroke(.white,style: StrokeStyle(dash:[4,4]))
				.foregroundStyle(.clear)
		)
		 */
	}
}




struct ExampleTable : View 
{
	static var allCards : [CardMeta]
	{
		var all = [CardMeta]()
		for suit in CardSuit.allSuits
		{
			for value in [2,3,4,5,6,7,8,9,10,11,12,13,14]
			{
				all.append( CardMeta(value:value,suit:suit) )
			}
		}
		return all
	}
		
	@State var Cards1 = allCards.shuffled()
	@State var Cards2 : [CardMeta] = []
	@State var Cards3 : [CardMeta] = []
	@Namespace private var cardDeck
	@State var SelectedCards2 = [CardMeta]()
	@State var SelectedCards3 = [CardMeta]()

	//let anim = Animation.bouncy
	let anim = Animation.bouncy(duration:0.1)
	
	func MoveTopToBottom()
	{
		withAnimation(anim)
		{
			PassCards(source: &Cards1, destination: &Cards2)
		}
	}
	
	func MoveBottomToTop()
	{
		withAnimation(anim)
		{
			PassCards(source: &Cards2, destination: &Cards1)
		}
	}
	
	func PassCards()
	{
		withAnimation(anim)
		{
			PassCards(source: &Cards2, destination: &Cards3)
		}
	}
	
	func SlideLeft()
	{
		withAnimation(anim)
		{
			let card = Cards2.popLast()
			if let card
			{
				Cards2.insert(card, at: 0)
			}
		}
	}
	
	func SlideRight()
	{
		withAnimation(anim)
		{
			if Cards2.count > 0
			{
				let card = Cards2.removeFirst()
				Cards2.append(card)
			}
		}
	}

	//	animation doesnt work in here, need to have caller put this inside an animation	
	func PassCards(source:inout [CardMeta],destination:inout[CardMeta])
	{
		let card = source.popLast()
		if let card
		{
			//destination.insert(card, at: 0)
			destination.append(card)
		}
	}

	
	var body: some View 
	{
		VStack
		{
			CardPile(cardDeckNamespace: cardDeck, cards: Cards1, debugName:"Top" )
				.onTapGesture {
					MoveTopToBottom()
				}
			CardBoard(cardDeckNamespace: cardDeck, cards: Cards2, debugName:"Middle", selectedCards: $SelectedCards2, maxSelectedCards: 1 )
			CardBoard(cardDeckNamespace: cardDeck, cards: Cards3, debugName:"Bottom", selectedCards: $SelectedCards3 )
			{
				card,cardView in
				let new = cardView.overlay
				{
					Text("Hello \(card.suit)")
						.background(.black)
						.foregroundStyle(.white)
				}
				return AnyView(new)
			}
			
			HStack
			{
				Button(action:MoveTopToBottom)
				{
					Text("Deal card")
				}
				Button(action:PassCards)
				{
					Text("Pass card")
				}
				Button(action:MoveBottomToTop)
				{
					Text("return card")
				}
				Button(action:SlideLeft)
				{
					Text("Slide left")
				}
				Button(action:SlideRight)
				{
					Text("slide right")
				}
			}
		}
	}
}

#Preview 
{
	ExampleTable()
	.padding(20)
	.frame(width:400,height: 350)
	.background(.red)
}
