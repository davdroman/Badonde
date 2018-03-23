import BadondeCore

let tool = Badonde()

do {
	try tool.run()
} catch {
	print("Whoops! An error occurred: \(error)")
}
