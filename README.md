<p align="center">
	<img width="250" src="https://imgur.com/download/qwCI0pa" alt="Badonde header"/>
</p>

<p align="center">
	<img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift version 5"/>
	<a href="https://travis-ci.org/davdroman/Badonde/branches">
	    <img src="https://img.shields.io/travis/davdroman/Badonde/master.svg" alt="Travis status" />
	</a>
	<img src="https://img.shields.io/github/release/davdroman/Badonde.svg" alt="Latest stable release"/>
	<h6 align="center">Named after emblematic <i>bart</i> critic <a href="https://www.youtube.com/watch?v=W2bB7uIVopA"><b>Brian Badonde</b></a>.</h6>
</p>

Badonde is a **command line** tool that combines **Git**, **GitHub**, and **JIRA** and offers as a solution for GitHub projects to define and automate a **PR creation workflow**.

<p align="center">
	<img src="https://imgur.com/download/2iG4ODD" alt="Badonde usage GIF"/>
</p>

## Installation

### Homebrew

```sh
brew install davdroman/tap/badonde
```

### Make

```sh
git clone https://github.com/davdroman/Badonde.git
cd Badonde
make install
```

## Usage

### Setup

First, in a **terminal window**, you want to navigate to your **repo root** and run:

```sh
$ badonde init
```

This will create all the required files for Badonde to work and **prompt for GitHub and JIRA credentials**.

Observe the `.badonde` folder is created to host Badonde's **local user configuration** (e.g. credentials). Such folder is also added to `.gitignore` because per-user configuration **must not be commited**.

### Badondefile

Additionally, a `Badondefile.swift` file is created with a **basic template**. A Badondefile defines the **rules** by which Badonde **derives data and outputs PR information**.

In order to edit Badondefile with **full autocompletion support**, run:

```sh
$ badonde edit
```

This will open an Xcode project where you can make any modifications to this file. When you're done, **go back to the terminal and press the return key** to save the file.

---

Consider a **scenario** where you want to generate a PR from a local branch named `fix/IOS-1234-fix-all-the-things` where `IOS-1234` is a **JIRA ticket id**. Here's an example of a Badondefile that would generate a PR automatically adding things like a **standarised PR title** and a `Bug` **label** for bugfix branches:

```swift
import BadondeKit

// Reads the current Git context and derives a JIRA ticket number from the
// current branch's name.
let badonde = Badonde()

// If a ticket was successfully derived and fetched, its info is available
// through the `badonde.jira` property.
if let ticket = badonde.jira?.ticket {
    // Sets the PR title to something like
    title("[\(ticket.key)] \(ticket.fields.summary)")
}

// If the current branch has the prefix 'fix/' it means we're dealing with a
// bugfix PR, so we attach the Bug label.
if badonde.git.currentBranch.name.hasPrefix("fix/") {
    // Sets the "Bug" label defined in your GitHub repo.
    label(named: "Bug")
}
```

Here's a more advanced (but just as easily expressed) case of an automation where we match the JIRA **ticket's epic** to a **label in your GitHub repo**:

```swift
if let epicName = ticket.fields.epicSummary {
    label(roughlyNamed: epicName)
} else {
    label(named: "BAU")
}
```

By default, Badonde generates **draft PRs**. To disable this, simply add this to your Badondefile:

```swift
draft(false)
```

---

### Generating a PR

Finally, when you're ready to generate a PR, run:

```sh
$ badonde pr
```

Or perform a **dry run** first to see what the output would be:

```sh
$ badonde pr --dry-run
```

### Configuration

As said above, Badonde stores its **local user configuration** in `.badonde/config.json`.

Badonde offers an **interface** similar to `git config` to modify this options. For instance:

```sh
$ badonde config git.remote origin
```

**Global options** are also available (and stored in `~/.config/badonde/config.json`):

```sh
$ badonde config --global git.autopush true
```

To list **all available options**, run:

```sh
$ badonde config --help
```

## Special thanks

Badonde's architecture is heavily inspired by the concepts of the **brilliant [Danger Swift](https://github.com/danger/swift)**. Long live Swift scripting! 🎉
