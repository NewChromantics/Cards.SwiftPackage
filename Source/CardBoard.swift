import SwiftUI


public struct CardPile : View 
{
	var debugName : String?
	let cardDeckNamespace : Namespace.ID
	var cards : [CardMeta]
	public var allCardsFaceUp : Bool
	public var allCardsPipOnly : Bool

	public init(cardDeckNamespace: Namespace.ID, cards: [CardMeta],debugName:String?=nil,allCardsFaceUp:Bool=false,allCardsPipOnly:Bool=false)
	{
		self.debugName = debugName
		self.cardDeckNamespace = cardDeckNamespace
		self.cards = cards
		self.allCardsFaceUp = allCardsFaceUp
		self.allCardsPipOnly = allCardsPipOnly
	}

	func getZOffset(cardIndex:Int) -> CGFloat
	{
		var z = CGFloat(cardIndex) * 0.9
		//z = min( 10.0, z )
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
	
	}
}

public struct CardBoard : View 
{
	@Binding public var selectedCard : CardMeta?
	var selectedCardZ = 20.0
	var selectAnimation = Animation.spring(duration:0.1)
	

	var debugName : String? = nil
	let cardDeckNamespace : Namespace.ID
	public var cards : [CardMeta]
	public var explicitCardSpaces : Int? = nil
	public var allCardsFaceUp : Bool = true
	public var allCardsPipOnly : Bool = false
	/*@ViewBuilder */var cardOverlay : ((CardMeta) -> AnyView)?

	public init(cardDeckNamespace: Namespace.ID, cards: [CardMeta], explicitCardSpaces: Int? = nil,allCardsFaceUp:Bool=true,allCardsPipOnly:Bool=false,debugName:String?=nil,selectedCard:Binding<CardMeta?>?=nil,cardOverlay:((CardMeta) -> AnyView)?=nil) 
	{
		self.debugName = debugName
		self.cardDeckNamespace = cardDeckNamespace
		self.cards = cards
		self.explicitCardSpaces = explicitCardSpaces
		self.allCardsFaceUp = allCardsFaceUp
		self.allCardsPipOnly = allCardsPipOnly
		self.cardOverlay = cardOverlay
		self._selectedCard = selectedCard ?? Binding.constant(nil)
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
						let isSlected = card == selectedCard
						let z = isSlected ? selectedCardZ : 0
						CardView(cardMeta: card, faceUp: allCardsFaceUp, pipOnly: allCardsPipOnly, z:z, debugString:debugName)
							.matchedGeometryEffect(id: card.hashValue, in: cardDeckNamespace)
							.overlay
						{
							VStack
							{
								if let cardOverlay
								{
									cardOverlay(card) 
								}
							}
						}
						.onTapGesture 
						{
							withAnimation(selectAnimation)
							{
								selectedCard = isSlected ? nil : card
							}
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

	//let anim = Animation.bouncy
	let anim = Animation.bouncy
	
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
			CardBoard(cardDeckNamespace: cardDeck, cards: Cards2, debugName:"Middle" )
			CardBoard(cardDeckNamespace: cardDeck, cards: Cards3, debugName:"Bottom" )
			{
				AnyView( 
					Text("Hello \($0.suit)")
						.background(.black)
						.foregroundStyle(.white)
				)
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
