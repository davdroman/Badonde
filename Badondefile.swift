import BadondeKit

let badonde = Badonde(
	ticketType: .githubIssue(derivationStrategy: .regex),
	baseBranchDerivationStrategy: .commitProximity
)

switch (badonde.pullRequest.baseBranch, badonde.pullRequest.headBranch) {
case ("master", "develop"):
	let latestTag = badonde.git.tags[0]
	title("\(latestTag) release")
case (_, "develop"):
	Logger.failAndExit("Develop should only be merged into master")
case (_, "master"):
	Logger.failAndExit("Running Badonde from master is not allowed")
default:
	// Set issue to convert to PR (if found).
	if let githubIssue = badonde.github.issue {
		issue(githubIssue.number)
	} else {
		// If issue not found, prettify PR title as follows:
		// "implement-something-cool" ~> "Implement something cool"
		title({
			let temp = badonde.git.currentBranch.name.replacingOccurrences(of: "-", with: " ")
			return temp.prefix(1).localizedCapitalized + temp.dropFirst()
		}())
	}
}

// Add a cheeky little watermark at the end :)
let prBody = (badonde.github.issue?.body ?? "")
	.trimmingCharacters(in: .whitespacesAndNewlines)
	.appending("\n\n")
	.appending(
		"""
		<h6 align="right">
		<img width="12" height="12" src="https://imgur.com/download/Zz8GL0X">
		Generated by <a href="https://badonde.dev">Badonde</a>
		</h6>
		"""
	)
	.trimmingCharacters(in: .whitespacesAndNewlines)

body(prBody)
