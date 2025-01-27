// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "Cards",
	
	platforms: [
		.iOS(.v16),		//	16 for TransferRepresentation
		.macOS(.v14)	//	13 for TransferRepresentation
	],
	

	products: [
		.library(
			name: "Cards",
			targets: [
				"Cards"
			]),
	],
	targets: [

		.target(
			name: "Cards",
			path: "./Source"
		)
	]
)
